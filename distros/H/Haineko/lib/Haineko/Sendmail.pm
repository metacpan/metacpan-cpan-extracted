package Haineko::Sendmail;
use strict;
use warnings;
use Encode;
use Try::Tiny;
use Time::Piece;
use Scalar::Util;
use Haineko::Log;
use Haineko::JSON;
use Haineko::Default;
use Haineko::SMTPD::Milter;
use Haineko::SMTPD::Session;
use Haineko::SMTPD::Response;

sub submit {
    my $class = shift;
    my $httpd = shift;  # (Haineko::HTTPD)

    my $serverconf = $httpd->{'conf'}->{'smtpd'};
    my $defaultset = Haineko::Default->conf;
    my $responsecn = 'Haineko::SMTPD::Response';
    my $responsejk = 'response';    # (String) Response json key name
    my $exceptions = 0;             # (Integer) Flag, be set in try {...} catch { ... }
    my $tmpsession = undef;         # (Haineko::SMTPD::Session) Temporary session object

    # Create a queue id (session id)
    my $queueident = Haineko::SMTPD::Session->make_queueid;

    # Variables related user information such as hostname or port number.
    my $xforwarded = [ split( ',', $httpd->req->header('X-Forwarded-For') || q() ) ];
    my $remoteaddr = pop @$xforwarded || $httpd->req->address // undef;
    my $remoteport = $httpd->req->env->{'REMOTE_PORT'} // undef;
    my $remotehost = $httpd->req->env->{'REMOTE_HOST'} // undef;
    my $remoteuser = $httpd->req->env->{'REMOTE_USER'} // undef;
    my $useragent1 = $httpd->req->user_agent // undef;

    # Syslog object
    my $syslogargv = {
        'queueid'    => $queueident,
        'facility'   => $serverconf->{'syslog'}->{'facility'},
        'disabled'   => $serverconf->{'syslog'}->{'disabled'},
        'useragent'  => $useragent1,
        'remoteaddr' => $remoteaddr,
        'remoteport' => $remoteport,
    };
    for my $e ( 'facility', 'disabled' ) {
        # Fallback to the default value when these values are not defined in
        # etc/haineko.cf
        $syslogargv->{ $e } //= $defaultset->{'smtpd'}->{'syslog'}->{ $e };
    }
    my $nekosyslog = Haineko::Log->new( %$syslogargv );
    my $esresponse = undef;

    # Create a new SMTP Session
    $tmpsession = Haineko::SMTPD::Session->new( 
                    'queueid'    => $queueident,
                    'referer'    => $httpd->req->referer // q(),
                    'useragent'  => $useragent1,
                    'remoteaddr' => $remoteaddr,
                    'remoteport' => $remoteport );


    if( $httpd->debug == 0 && $httpd->req->method eq 'GET' ) {
        # GET method is not permitted in production mode.
        # Use ``POST'' method instead.
        $esresponse = $responsecn->r( 'http', 'method-not-supported' );
        $tmpsession->add_response( $esresponse );
        $nekosyslog->w( 'err', $esresponse->damn );

        return $httpd->res->json( 405, $tmpsession->damn );
    }

    CONN: {
        #   ____ ___  _   _ _   _ 
        #  / ___/ _ \| \ | | \ | |
        # | |  | | | |  \| |  \| |
        # | |__| |_| | |\  | |\  |
        #  \____\___/|_| \_|_| \_|
        #                         
        # Check the remote address
        my $relayhosts = undef;
        my $ip4network = undef;

        try { 
            # Check etc/relayhosts file.  The remote host or the network should
            # be listed in the file.
            $exceptions = 0;
            require Net::CIDR::Lite;
            $relayhosts = Haineko::JSON->loadfile( $serverconf->{'access'}->{'conn'} );
            $ip4network = Net::CIDR::Lite->new( @{ $relayhosts->{'relayhosts'} } );

        } catch {
            $exceptions = 1;
        };

        # If etc/relayhosts file does not exist or failed to load, 
        # only 127.0.0.1 is permitted to relay.
        $ip4network //= Net::CIDR::Lite->new( '127.0.0.1/32' );
        $ip4network->add( '127.0.0.1/32' ) unless $ip4network->list;

        # Haineko relays an email from any to any when the remote user successfully
        # authenticated by Haineko with etc/password file.
        $relayhosts->{'open-relay'} = 1 if $remoteuser;

        if( not $relayhosts->{'open-relay'} ) {
            # When the value of ``openrelay'' is defined as ``0'' in etc/relayhosts,
            # Only permitted host can send an email.
            if( not $ip4network->find( $remoteaddr ) ) {
                # The remote address or the remote network is not listed in 
                # etc/relayhosts.
                $esresponse = $responsecn->r( 'auth', 'access-denied' );
                $tmpsession->add_response( $esresponse );
                $nekosyslog->w( 'err', $esresponse->damn );

                return $httpd->res->json( 403, $tmpsession->damn );
            }
        }

        XXFI_CONNECT: {
            # Act like xxfi_connect() function
            my $milterlibs = $serverconf->{'milter'}->{'conn'} || [];
            my $mfresponse = undef;

            for my $e ( @{ Haineko::SMTPD::Milter->import( $milterlibs ) } ) {
                # Check the remote address with conn() method of each milter
                $mfresponse = $responsecn->new( 'code' => 421, 'command' => 'CONN' );
                last if not $e->conn( $mfresponse, $remotehost, $remoteaddr );
            }
            last XXFI_CONNECT unless defined $mfresponse;
            last XXFI_CONNECT unless $mfresponse->error;

            # Reject connection
            $esresponse = $mfresponse;
            $tmpsession->add_response( $esresponse );
            $nekosyslog->w( 'err', $esresponse->damn );

            return $httpd->res->json( 400, $tmpsession->damn );
        } # End of ``XXFI_CONNECT''

    } # End of ``CONN''

    my $headerlist = [ 'from', 'replyto', 'subject' ];
    my $emencoding = q();   # Character set such as iSO-2022-JP, UTF-8, or ISO-8859-1.
    my $recipients = [];    # Recipient addresses specified in JSON
    my $cannotsend = [];    # Invalid recipient addresses checked by the following codes
    my ( $ehlo, $mail, $rcpt, $head, $body, $json ) = undef;

    try { 
        # Load email data as a JSON
        $exceptions = 0;
        $json = Haineko::JSON->loadjson( $httpd->req->content );
        $ehlo = $json->{'ehlo'} // $json->{'helo'} // q();
        $mail = $json->{'mail'} // $json->{'send'} // $json->{'from'} // q();
        $rcpt = $json->{'rcpt'} // $json->{'recv'} // $json->{'to'}   // [];
        $body = $json->{'body'} // q();
        $head = {};

        for my $e ( @$headerlist ) {
            # Load each email header
            last unless ref $json->{'header'} eq 'HASH';
            next unless defined $json->{'header'}->{ $e };

            $head->{ $e } = $json->{'header'}->{ $e };
            utf8::decode $head->{ $e } unless utf8::is_utf8 $head->{ $e };
        }

        $emencoding = $head->{'charset'} // $head->{'Charset'} // 'UTF-8';
        $head->{'subject'} //= q();
        utf8::decode $body unless utf8::is_utf8 $body;
        $recipients = $rcpt;

    } catch {
        # Failed to load the email body or email headers
        $exceptions = 1;
        $esresponse = $responsecn->r( 'http', 'malformed-json' );
        $esresponse = $esresponse->mesg( $_ ) if $httpd->debug;
        $tmpsession->add_response( $esresponse );
        $nekosyslog->w( 'err', $esresponse->damn );
    };
    return $httpd->res->json( 400, $tmpsession->damn ) if $exceptions;

    DETECT_LOOP_DURING_HAINEKO_SERVERS: {
        #  _                        ___ 
        # | |    ___   ___  _ __   |__ \
        # | |   / _ \ / _ \| '_ \    / /
        # | |__| (_) | (_) | |_) |  |_| 
        # |_____\___/ \___/| .__/   (_) 
        #                  |_|          
        # Check ``X-Haineko-Loop'' header
        my $v = $head->{'x-haineko-loop'} || [];
        if( ref $v eq 'ARRAY' ) {
            # The value of X-Haineko-Loop is an array reference
            if( scalar @$v ) {
                # ``X-Haineko-Loop'' exists in received JSON 
                # "header": { ..., "x-haineko-loop": [] }, 
                if( grep { $serverconf->{'servername'} eq $_ } @$v ) {
                    # DETECTED LOOP:
                    # THE MESSAGE HAS ALREADY PASSED THIS Haineko
                    $esresponse = $responsecn->r( 'conn', 'detect-loop' );
                    $tmpsession->add_response( $esresponse );
                    $nekosyslog->w( 'err', $esresponse->damn );

                    return $httpd->res->json( 400, $tmpsession->damn );
                }
            } else {
                # The header is empty or other data structure.
                push @{ $head->{'x-haineko-loop'} }, $serverconf->{'servername'};
            }
        } else {
            # The value of the header is not an array reference, set this hostname
            # into X-Haineko-Loop header.
            $head->{'x-haineko-loop'} = [ $serverconf->{'servername'} ];
        }
    }

    EHLO: {
        #  _____ _   _ _     ___  
        # | ____| | | | |   / _ \ 
        # |  _| | |_| | |  | | | |
        # | |___|  _  | |__| |_| |
        # |_____|_| |_|_____\___/ 
        #                         
        # Check the value of ``ehlo'' field
        require Haineko::SMTPD::RFC5321;
        require Haineko::SMTPD::RFC5322;

        if( not length $ehlo ) {
            # The value is empty: { "ehlo": '', ... }
            $esresponse = $responsecn->r( 'ehlo', 'require-domain' );
            $tmpsession->add_response( $esresponse );
            $nekosyslog->w( 'err', $esresponse->damn );

            return $httpd->res->json( 400, $tmpsession->damn );

        } elsif( not Haineko::SMTPD::RFC5321->check_ehlo( $ehlo ) ) {
            # The value is invalid: { "ehlo": 1, ... }
            $esresponse = $responsecn->r( 'ehlo', 'invalid-domain' );
            $tmpsession->add_response( $esresponse );
            $nekosyslog->w( 'err', $esresponse->damn );

            return $httpd->res->json( 400, $tmpsession->damn );
        }

        XXFI_HELO: {
            # Act like xxfi_helo() function
            my $milterlibs = $serverconf->{'milter'}->{'ehlo'} || [];
            my $mfresponse = undef;

            for my $e ( @{ Haineko::SMTPD::Milter->import( $milterlibs ) } ) {
                # Check the EHLO value with ehlo() method of each milter
                $mfresponse = $responsecn->new( 'code' => 521, 'command' => 'EHLO' );
                last if not $e->ehlo( $mfresponse, $remotehost, $remoteaddr );
            }

            if( defined $mfresponse && $mfresponse->error ){
                # The value of EHLO is rejected
                $esresponse = $mfresponse->damn;
                $tmpsession->add_response( $mfresponse );
                $nekosyslog->w( 'err', $esresponse );

                return $httpd->res->json( 400, $tmpsession->damn );
            }
        } # End of ``XXFI_HELO''
        $tmpsession->ehlo(1);

    } # End of ``EHLO''

    MAIL_FROM: {
        #  __  __    _    ___ _       _____ ____   ___  __  __ 
        # |  \/  |  / \  |_ _| |     |  ___|  _ \ / _ \|  \/  |
        # | |\/| | / _ \  | || |     | |_  | |_) | | | | |\/| |
        # | |  | |/ ___ \ | || |___  |  _| |  _ <| |_| | |  | |
        # |_|  |_/_/   \_\___|_____| |_|   |_| \_\\___/|_|  |_|
        #                                                      
        # Check the envelope sender address
        if( not length $mail ) {
            # The envelope sender address is empty: { "mail": '', ... }
            $esresponse = $responsecn->r( 'mail', 'syntax-error' );
            $tmpsession->add_response( $esresponse );
            $nekosyslog->w( 'err', $esresponse->damn );

            return $httpd->res->json( 400, $tmpsession->damn );

        } elsif( not Haineko::SMTPD::RFC5322->is_emailaddress( $mail ) ) {
            # The envelope sender address is not valid: { "mail": 'neko', ... }
            $esresponse = $responsecn->r( 'mail', 'domain-required' );
            $tmpsession->add_response( $esresponse );
            $nekosyslog->w( 'err', $esresponse->damn );

            return $httpd->res->json( 400, $tmpsession->damn );

        } elsif( Haineko::SMTPD::RFC5321->is8bit( \$mail ) ) {
            # The envelope sender address includes multi-byte character
            $esresponse = $responsecn->r( 'mail', 'non-ascii' );
            $tmpsession->add_response( $esresponse );
            $nekosyslog->w( 'err', $esresponse->damn );

            return $httpd->res->json( 400, $tmpsession->damn );
        }

        XXFI_ENVFROM: {
            # Act like xxfi_envfrom() function
            my $milterlibs = $serverconf->{'milter'}->{'mail'} || [];
            my $mfresponse = undef;

            for my $e ( @{ Haineko::SMTPD::Milter->import( $milterlibs ) } ) {
                # Check the envelope sender address with mail() method of each milter
                $mfresponse = $responsecn->new( 'code' => 501, 'dsn' => '5.1.8', 'command' => 'MAIL' );
                last if not $e->mail( $mfresponse, $mail );
            }

            if( defined $mfresponse && $mfresponse->error ){
                # The envelope sender address rejected
                $esresponse = $mfresponse->damn;
                $tmpsession->add_response( $mfresponse );
                $nekosyslog->w( 'err', $esresponse );

                return $httpd->res->json( 400, $tmpsession->damn );
            }
        } # End of ``XXFI_ENVFROM''
        $tmpsession->mail(1);

    } # End of ``MAIL_FROM''

    RCPT_TO: {
        #  ____   ____ ____ _____   _____ ___  
        # |  _ \ / ___|  _ \_   _| |_   _/ _ \ 
        # | |_) | |   | |_) || |     | || | | |
        # |  _ <| |___|  __/ | |     | || |_| |
        # |_| \_\\____|_|    |_|     |_| \___/ 
        #                                      
        # Check envelope recipient addresses
        my $accessconf = undef;
        my $xrecipient = $serverconf->{'max_rcpts_per_message'} // $defaultset->{'smtpd'}->{'max_rcpts_per_message'};

        if( not scalar @$recipients ) {
            # No envelope recipient address: { "rcpt": [], ... }
            $esresponse = $responsecn->r( 'rcpt', 'address-required' );
            $tmpsession->add_response( $esresponse );
            $nekosyslog->w( 'err', $esresponse->damn );

            return $httpd->res->json( 400, $tmpsession->damn );
        }

        if( Scalar::Util::looks_like_number $xrecipient ) {

            if( $xrecipient && $xrecipient > 0 ) {

                if( scalar @$recipients > $xrecipient ) {
                    # The number of recipients exceeded the value of ``max_rcpts_per_message'' 
                    # defined in etc/haineko.cf
                    $esresponse = $responsecn->r( 'rcpt', 'too-many-recipients' );
                    $tmpsession->add_response( $esresponse );
                    $nekosyslog->w( 'err', $esresponse->damn );

                    return $httpd->res->json( 403, $tmpsession->damn );
                }
            }
        } else {
            # The value of max_rcpts_per_message does not look like number, such
            # as "max_rcpts_per_message": "neko"
            $esresponse = $responsecn->r( 'conf', 'not-looks-like-number' );
            $esresponse->mesg( sprintf( "Wrong value of max_rcpts_per_message: '%s'", $xrecipient ) );
            $tmpsession->add_response( $esresponse );
            $nekosyslog->w( 'err', $esresponse->damn );

            return $httpd->res->json( 500, $tmpsession->damn );
        }

        VALID_EMAIL_ADDRESS_OR_NOT: {
            # When there is any invalid email address in the value of "rcpt",
            # Haineko rejects current session and returns an error message as
            # a JSON with HTTP status code 400.
            for my $e ( @$recipients ) { 
                # Check the all envelope recipient addresses
                if( Haineko::SMTPD::RFC5322->is_emailaddress( $e ) ) {
                    # Check the envelope recipient address includes multi-byte 
                    # character or not.
                    next unless Haineko::SMTPD::RFC5321->is8bit( \$e );

                    # The envelope recipient address includes multi-byte character
                    $esresponse = $responsecn->r( 'mail', 'non-ascii' );

                } else {
                    # The envelope recipient address is not valid email address
                    $esresponse = $responsecn->r( 'rcpt', 'is-not-emailaddress' );
                }

                $esresponse->rcpt( $e );
                $nekosyslog->w( 'err', $esresponse->damn );
                $tmpsession->add_response( $esresponse );
                push @$cannotsend, $e;
            }
        }

        ALLOWED_RECIPIENT: {
            # Check etc/recipients file. The envelope recipient address or the 
            # domain part of the recipient address should be listed in the file.
            try { 
                $exceptions = 0;
                $accessconf = Haineko::JSON->loadfile( $serverconf->{'access'}->{'rcpt'} );

            } catch {
                $exceptions = 1;
            };

            if( not defined $accessconf ) {
                # If the file does not exist or failed to load the file, only
                # $serverconf->{'hostname'} or $ENV{'HOSTNAME'} or $ENV{'SERVER_NAME'} 
                # or `hostname` allowed as a domain part of the recipient address.
                $accessconf //= { 
                    'open-relay' => 0,
                    'domainpart' => [ $serverconf->{'hostname'} ],
                    'recipients' => [],
                };
            }

            if( ref $accessconf eq 'HASH' ) {
                # etc/recipients file has loaded successfully
                if( 0 ) {
                    # DISABLED FOR DUE TO SECURITY REASON.
                    if( $remoteaddr eq '127.0.0.1' && $remoteaddr eq $httpd->host ) {
                        # Allow relaying when the value of REMOTE_ADDR is equal to 
                        # the value value SERVER_NAME and the value is 127.0.0.1
                        $accessconf->{'open-relay'} = 1;

                    } elsif( $remoteuser ) {
                        # Turn on open-relay if REMOTE_USER environment variable exists.
                        $accessconf->{'open-relay'} = 1;
                    }
                }

                if( not $accessconf->{'open-relay'} ) {
                    # When the value of ``open-relay'' is 0, check the all recipient
                    # addresses with entries defined in etc/recipients.
                    my $r = $accessconf->{'recipients'} || [];
                    my $d = $accessconf->{'domainpart'} || [];

                    for my $e ( @$recipients ) {
                        # The envelope recipient address is defined in etc/recipients
                        next if grep { $e eq $_ } @$r;

                        # The domain part of the envelope recipient address is
                        # defined in etc/recipients
                        my $x = [ split( '@', $e ) ]->[-1];
                        next if grep { $x eq $_ } @$d;

                        # Neither the envelope recipient address nor the domain
                        # part of the address are not allowed at etc/recipients
                        # file.
                        $esresponse = $responsecn->r( 'rcpt', 'rejected' );
                        $esresponse->rcpt( $e );
                        $tmpsession->add_response( $esresponse );
                        $nekosyslog->w( 'err', $esresponse->damn );

                        push @$cannotsend, $e;
                    }
                }
            }
        } # End of ``ALLOWED_RECIPIENT'' block

        XXFI_ENVRCPT: {
            # Act like xxfi_envrcpt() function
            my $milterlibs = $serverconf->{'milter'}->{'rcpt'} || [];
            my $mfresponse = undef;

            for my $e ( @{ Haineko::SMTPD::Milter->import( $milterlibs ) } ) {
                # Check the envelope recipient address with rcpt() method of each milter
                for my $r ( @$recipients ) {
                    my $v = { 'code' => 553, 'dsn' => '5.7.1', 'command' => 'RCPT' };
                    $mfresponse = $responsecn->new( %$v );

                    next if $e->rcpt( $mfresponse, $r );
                    if( defined $mfresponse && $mfresponse->error ) {
                        # One or more envelope recipient address will be rejected
                        $esresponse = $mfresponse->damn;
                        $mfresponse->rcpt( $r );
                        $tmpsession->add_response( $mfresponse );
                        $nekosyslog->w( 'err', $esresponse->damn );

                        push @$cannotsend, $r;
                    }
                }
            }
        } # End of ``XXFI_ENVRCPT''

        CHECK_RCPT: {
            # Check recipient addresses. If there is no envelope recipient address
            # Haineko can send. The following code returns error.
            if( scalar @$cannotsend ) {
                # Cannot send to one or more envelope recipient address
                my $v = [];

                for my $e ( @$recipients ) {
                    # Verify each envelope recipient address with addresses in
                    # variable ``@$cannotsend''
                    next if grep { $e eq $_ } @$cannotsend;
                    push @$v, $e;
                }

                if( scalar @$v ) {
                    # Update the variable for holding recipient addresses without
                    # invalid addresses checked above.
                    $recipients = $v;

                } else {
                    # There is no valid envelope recipient address.
                    return $httpd->res->json( 400, $tmpsession->damn );
                }
            }
        }
        $tmpsession->rcpt(1);

    } # End of ``RCPT_TO''

    DATA: {
        #  ____    _  _____  _    
        # |  _ \  / \|_   _|/ \   
        # | | | |/ _ \ | | / _ \  
        # | |_| / ___ \| |/ ___ \ 
        # |____/_/   \_\_/_/   \_\
        #                         
        # Check email body and subject header
        if( not length $body ) {
            # Empty message is not allowed on Haineko
            $esresponse = $responsecn->r( 'data', 'empty-body' );
            $tmpsession->add_response( $esresponse );
            $nekosyslog->w( 'err', $esresponse->damn );

            return $httpd->res->json( 400, $tmpsession->damn );

        } else {
            # Check message body size
            my $xmesgsize = $serverconf->{'max_message_size'} // $defaultset->{'smtpd'}->{'max_message_size'};

            if( Scalar::Util::looks_like_number $xmesgsize ) {

                if( $xmesgsize > 0 && length( $body ) > $xmesgsize ) {
                    # Message body size exceeds the limit defined in etc/haineko.cf
                    # or Haineko::Default module.
                    $esresponse = $responsecn->r( 'data', 'mesg-too-big' );
                    $tmpsession->add_response( $esresponse );
                    $nekosyslog->w( 'err', $esresponse->damn );

                    return $httpd->res->json( 400, $tmpsession->damn );
                }

            } else {
                # The value of max_message_size does not look like number, such
                # as "max_message_size": "neko"
                $esresponse = $responsecn->r( 'conf', 'not-looks-like-number' );
                $esresponse->mesg( sprintf( "Wrong value of max_message_size: '%s'", $xmesgsize ) );
                $tmpsession->add_response( $esresponse );
                $nekosyslog->w( 'err', $esresponse->damn );

                return $httpd->res->json( 500, $tmpsession->damn );
            }
        }

        if( not length $head->{'subject'} ) {
            # Empty subject is not allowed on Haineko
            $esresponse = $responsecn->r( 'data', 'empty-subject' );
            $tmpsession->add_response( $esresponse );
            $nekosyslog->w( 'err', $esresponse->damn );

            return $httpd->res->json( 400, $tmpsession->damn );
        }
        $tmpsession->data(1);

    } # End of ``DATA''


    # Create new Haineko::SMTPD::Session object from temporary session object
    my $submission = Haineko::SMTPD::Session->new(
                        'addresser' => $mail,
                        'recipient' => $recipients,
                        %{ $tmpsession->damn },
                     );

    my $timestamp1 = localtime Time::Piece->new;
    my $attributes = { 'content_type' => 'text/plain' };
    my $mailheader = {
        'Date'       => $timestamp1->strftime,
        'Received'   => $head->{'received'} || [],
        'Message-Id' => sprintf( "%s.%d.%d.%03d@%s", 
                            $submission->queueid, $$, $submission->started->epoch,
                            int(rand(100)), $serverconf->{'hostname'}
                        ),
        'MIME-Version'     => '1.0',
        'X-Mailer'         => $submission->useragent // q(),
        'X-SMTP-Engine'    => sprintf( "%s %s", $serverconf->{'system'}, $serverconf->{'version'} ),
        'X-HTTP-Referer'   => $submission->referer // q(),
        'X-Haineko-Loop'   => join( ',', @{ $head->{'x-haineko-loop'} } ),
        'X-Originating-IP' => $remoteaddr,
    };
    push @{ $mailheader->{'Received'} }, sprintf( "from %s ([%s]) by %s with HTTP id %s; %s", 
                                            $ehlo, $remoteaddr, $serverconf->{'hostname'}, 
                                            $submission->queueid, $timestamp1->strftime );

    MIME_ENCODING: {
        #  __  __ ___ __  __ _____ 
        # |  \/  |_ _|  \/  | ____|
        # | |\/| || || |\/| |  _|  
        # | |  | || || |  | | |___ 
        # |_|  |_|___|_|  |_|_____|
        #                          
        # detect encodings
        my $encodelist = [ 'US-ASCII', 'ISO-2022-JP', 'ISO-8859-1' ];
        my $ctencindex = {
            'US-ASCII'    => '7bit',
            'ISO-8859-1'  => 'quoted-printable',
            'ISO-2022-JP' => '7bit',
        };

        my $ctencoding = Haineko::SMTPD::RFC5321->is8bit( \$body ) ? '8bit' : '7bit';
        my $headencode = 'MIME-Header';
        my $thisencode = uc $emencoding;    # The value of ``charset'' in received JSON

        if( grep { $thisencode eq $_ } @$encodelist ) {
            # Received supported encodings except UTF-8
            if( $ctencoding eq '8bit' ) {
                # The message body includes multi-byte character
                $ctencoding = $ctencindex->{ $thisencode };

                if( $thisencode eq 'ISO-2022-JP' ) {
                    # ISO-2022-JP is 7bit encoding
                    $thisencode =~ y/-/_/;
                    $headencode =  sprintf( "MIME-Header-%s", $thisencode );
                }
            }

        } else {
            # Force UTF-8 except available encodings
            $emencoding = 'UTF-8';
        }
        $attributes->{'charset'}  = $emencoding;
        $attributes->{'encoding'} = $ctencoding;

        for my $e ( keys %$head ) {
            # Prepare email headers. Email headers in received JSON except supported
            # headers in Haineko are not converted (will be ignored).
            next unless grep { $e eq $_ } @$headerlist;
            next unless defined $head->{ $e };

            my $fieldvalue = $head->{ $e };
            my $headername = ucfirst $e;
            $headername = 'Reply-To' if $headername eq 'Replyto';

            if( Haineko::SMTPD::RFC5321->is8bit( \$fieldvalue ) ) {
                # MIME encode if the value of the header contains any multi-byte
                # character.
                $fieldvalue = Encode::encode( $headencode, $fieldvalue );
            }

            if( exists $mailheader->{ $headername } ) {
                # There is the header which has the same header name, such as
                # ``Received:'' header in generic email message.
                if( ref $mailheader->{ $headername } eq 'ARRAY' ) {
                    # The header already exists, Add the header into array.
                    push @{ $mailheader->{ $headername } }, $fieldvalue;

                } else {
                    # The first header, Add the header as the first element
                    $mailheader->{ $headername } = [ $mailheader->{ $headername }, $fieldvalue ];
                }

            } else {
                $mailheader->{ $headername } = $fieldvalue;
            }
        } # End of for()

    } # End of MIME_ENCODING

    SENDER_HEADER: {
        # Add the envelope sender address into ``Sender:'' header.
        my $fromheader = Haineko::SMTPD::Address->canonify( $head->{'from'} );
        my $envelopemf = $submission->addresser->address;
        $mailheader->{'Sender'} = $envelopemf if $fromheader eq $envelopemf;
    }

    XXFI_HEADER: {
        # Act like xxfi_header() function
        my $milterlibs = $serverconf->{'milter'}->{'head'} || [];
        my $mfresponse = undef;

        for my $e ( @{ Haineko::SMTPD::Milter->import( $milterlibs ) } ) {
            # Check email headers with head() method of each milter
            $mfresponse = $responsecn->new( 'code' => 554, 'dsn' => '5.7.1', 'command' => 'DATA' );
            last if not $e->head( $mfresponse, $mailheader );
        }

        if( defined $mfresponse && $mfresponse->error ){
            # One or more email header will be rejected
            $esresponse = $mfresponse->damn;
            $nekosyslog->w( 'err', $esresponse );
            $submission->add_response( $mfresponse );

            return $httpd->res->json( 400, $submission->damn );
        }
    } # End of ``XXFI_HEADER''

    XXFI_BODY: {
        # Act like xxfi_body() function
        my $milterlibs = $serverconf->{'milter'}->{'body'} || [];
        my $mfresponse = undef;

        for my $e ( @{ Haineko::SMTPD::Milter->import( $milterlibs ) } ) {
            # Check the email body with body() method of each milter
            $mfresponse = $responsecn->new( 'code' => 554, 'dsn' => '5.6.0', 'command' => 'DATA' );
            last if not $e->body( $mfresponse, \$body );
        }

        if( defined $mfresponse && $mfresponse->error ){
            # The email body will be rejected
            $esresponse = $mfresponse->damn;
            $submission->add_response( $mfresponse );
            $nekosyslog->w( 'err', $esresponse );

            return $httpd->res->json( 400, $submission->damn );
        }

    } # End of ``XXFI_BODY''


    # mailertable
    my $mailerconf = { 'mail' => {}, 'rcpt' => {} };
    my $defaulthub = undef; # Relays based on the domain part of the recipient address
    my $sendershub = undef; # Relays based on the domain part of the sender address

    MAILERTABLE: {
        # Load etc/mailertable, etc/sendermt
        require Haineko::SMTPD::Relay;

        for my $e ( 'mail', 'rcpt' ) {
            # Check the contents of the following mailer table files:
            #   - etc/mailertable 
            #   - etc/sendermt
            try { 
                $exceptions = 0;
                $mailerconf->{ $e } = Haineko::JSON->loadfile( $serverconf->{'mailer'}->{ $e } );

            } catch {
                # Failed to load etc/mailertable or etc/sendermt. Maybe the file
                # format is wrong or is not JSON or YAML.
                $exceptions = 1;
            };

            # Load ``default:'' section in etc/mailertable
            $defaulthub //= $mailerconf->{'rcpt'}->{'default'};

            last if $e eq 'rcpt';

            # If the value of ``disabled'' is 1, the mailer table based on the 
            # domain part of the envelope sender address will not be used.
            next unless exists $mailerconf->{'mail'}->{ $submission->addresser->host };
            next if $mailerconf->{'mail'}->{ $submission->addresser->host }->{'disabled'};

            $sendershub = $mailerconf->{'mail'}->{ $submission->addresser->host };
        }

        # ``default:'' section was not defined in etc/mailertable. Use system
        # configuration as a default hub for relaying.
        $defaulthub //= Haineko::SMTPD::Relay->defaulthub;
    }

    my $autheninfo = undef;
    AUTHINFO: {
        # Load etc/authinfo file. Entries defined in etc/authinfo are used at
        # relaying to an external SMTP server or sending message to an email
        # clouds.
        try {
            $exceptions = 0;
            $mailerconf->{'auth'} = Haineko::JSON->loadfile( $serverconf->{'mailer'}->{'auth'} );
        } catch {
            # Failed to load etc/authinfo file.
            $exceptions = 1;
        };
        $autheninfo = $mailerconf->{'auth'} // {};
    }

    SENDMIAL: {
        #  ____  _____ _   _ ____  __  __    _    ___ _     
        # / ___|| ____| \ | |  _ \|  \/  |  / \  |_ _| |    
        # \___ \|  _| |  \| | | | | |\/| | / _ \  | || |    
        #  ___) | |___| |\  | |_| | |  | |/ ___ \ | || |___ 
        # |____/|_____|_| \_|____/|_|  |_/_/   \_\___|_____|
        #                                                   
        require Module::Load;

        my $maxworkers = scalar @$recipients;
        my $preforkset = undef;     # (Parallel::Prefork) object
        my $preforkarg = undef;     # (Ref->Hash) arguments for Parallel::Prefork
        my $preforkipc = [];        # (Ref->Array) IO::Pipe objects
        my $useprefork = 0;         # (Integer) use fork() or not
        my $procnumber = 0;         # (Integer) Job ID of each child process
        my $trappedsig = 0;         # (Integer) The number of received USR2 signal

        if( $maxworkers > 1 ) {
            # Adjust the number of max worker processes.
            my $xprocesses = $serverconf->{'max_workers'} // $defaultset->{'smtpd'}->{'max_workers'};

            if( Scalar::Util::looks_like_number $xprocesses ) {
                # Limit the value of max_workers to the value defined in 
                # etc/haineko.cf or Haineko::Default.
                $maxworkers = $xprocesses if $maxworkers > $xprocesses;

            } else {
                # The value of max_workers does not look like number, such as
                # "max_workers": "neko"
                $esresponse = $responsecn->r( 'conf', 'not-looks-like-number' );
                $esresponse->mesg( sprintf( "Wrong value of max_workers: '%s'", $xprocesses ) );
                $tmpsession->add_response( $esresponse );
                $nekosyslog->w( 'err', $esresponse->damn );

                return $httpd->res->json( 500, $tmpsession->damn );
            }
            $useprefork = 1 if $maxworkers > 1;;
        }

        if( $useprefork ) {
            # If the number of recipients or the value of `maxworkers` is greater
            # than 1, fork and send emails by each child process.
            require IO::Pipe;
            require Parallel::Prefork;

            $preforkarg = {
                'max_workers' => $maxworkers,
                'err_respawn_interval' => 2,
                'spawn_interval' => 0,
                'trap_signals' => { 'HUP' => 'TERM', 'TERM' => 'TERM' },
                'before_fork' => sub {
                    my $k = shift;
                    $k->{'procnumber'} = $procnumber;

                    if( $procnumber < $maxworkers ) {
                        $preforkipc->[ $procnumber ] = IO::Pipe->new;;
                        $procnumber++;
                    }
                }
            };
            $preforkset = Parallel::Prefork->new( $preforkarg );

            $SIG{'USR2'} = sub {
                # Trap signal from each child process
                $trappedsig++;
                kill( 'TERM', $$ ) if $trappedsig >= $maxworkers;
            };
        }

        my $sendmailto = sub {
            # Code reference for sending an email to each recipient which called
            # from Parallel::Prefork->start().
            my $thisworker = undef;

            local $SIG{'TERM'} = 'IGNORE';

            if( $useprefork ) {
                # fork and send each email
                kill( 'USR2', $preforkset->manager_pid );
                $thisworker = $preforkset->{'procnumber'};

                # The number of worker processes has exceeded the limit
                return -1 if $thisworker >= $maxworkers;

            } else {
                # send each email in order
                $thisworker = 0;
            }

            ONE_TO_ONE: for( my $i = $thisworker; $i < $maxworkers; $i += $maxworkers ) {
                # Skip if the recipient address is in @$cannotsend
                my $e = $recipients->[ $i ];
                next if grep { $e eq $_ } @$cannotsend;

                # Create email address objects from each envelope recipient address
                my $r = Haineko::SMTPD::Address->new( 'address' => $e );

                my $relayclass = q();       # (String) Class name of $smtpmailer
                my $smtpmailer = undef;     # (Haineko::SMTPD::Relay::*) Mailer object
                my $relayingto = undef;     # (Ref->Hash) Mailertable
                my $credential = undef;     # (Ref->Hash) Username and password for SMTP-AUTH or API

                $relayingto = $mailerconf->{'rcpt'}->{ $r->host } // $sendershub;
                $relayingto = $sendershub if $relayingto->{'disabled'};

                $relayingto = $defaulthub unless keys %$relayingto;
                $relayingto = $defaulthub if $relayingto->{'disabled'};

                $relayingto->{'port'}   //= 25;
                $relayingto->{'host'}   //= '127.0.0.1';
                $relayingto->{'mailer'} //= 'ESMTP';

                if( $relayingto->{'auth'} ) {
                    $credential = $autheninfo->{ $relayingto->{'auth'} } // {};
                } 
                $relayingto->{'auth'} = q() unless keys %$credential;

                if( $relayingto->{'mailer'} =~ m/\A(?:ESMTP|Haineko|MX)\z/ ) {
                    # Use Haineko::SMTPD::Relay::ESMTP or Haineko::SMTPD::Relay::Haineko
                    #   ::MX      = Directly connect to the host listed in MX Resource record
                    #   ::ESMTP   = Generic SMTP connection to an external server
                    #   ::Haineko = Relay an message to Haineko running on other host
                    my $methodargv = {
                        'ehlo'      => $serverconf->{'hostname'},
                        'mail'      => $submission->addresser->address,
                        'rcpt'      => $r->address,
                        'head'      => $mailheader,
                        'body'      => \$body,
                        'attr'      => $attributes,
                        'host'      => $relayingto->{'host'} // '127.0.0.1',
                        'retry'     => $relayingto->{'retry'} // 0,
                        'sleep'     => $relayingto->{'sleep'} // 5,
                        'timeout'   => $relayingto->{'timeout'} // 59,
                        'starttls'  => $relayingto->{'starttls'},
                    };

                    if( $relayingto->{'mailer'} eq 'ESMTP' ) {
                        # use well-known port for SMTP
                        $methodargv->{'port'} = $relayingto->{'port'} // 25;
                        $methodargv->{'debug'} = $relayingto->{'debug'} // 0;

                    } elsif( $relayingto->{'mailer'} eq 'Haineko' ) {
                        # Haineko uses 2794 by default
                        $methodargv->{'port'} = $relayingto->{'port'} // 2794;

                    } elsif( $relayingto->{'mailer'} eq 'MX' ) {
                        # Mail Exchanger is waiting on *:25
                        $methodargv->{'port'} = 25;
                        $methodargv->{'debug'} = $relayingto->{'debug'} // 0;
                    }

                    $relayclass = sprintf( "Haineko::SMTPD::Relay::%s", $relayingto->{'mailer'} );
                    Module::Load::load( $relayclass );
                    $smtpmailer = $relayclass->new( %$methodargv );

                    if( $relayingto->{'auth'} ) {
                        # Load credentials for SMTP-AUTH
                        $smtpmailer->auth( 1 );
                        $smtpmailer->username( $credential->{'username'} );
                        $smtpmailer->password( $credential->{'password'} );
                    }

                    $smtpmailer->sendmail();

                } elsif( $relayingto->{'mailer'} =~ m/(?:Discard|Screen)/ ) {
                    # These mailer does not open new connection to any host.
                    # Haineko::SMTPD::Relay::
                    #   - Discard: email blackhole. It will discard all messages
                    #   - Screen: print the email message to STDERR
                    $relayclass = sprintf( "Haineko::SMTPD::Relay::%s", $relayingto->{'mailer'} );
                    Module::Load::load( $relayclass );

                    my $methodargv = {
                        'ehlo'      => $serverconf->{'hostname'},
                        'mail'      => $submission->addresser->address,
                        'rcpt'      => $r->address,
                        'head'      => $mailheader,
                        'body'      => \$body,
                        'attr'      => $attributes,
                    };
                    $smtpmailer = $relayclass->new( %$methodargv );
                    $smtpmailer->sendmail();

                } elsif( $relayingto->{'mailer'} =~ m|\A/| or $relayingto->{'mailer'} eq 'File' ) {
                    # Haineko::SMTPD::Relay::File mailer
                    require Haineko::SMTPD::Relay::File;
                    my $mailfolder = $relayingto->{'mailer'} eq 'File' ? '/tmp' : $relayingto->{'mailer'};
                    my $methodargv = {
                        'ehlo'      => $serverconf->{'hostname'},
                        'host'      => $mailfolder,
                        'mail'      => $submission->addresser->address,
                        'rcpt'      => $r->address,
                        'head'      => $mailheader,
                        'body'      => \$body,
                        'attr'      => $attributes,
                    };
                    $smtpmailer = Haineko::SMTPD::Relay::File->new( %$methodargv );
                    $smtpmailer->sendmail();

                } else {
                    $mailheader->{'To'} = $r->address;
                    my $methodargv = {
                        'ehlo'    => $serverconf->{'hostname'},
                        'mail'    => $submission->addresser->address,
                        'rcpt'    => $r->address,
                        'head'    => $mailheader,
                        'body'    => \$body,
                        'attr'    => $attributes,
                        'retry'   => $relayingto->{'retry'} // 0,
                        'timeout' => $relayingto->{'timeout'} // 60,
                    };

                    if( length $relayingto->{'mailer'} ) {
                        # Use Haineko::SMTPD::Relay::* except H::S::R::ESMTP, 
                        # H::S::R::Haineko and H::S::R::Discard.
                        try {
                            $relayclass = sprintf( "Haineko::SMTPD::Relay::%s", $relayingto->{'mailer'} );
                            Module::Load::load( $relayclass );
                            $smtpmailer = $relayclass->new( %$methodargv );

                            if( $relayingto->{'auth'} ) {
                                # Load credentials for SMTP-AUTH
                                $smtpmailer->auth( 1 );
                                $smtpmailer->username( $credential->{'username'} );
                                $smtpmailer->password( $credential->{'password'} );
                            }

                            $smtpmailer->sendmail();

                            if( not $smtpmailer->response->dsn ) {
                                # D.S.N. is empty or undefined.
                                if( $smtpmailer->response->error ) {
                                    # Error but no D.S.N.
                                    $smtpmailer->response->dsn( '5.0.0' );
                                } else {
                                    # Successfully sent but no D.S.N.
                                    $smtpmailer->response->dsn( '2.0.0' );
                                }
                            }

                        } catch {
                            require Haineko::E;
                            my $v = [ split( "\n", $_ ) ]->[0];
                            my $E = Haineko::E->new( $v );
                            my $R = { 
                                'code' => 500, 
                                'error' => 1, 
                                'message' => [ $E->mesg->[0] ],
                            };

                            $smtpmailer = Haineko::SMTPD::Relay->new( %$methodargv );
                            $smtpmailer->response( Haineko::SMTPD::Response->new( %$R ) );
                        };

                    } else {
                        # The value of "mailer" is empty
                        $smtpmailer = Haineko::SMTPD::Relay->new( %$methodargv );
                        my $R = { 
                            'code' => 500, 
                            'error' => 1, 
                            'message' => [ 'The value of "mailer" is empty' ],
                        };
                        $smtpmailer->response( Haineko::SMTPD::Response->new( %$R ) );
                    }
                }

                if( $maxworkers > 1 ) {
                    # Send the received response as a JSON from child process
                    # to parent process via pipe.
                    my $p = $preforkipc->[ $thisworker ];
                    $p->writer;
                    print( { $p } Haineko::JSON->dumpjson( $smtpmailer->response->damn ) );
                    close $p;

                } else {
                    # Add the received response as a Haineko::SMTPD::Response object
                    # into Haineko::SMTPD::Session object.
                    $submission->add_response( $smtpmailer->response );
                }

            } # End of for(ONE_TO_ONE)

            return 0;

        }; # End of `sub sendmailto`

        if( $useprefork ) {
            # Call sendmailto->() and wait all children
            while(1) {
                last if $preforkset->signal_received eq 'TERM';
                last if $preforkset->signal_received eq 'INT';
                $preforkset->start( $sendmailto );
            }
            $preforkset->wait_all_children;

            for my $v ( @$preforkipc ) {
                # Receive the response as a JSON from each child
                my $j = q();
                my $p = undef;

                $v->reader;
                while( <$v> ) {
                    $j .= $_;
                }
                $p = Haineko::JSON->loadjson( $j );
                $submission->add_response( Haineko::SMTPD::Response->new( %$p ) );
            }

        } else {
            # Haineko does not fork when the number of recipients is ``1''
            $sendmailto->();
        }

    } # End of SENDMAIL

    # Respond to the client
    $nekosyslog->w( 'notice', $submission->damn );
    return $httpd->res->json( 200, $submission->damn );

}

1;
__END__
=encoding utf-8

=head1 NAME

Haineko::Sendmail - Controller for /submit

=head1 DESCRIPTION

Haineko::Sendmail is a controller for url /submit and receive email data as
a JSON format or as a parameter in URL.

=head1 EMAIL SUBMISSION

=head2 URL

    http://127.0.0.1:2794/submit

=head2 PARAMETERS(JSON)

To send email via Haineko, POST email data as a JSON format like the following:

    { 
        ehlo: 'your-host-name.as.fqdn'
        mail: 'kijitora@example.jp'
        rcpt: [ 'cats@cat-ml.kyoto.example.jp' ]
        header: { 
            from: 'kijitora <kijitora@example.jp>'
            subject: 'About next meeting'
            relpy-to: 'cats <ml@cat-ml.kyoto.example.jp>'
            charset: 'ISO-2022-JP'
        }
        body: 'Next meeting opens at midnight on next thursday'
    }

    $ curl 'http://127.0.0.1:2794/submit' -X POST -H 'Content-Type: application/json' \
      -d '{ ehlo: "[127.0.0.1]", mail: "kijitora@example.jp", ... }'

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut


