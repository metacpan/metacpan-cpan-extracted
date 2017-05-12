package GMail::IMAPD::Gmail;

use lib qw(lib);
use strict;

require GMail::IMAPD::UserAgent;
require HTTP::Headers;
require HTTP::Cookies;
require HTTP::Request::Common;
require Crypt::SSLeay;
require Exporter;

#Only patched version from Mincus' website works.  
#See http://code.mincus.com/?p=2
our $VERSION = "1.04_patched";


our @ISA = qw(Exporter);
our @EXPORT_OK = ();
our @EXPORT = ();

our $USER_AGENT = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7.8) Gecko/20050511 Firefox/1.0.4";
our $MAIL_URL = "http://mail.google.com/mail";
our $SSL_MAIL_URL = "https://mail.google.com/mail";
our $LOGIN_URL = "https://www.google.com/accounts/ServiceLoginBoxAuth?rm=false&continue=http://mail.google.com/mail/";

our %FOLDERS = (
    'INBOX'   => '^I',
    'STARRED' => '^T',
    'SPAM'    => '^S',
    'TRASH'   => '^K',
);

sub new {
    my $class = shift;
    my %args = @_;

    my $ua = new GMail::IMAPD::UserAgent( agent => $USER_AGENT, keep_alive => 1);
    push( @LWP::Protocol::http::EXTRA_SOCK_OPTS, SendTE => 0 );
    
    my $self = bless {
        _username      => $args{username}       || die( 'No username defined' ),
        _password      => $args{password}       || die( 'No password defined' ),
        _login_url     => $args{login_server}   || $LOGIN_URL,
        _mail_url      => $args{mail_server}    || $args{encrypt_session} ? $SSL_MAIL_URL : $MAIL_URL,
        _proxy_user    => $args{proxy_username} || '',
        _proxy_pass    => $args{proxy_password} || '',
        _proxy_name    => $args{proxy_name}     || '',
        _proxy_enable  => 0,
        _logged_in     => 0,
        _err_str       => '',
        _cookies       => { },
        _ua            => $ua,
        _debug_level   => 0,
        _error         => 0,
    }, $class;

    #added by krs 11/11/05
    $ua->timeout($args{timeout}) if defined $args{timeout};
    #End 

    if ( defined( $args{proxy_name} ) ) {
        $self->{_proxy_enable}++;
        if ( defined( $args{proxy_username} ) && defined( $args{proxy_password} ) ) {
            $self->{_proxy_enable}++;
        }
    }

    return $self;
}

sub error {
    my ( $self ) = @_;
    return( $self->{_error} );
}

sub error_msg {
    my ( $self ) = @_;
    my $error_msg = $self->{_err_str};

    $self->{_error} = 0;
    $self->{_err_str} = '';
    return( $error_msg );
}

sub login {
    my ( $self ) = @_;

    return 0 if $self->{_logged_in};

    if ( $self->{_proxy_enable} && $self->{_proxy_enable} >= 1 ) {
        $ENV{HTTPS_PROXY} = $self->{_proxy_name};
        if ( $self->{_proxy_enable} && $self->{_proxy_enable} >= 2 ) {
            $ENV{HTTPS_PROXY_USERNAME} = $self->{_proxy_user};
            $ENV{HTTPS_PROXY_PASSWORD} = $self->{_proxy_pass};
        }
    }

    my $req = HTTP::Request->new( POST => $self->{_login_url} );
    my ( $cookie );

    $req->content_type( "application/x-www-form-urlencoded" );
    $req->content( 'Email=' . $self->{_username} . '&Passwd=' . $self->{_password} . '&null=Sign+in' );
    my $res = $self->{_ua}->request( $req );

    if ( $res->is_success() ) {
        update_tokens( $self, $res );
        if ( $res->content() =~ /var url = "(.*?)";/ ) {
            $req = HTTP::Request->new( GET => "$SSL_MAIL_URL/$1" );
            $req->header( 'Cookie' => $self->{_cookie} );
            $res = $self->{_ua}->request( $req );
            if ( $res->content() =~ /location.replace\("(.*?)"\)/ ) {
                update_tokens( $self, $res );
                $req = HTTP::Request->new( GET => "$SSL_MAIL_URL/$1" );
                $req->header( 'Cookie' => $self->{_cookie} );
                $res = $self->{_ua}->request( $req );
		if ( $res->content() =~ /js_version/ ) {
                    update_tokens( $self, $res );
                    if ( $self->{_proxy_enable} ) {
                        if ( $self->{_proxy_enable} >= 1 ) {
                            $self->{_ua}->proxy( 'http', $self->{_proxy_name} );
                            delete ( $ENV{HTTPS_PROXY} );
                        }
                        if ( $self->{_proxy_enable} >= 2 ) {
                            delete ( $ENV{HTTPS_PROXY_USERNAME} );
                            delete ( $ENV{HTTPS_PROXY_PASSWORD} );
                        }
                    }
                    $self->{_logged_in} = 1;
                    $res = get_page( $self, start => '', search => '', view => '', req_url => $self->{_mail_url} );
                    return( 1 );
                } else {
                    $self->{_error} = 1;
                    $self->{_err_str} .= "Error: Could not login with those credentials\n";
                    $self->{_err_str} .= "  Additionally, HTTP error: " . $res->status_line . "\n";
                    return;
                }
            } else {
                $self->{_error} = 1;
                $self->{_err_str} .= "Error: Could not login with those credentials\n";
                $self->{_err_str} .= "  Additionally, HTTP error: " . $res->status_line . "\n";
                return;
            }
        } else {
            $self->{_error} = 1;
            $self->{_err_str} .= "Error: Could not login with those credentials\n";
            $self->{_err_str} .= "  Additionally, HTTP error: " . $res->status_line . "\n";
            return;
        }
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: Could not login with those credentials\n";
        $self->{_err_str} .= "  Additionally, HTTP error: " . $res->status_line . "\n";
        return;
    }
}

sub check_login {
    my ( $self ) = @_;

    if ( !$self->{_logged_in} ) {
        unless ( $self->login() ) {
            $self->{_error} = 1;
            $self->{_err_str} .= "Error: Could not Login.\n";
            return;
        }
    }
    return ( $self->{_logged_in} );
}

sub update_tokens {
    my ( $self, $res ) = @_;

    my $previous = $res->previous();
    if ( $previous ) {
        update_tokens( $self, $previous );
    }
    my $header = $res->header( 'Set-Cookie' );
    if ( defined( $header ) ) {
        my ( @cookies ) = split( ',', $header );
        foreach( @cookies ) {
            $_ =~ s/^\s*//;
            if ( $_ =~ /(.*?)=(.*?);/ ) {
                if ( $2 eq '' ) {
                    delete( $self->{_cookies}->{$1} );
                } else {
                    unless ( $1 =~ /\s/ ) {
                        if ( $1 ne '' ) {
                            $self->{_cookies}->{$1} = $2;
                        } else {
                            $self->{_cookies}->{'Session'} = $2;
                        }
                    }
                }
            }
        }
        $self->{_cookie} = join( '; ', map{ "$_=$self->{_cookies}->{$_}"; }( sort keys %{ $self->{_cookies} } ) );
    }
}

sub get_page {
    my ( $self ) = shift;
    my ( %args ) = (
        search  => 'all',
        view    => 'tl',
        start   => 0,
        method  => '',
        req_url => $self->{_mail_url},
        @_, );
    my ( $res, $req, $req_url, @tees );

    unless ( check_login( $self ) ) { return };

    if ( defined( $args{ 'label' } ) ) {
        $args{ 'label' } = validate_label( $self, $args{ 'label' } );
        if ( $self->error ) {
            return;
        } else {
            $args{ 'cat' } = $args{ 'label' };
            delete( $args{ 'label' } );
            $args{ 'search' } = 'cat';
        }
    }

    if ( defined( $args{ 't' } ) ) {
        if ( ref( $args{ 't' } ) eq 'ARRAY' ) {
            foreach ( @{ $args{ 't' } } ) {
                push( @tees, 't' );
                push( @tees, $_ );
            }
            delete( $args{ 't' } );
        }
    }

    $req_url = $args{ 'req_url' };
    delete( $args{ 'req_url' } );

    my ( $url, $method, $view ) = '' x 3;

    $method = $args{ 'method' };
    delete( $args{ 'method' } );

    if ( $method eq 'post' ) {
        $view = $args{ 'view' };
        delete( $args{ 'view' } );
    }

    foreach ( keys %args ) {
        if ( defined( $args{ $_ } ) ) {
            if ( $args{ $_ } eq '' ) {
                delete( $args{ $_ } );
            }
        } else {
            delete( $args{ $_ } );
        }
    }
    if ( $method eq 'post' ) {
        $req = HTTP::Request::Common::POST( $req_url,
            Content_Type => 'multipart/form-data',
            Connection   => 'Keep-Alive',
            'Keep-Alive' => 300,
            Cookie       => $self->{_cookie},
            Content      => [ view => $view, %args, @tees ] );
        if ( $self->{_proxy_enable} && $self->{_proxy_enable} >= 2 ) {
            $req->proxy_authorization_basic( $self->{_proxy_user}, $self->{_proxy_pass} );
        }
        $res = $self->{_ua}->request( $req );
    } else {
        $url = join( '&', map{ "$_=$args{ $_ }"; }( keys %args ) );
        if ( $url ne '' ) {
            $url = '?' . $url;
        }
        $req = HTTP::Request->new( GET => $req_url . "$url" );
        $req->header( 'Cookie' => $self->{_cookie} );
        if ( $self->{_proxy_enable} && $self->{_proxy_enable} >= 2 ) {
            $req->proxy_authorization_basic( $self->{_proxy_user}, $self->{_proxy_pass} );
        }
        $res = $self->{_ua}->request( $req );
    }

    if ( $res ) {
        if ( $res->is_success() ) {
            update_tokens( $self, $res );
        } elsif ( $res->previous() ) {
            update_tokens( $self, $res->previous() );
        }
    }

    return ( $res );
}

sub size_usage {
    my ( $self, $res ) = @_;

    unless ( check_login( $self ) ) { return };

    unless ( $res ) {
        $res = get_page( $self );
    }

    my %functions = %{ parse_page( $self, $res ) };

    if ( $self->{_error} ) {
        return;
    }

    if ( $res->is_success() ) {
        if ( defined( $functions{ 'qu' } ) ) {
            if ( wantarray ) {
                pop( @{ $functions{ 'qu' } } );
                foreach ( @{ $functions{ 'qu' } } ) {
                    s/"//g;
                }
                return( @{ $functions{ 'qu' } } );
            } else {
                $functions{ 'qu' }[0] =~ /"(.*)\s/;
                my $used = $1;
                $functions{ 'qu' }[1] =~ /"(.*)\s/;
                my $size = $1;
                return( $size - $used );
            }
        } else {
            $self->{_error} = 1;
            $self->{_err_str} .= "Error: Could not find free space info.\n";
            return;
        }
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: While requesting: '$res->{_request}->{_uri}'.\n";
        return;
    }
}

sub edit_labels {
    my ( $self ) = shift;
    my ( %args ) = (
        start    => '',
        search   => '',
        action   => '',
        label    => '',
        new_name => '',
        view     => 'up',
        method   => 'post',
        @_,
    );

    unless ( check_login( $self ) ) { return };

    my $action;

    if ( uc( $args{ 'action' } ) eq 'CREATE' ) {
        $action = 'cc_';
        $args{ 'new_name' } = '';
    } elsif ( uc( $args{ 'action' } ) eq 'DELETE' ) {
        $action = 'dc_';
        $args{ 'new_name' } = '';
    } elsif ( uc( $args{ 'action' } ) eq 'REMOVE' ) {
        $action = 'rc_';
        $args{ 'new_name' } = '';
      #Small fix by Kurt 10/30/05
        $args{ 't' } = $args{ 'msgid' };
        delete( $args{ 'msgid' } );
        $args{ 'search' } = 'all';
      #end
    } elsif ( uc( $args{ 'action' } ) eq 'ADD' ) {
        $action = 'ac_';
        $args{ 'new_name' } = '';
        unless ( defined( $args{ 'msgid' } ) ) {
            $self->{_error} = 1;
            $self->{_err_str} .= "To add a label to a message, you must supply a msgid.\n";
            return;
        } else {
            $args{ 't' } = $args{ 'msgid' };
            delete( $args{ 'msgid' } );
            $args{ 'search' } = 'all';
        }
    } elsif ( uc( $args{ 'action' } ) eq 'RENAME' ) {
        $args{ 'new_name' } = '^' . validate_label( $self, $args{ 'new_name' } );
        if ( $self->{_error} ) {
            return;
        }
        $action = 'nc_';
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: No action defined.\n";
        return;
    }

    $args{ 'act' } = $action . validate_label( $self, $args{ 'label' } ) . $args{ 'new_name' };
    if ( $self->{_error} ) {
        return;
    } else {
        delete( $args{ 'label' } );
        delete( $args{ 'action' } );
        $args{ 'at' } = $self->{_cookies}->{GMAIL_AT};
    }

    my $res = get_page( $self, %args );

    if ( $res->is_success() ) {
        my %functions = %{ parse_page( $self, $res ) };
        if ( defined( $functions{ 'ar' } ) ) {
            unless ( $functions{ 'ar' }->[0] ) {
                $self->{_error} = 1;
                $self->{_err_str} .= "Error: " . $functions{ 'ar' }->[1] . "\n";
                return;
            } else {
                return( 1 );
            }
        } else {
            $self->{_error} = 1;
            $self->{_err_str} .= "Error: Could not find label success message.\n";
            return;
        }
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: While requesting: '$res->{_request}->{_uri}'.\n";
        return;
    }
}

sub get_labels {
    my ( $self, $res ) = @_;

    unless ( check_login( $self ) ) { return };

    unless ( $res ) {
        $res = get_page( $self, search => 'inbox' );
    }

    if ( $res->is_success() ) {
        my %functions = %{ parse_page( $self, $res ) };

        if ( $self->{_error} ) {
            return;
        }

        unless ( defined( $functions{ 'ct' } ) ) {
            return;
        }

        my @fields = @{ extract_fields( $functions{ 'ct' }->[0] ) };
        foreach ( @fields ) {
            $_ = ${ extract_fields( $_ ) }[0];
            $_ = remove_quotes( $_ );
        }
        if ( @fields ) {
            return( @fields );
        } else {
            $self->{_error} = 1;
            $self->{_err_str} .= "Error: No Labels found.\n";
            return;
        }
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: While requesting: '$res->{_request}->{_uri}'.\n";
        return;
    }    
}

sub validate_label {
    my ( $self, $label ) = @_;

    if ( defined( $label ) ) {
        $label =~ s/^\s//;
        $label =~ s/\s$//;
        if ( $label =~ /\^/ ) {
            my $is_folder = 0;
            foreach ( keys %FOLDERS ) {
                if ( $FOLDERS{ $_ } eq uc( $label ) ) {
                    $is_folder = 1;
                }
            }
            unless ( $is_folder ) {
                $self->{_error} = 1;
                $self->{_err_str} .= "Error: Labels cannot contain the character '^'.\n";
                return;
            }
        }
        if ( length( $label ) > 40 ) {
            $self->{_error} = 1;
            $self->{_err_str} .= "Error: Labels cannot contain more than 40 characters.\n";
            return;
        }
        if ( length( $label ) == 0 ) {
            $self->{_error} = 1;
            $self->{_err_str} .= "Error: No labels specified.\n";
            return;
        }
        return( $label );
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: No labels specified.\n";
        return;
    }
}

sub edit_star {
    my ( $self ) = shift;
    my ( %args ) = (
        start    => '',
        action   => '',
        view     => 'up',
        @_,
    );

    unless ( check_login( $self ) ) { return };

    my $action;

    if ( $args{ 'action' } eq 'add' ) {
        $args{ 'act' } = 'st';
    } elsif ( $args{ 'action' } eq 'remove' ) {
        $args{ 'act' } = 'xst';
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: No action defined.\n";
        return;
    }
    delete( $args{ 'action' } );

    if ( defined( $args{ 'msgid' } ) ) {
        $args{ 'm' } = $args{ 'msgid' };
        delete( $args{ 'msgid' } );
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: No msgid sent.\n";
        return;
    }

    $args{ 'at' } = $self->{_cookies}->{GMAIL_AT};

    my $res = get_page( $self, %args );

    if ( $res->is_success() ) {
        my %functions = %{ parse_page( $self, $res ) };
        if ( defined( $functions{ 'ar' } ) ) {
            unless ( $functions{ 'ar' }->[0] ) {
                $self->{_error} = 1;
                $self->{_err_str} .= "Error: " . $functions{ 'ar' }->[1] . "\n";
                return;
            } else {
                return( 1 );
            }
        } else {
            $self->{_error} = 1;
            $self->{_err_str} .= "Error: Could not find label success message.\n";
            return;
        }
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: While requesting: '$res->{_request}->{_uri}'.\n";
        return;
    }
}

sub edit_archive {
    my ( $self ) = shift;
    my ( %args ) = (
        action => '',
        msgid  => '',
        method => 'post',
        @_,
    );

    unless ( check_login( $self ) ) { return };

    if ( $args{ 'action' } eq 'archive' ) {
        $args{ 'act' } = 'rc_' . lc( $FOLDERS{ 'INBOX' } );
    } elsif ( $args{ 'action' } eq 'unarchive' ) {
        $args{ 'act' } = 'ib';
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: No action defined.\n";
        return;
    }
    delete( $args{ 'action' } );

    if ( defined( $args{ 'msgid' } ) ) {
        $args{ 't' } = $args{ 'msgid' };
        delete( $args{ 'msgid' } );
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: No msgid sent.\n";
        return;
    }

    $args{ 'at' } = $self->{_cookies}->{GMAIL_AT};

    my $res = get_page( $self, %args );

    if ( $res->is_success() ) {
        my %functions = %{ parse_page( $self, $res ) };
        if ( defined( $functions{ 'ar' } ) ) {
            unless ( $functions{ 'ar' }->[0] ) {
                $self->{_error} = 1;
                $self->{_err_str} .= "Error: " . $functions{ 'ar' }->[1] . "\n";
                return;
            } else {
                return( 1 );
            }
        } else {
            $self->{_error} = 1;
            $self->{_err_str} .= "Error: Could not find archive success message.\n";
            return;
        }
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: While requesting: '$res->{_request}->{_uri}'.\n";
        return;
    }
}

sub multi_email_addr {
    my $array_ref = shift;

    my $email_list;
    foreach( @{ $array_ref } ) {
       $email_list .= "<$_>, ";
    }
    return( $email_list );
}

sub send_message {
    my ( $self ) = shift;
    my ( %args ) = (
        start    => '',
        search   => '',
        action   => '',
        view     => 'sm',
        cmid     => '1'   || $_{cmid},
        to       => ''    || $_{to},
        cc       => ''    || $_{cc},
        bcc      => ''    || $_{bcc},
        subject  => ''    || $_{subject},
        msgbody  => ''    || $_{msgbody},
        method   => 'post',
        @_,
    );

    unless ( check_login( $self ) ) { return };

    $args{ 'at' } = $self->{_cookies}->{GMAIL_AT};

    if ( ( $args{to} ne '' ) || ( $args{cc} ne '' ) || ( $args{bcc} ne '' ) ) {
        foreach( 'to', 'cc', 'bcc' ) {
            if ( ref( $args{$_} ) eq 'ARRAY' ) {
                $args{$_} = multi_email_addr( $args{$_} );
            }
        }

        foreach( keys %args ) {
            if ( defined( $args{ $_ } ) ) {
                $args{ $_ } =~ s/&/%26/g;
            }
        }

        my $res = get_page( $self, %args );
        if ( $res->is_success() ) {
            my %functions = %{ parse_page( $self, $res ) };
            
            if ( $self->{_error} ) {
                return;
            }
            unless ( defined( $functions{ 'sr' } ) ) {
                return;
            }
            if ( $functions{ 'sr' }->[1] ) {
                if ( $functions{ 'sr' }->[3] eq '"0"' ) {
                    $self->{_error} = 1;
                    $self->{_err_str} .= "This message has already been sent.\n";
                    return;
                } else {
                    $functions{ 'sr' }->[3] =~ s/"//g;
                    return( $functions{ 'sr' }->[3] );
                }
            } else {
                $self->{_error} = 1;
                $self->{_err_str} .= "Message could not be sent.\n";
                return;
            }           
        }
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "One of the following must be filled out: to, cc, bcc.\n";
        return;
    }
}

sub get_messages {
    my ( $self ) = shift;
    my ( %args ) = (
        init    => 1,
        start => 0,
        @_, );
    my ( $res, $req );

    if ( defined( $args{ 'label' } ) ) {
        $args{ 'label' } = validate_label( $self, $args{ 'label' } );
        if ( $self->error ) {
            return;
        } else {
            $args{ 'cat' } = $args{ 'label' };
            delete( $args{ 'label' } );
            $args{ 'search' } = 'cat';
        }
    }

    unless ( check_login( $self ) ) { return };

    $res = get_page( $self, %args );

    if ( $res->is_success() ) {
        my %functions = %{ parse_page( $self, $res ) };

        if ( $self->{_error} ) {
            return;
        }
        my ( @emails, @letters );

        unless ( defined( $functions{ 't' } ) ) {
            return;
        }

        foreach ( @{ $functions{ 't' } } ) {
            my @email_line = @{ extract_fields( $_ ) };
            my %indv_email;
            $indv_email{ 'id' }            = remove_quotes( $email_line[0] );
            $indv_email{ 'new' }           = remove_quotes( $email_line[1] );
            $indv_email{ 'starred' }       = remove_quotes( $email_line[2] );
            $indv_email{ 'date_received' } = remove_quotes( $email_line[3] );
            $indv_email{ 'sender_email' }  = remove_quotes( $email_line[4] );
                $indv_email{ 'sender_email' } =~ /'\\>(.*?)\\/;
            $indv_email{ 'sender_name' }   = remove_quotes( $1 );
                $indv_email{ 'sender_email' } =~ /_user_(.*?)\\/;
                $indv_email{ 'sender_email' } = remove_quotes( $1 );
            $indv_email{ 'subject' }       = remove_quotes( $email_line[6] );
            $indv_email{ 'blurb' }         = remove_quotes( $email_line[7] );
            $indv_email{ 'labels' } = [ map{ remove_quotes( $_ ) }@{ extract_fields( $email_line[8] ) } ];
                $email_line[9] = remove_quotes( $email_line[9] );
            $indv_email{ 'attachments' } = extract_fields( $email_line[9] ) if ( $email_line[9] ne '' );
            push ( @emails, \%indv_email );
        }
        if ( ( @emails == @{ $functions{ 'ts' } }[1] ) && ( @{ $functions{ 'ts' } }[0] != @{ $functions{ 'ts' } }[2] ) ) {
            my $start = $args{ 'start' };
            delete( $args{ 'start' } );
            if ( $args{ 'cat' } ) {
                $args{ 'label' } = $args{ 'cat' };
                delete ( $args{ 'cat' } );
                delete ( $args{ 'search' } );
            }
            my $next_page_emails = get_messages( $self, start => ( $start + @emails ), %args );
            if ( $next_page_emails ) {
                @emails = ( @emails, @{ $next_page_emails } );
            }
        }
        return ( \@emails );
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: While requesting: '$res->{_request}->{_uri}'.\n";
        return;
    }
}

sub delete_message {
    my ( $self ) = shift;
    my ( %args ) = (
        act         => 'tr',
        method      => 'post',
        at          => '',
        del_message => 1,
        @_, );

    if ( defined( $args{ 'msgid' } ) ) {
        $args{ 't' } = $args{ 'msgid' };
        delete( $args{ 'msgid' } );
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: No msgid provided.\n";
        return;
    }

    my $del_message = $args{ 'del_message' };
    delete( $args{ 'del_message' } );

    unless ( check_login( $self ) ) { return };

    $args{ 'at' } = $self->{_cookies}->{GMAIL_AT};

    my $res = get_page( $self, %args );

    if ( $res->is_success() ) {
        my %functions = %{ parse_page( $self, $res ) };
            
        if ( $self->{_error} ) {
            return;
        }
        unless ( defined( $functions{ 'ar' } ) ) {
            return;
        }
        if ( $functions{ 'ar' }->[0] ) {
            if ( $del_message ) {
                $args{ 'act' } = 'dl';
                $args{ 'search' } = 'trash';
                $res = get_page( $self, %args );
                if ( $res->is_success() ) {
                    my %functions = %{ parse_page( $self, $res ) };
            
                    if ( $self->{_error} ) {
                        return;
                    }
                    unless ( defined( $functions{ 'ar' } ) ) {
                        return;
                    }
                    if ( $functions{ 'ar' }->[0] ) {
                        return( 1 );
                    } else {
                        $self->{_error} = 1;
                        $self->{_err_str} .= remove_quotes( $functions{ 'ar'}->[1] ) . "\n";
                        return;
                    }
                } else {
                    $self->{_error} = 1;
                    $self->{_err_str} .= "Error: While requesting: '$res->{_request}->{_uri}'.\n";
                    return;
                }
            } else {
                return( 1 );
            }
         } else {
             $self->{_error} = 1;
             $self->{_err_str} .= remove_quotes( $functions{ 'ar'}->[1] ) . "\n";
             return;
        }
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: While requesting: '$res->{_request}->{_uri}'.\n";
        return;
    }
}

sub get_indv_email {
    my ( $self ) = shift;
    my ( %args ) = (
        view   => 'cv',
        @_, );

    if ( defined( $args{ 'id' } ) && defined( $args{ 'label' } ) ) {
        $args{ 'label' } = validate_label( $self, $args{ 'label' } );
        if ( $self->error() ) {
            return;
        } else {
            $args{ 'cat' } = $args{ 'label' };
            delete( $args{ 'label' } );
            $args{ 'search' } = 'cat';
        }
        $args{ 'th' } = $args{ 'id' };
        delete( $args{ 'id' } );
    } elsif ( defined( $args{ 'msg' } ) ) {
        if ( defined( $args{ 'msg' }->{ 'id' } ) ) {
            $args{ 'th' } = $args{ 'msg' }->{ 'id' };
        } else {
            $self->{_error} = 1;
            $self->{_err_str} .= "Error: Not a valid msg reference.\n";
            return;
        }

        if ( defined( @{ $args{ 'msg' }->{ 'labels' } } ) ) {
            if ( $args{ 'msg' }->{ 'labels' }->[0] ne '' ) {
                $args{ 'label' } = validate_label( $self, $args{ 'msg' }->{ 'labels' }->[0] );
                delete( $args{ 'msg' }->{ 'label' } );
                if ( $self->error ) {
                    return;
                } else {
                    if ( $args{ 'label' } =~ /^\^.$/ ) {
                        $args{ 'label' } = cat_to_search( $args{ 'label' } );
                        $args{ 'search' } = $args{ 'label' };
                    } else {
                        $args{ 'cat' } = $args{ 'label' };
                        $args{ 'search' } = 'cat';
                    }
                    delete( $args{ 'label' } );
                }
            }
        }
        delete( $args{ 'msg' } );
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: Must specify either id and label or send a reference to a valid message with msg.\n";
        return;
    }

    unless ( check_login( $self ) ) { return };

    my $res = get_page( $self, %args );

    if ( $res->is_success() ) {
        my %functions = %{ parse_page( $self, $res ) };

        if ( defined( $functions{ 'mi' } ) ) {
            my %messages;
            my @thread;
            foreach ( @{ $functions{ 'mi' } } ) {
                my %message;
                my @email = @{ extract_fields( $_ ) };
                $email[2] = remove_quotes( $email[2] );
                if ( $email[16] ne '' ) {
                    my @attachments = @{ extract_fields( $email[17] ) };
                    my @files;
                    foreach ( @attachments ) {
                        my @attachment = @{ extract_fields( $_ ) };
                        my %indv_attachment;
                        $indv_attachment{ 'id' }       = remove_quotes( $attachment[0] );
                        $indv_attachment{ 'name' }     = remove_quotes( $attachment[1] );
                        $indv_attachment{ 'encoding' } = remove_quotes( $attachment[2] );
                        $indv_attachment{ 'th' }       = $email[2];
                        push( @files, \%indv_attachment );
                    }
                    $message{ 'attachments' } = \@files;
                }
                $message{ 'id' }      = $email[2];
                $message{ 'sender' }  = remove_quotes( $email[7] );
                $message{ 'sent' }    = remove_quotes( $email[9] );
                $message{ 'to' }      = remove_quotes( $email[10] );
                $message{ 'read' }    = remove_quotes( $email[14] );
                $message{ 'subject' } = remove_quotes( $email[15] );
                if ( $args{ 'th' } eq $email[2] ) {
                    foreach ( @{ $functions{ 'mb' } } ) {
                        my $body = extract_fields( $_ );
                        $message{ 'body' } .= $body->[0];
                    }
                    if ( defined( $functions{ 'cs' } ) ) {
                        if ( $functions{ 'cs' }[8] ne '' ) {
                            $message{ 'ads' } = get_ads( $self, adkey => remove_quotes( $functions{ 'cs' }[8] ) );
                        }
                    }
                }
                $messages{ $email[2] } = \%message;
            }
            return ( \%messages );
        }

    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: While requesting: '$res->{_request}->{_uri}'.\n";
        return;
    }
}

sub get_mime_email {
    my ( $self ) = shift;
    my ( %args ) = (
        view   => 'om',
        @_, );

    if ( defined( $args{ 'id' } ) && defined( $args{ 'label' } ) ) {
        $args{ 'label' } = validate_label( $self, $args{ 'label' } );
        if ( $self->error() ) {
            return;
        } else {
            $args{ 'cat' } = $args{ 'label' };
            delete( $args{ 'label' } );
            $args{ 'search' } = 'cat';
        }
        $args{ 'th' } = $args{ 'id' };
        delete( $args{ 'id' } );
    } elsif ( defined( $args{ 'msg' } ) ) {
        if ( defined( $args{ 'msg' }->{ 'id' } ) ) {
            $args{ 'th' } = $args{ 'msg' }->{ 'id' };
        } else {
            $self->{_error} = 1;
            $self->{_err_str} .= "Error: Not a valid msg reference.\n";
            return;
        }

        if ( defined( @{ $args{ 'msg' }->{ 'labels' } } ) ) {
            if ( $args{ 'msg' }->{ 'labels' }->[0] ne '' ) {
                $args{ 'label' } = validate_label( $self, $args{ 'msg' }->{ 'labels' }->[0] );
                delete( $args{ 'msg' }->{ 'label' } );
                if ( $self->error ) {
                    return;
                } else {
                    if ( $args{ 'label' } =~ /^\^.$/ ) {
                        $args{ 'label' } = cat_to_search( $args{ 'label' } );
                        $args{ 'search' } = $args{ 'label' };
                    } else {
                        $args{ 'cat' } = $args{ 'label' };
                        $args{ 'search' } = 'cat';
                    }
                    delete( $args{ 'label' } );
                }
            }
        }
        delete( $args{ 'msg' } );
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: Must specify either id and label or send a reference to a valid message with msg.\n";
        return;
    }

    unless ( check_login( $self ) ) { return };

    my $res = get_page( $self, %args );

    if ( $res->is_success() ) {
        my $content = $res->content;
        $content =~ s/\r\n/\n/g;
        $content =~ s/^(\s*\n)+//;
        return $content;
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: While requesting: '$res->{_request}->{_uri}'.\n";
        return;
    }
}

sub get_contacts {
    my ( $self ) = shift;
    my ( %args ) = (
        @_, );
    my ( $res, $req );

    $args{ 'view' } = 'cl';
    $args{ 'search' } = 'contacts';
    $args{ 'start' } = undef;
    $args{ 'method' } = 'get';
    $args{ 'pnl' } = $args{ 'frequent' } ? 'p' : 'a';
    delete $args{ 'frequent' };

    unless ( check_login( $self ) ) { return };

    $res = get_page( $self, %args );

    if ( $res->is_success() ) {
        my %functions = %{ parse_page( $self, $res ) };

        if ( $self->{_error} ) {
            return;
        }
        my ( @contacts );

        unless ( defined( $functions{ 'a' } ) ) {
            return;
        }

        foreach ( @{ $functions{ 'a' } } ) {
            my @contact_line = @{ extract_fields( $_ ) };
            my %indv_contact;
            $indv_contact{ 'id' }            = remove_quotes( $contact_line[0] );
            $indv_contact{ 'name1' }         = remove_quotes( $contact_line[1] );
            $indv_contact{ 'name2' }         = remove_quotes( $contact_line[2] );
            $indv_contact{ 'email' }         = remove_quotes( $contact_line[3] );
            $indv_contact{ 'note' }          = remove_quotes( $contact_line[4] );
            push ( @contacts, \%indv_contact );
        }
        return ( \@contacts );
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: While requesting: '$res->{_request}->{_uri}'.\n";
        return;
    }
}

sub get_ads {
    my ( $self ) = shift;
    my ( %args ) = (
        adkey  => '',
        view   => 'ad',
        search => '',
        start  => '',
        @_, );

    unless ( check_login( $self ) ) { return };

    if ( defined( $args{ 'adkey' } ) ) {
        $args{ 'bb' } = $args{ 'adkey' };
        delete( $args{ 'adkey' } );
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: No addkey provided.\n";
        return;
    }

    my $res = get_page( $self, %args );
    if ( $res->is_success() ) {
        my $ad_text = $res->content();
        $ad_text =~ s/\n//g;
        $ad_text =~ /\[(\[.*?\])\]/;
        $ad_text = $1;
        my @indv_ads = @{ extract_fields( $ad_text ) };
        my @ads;
        foreach ( @indv_ads ) {
            my @split_ad = @{ extract_fields( $_ ) };
            if ( uc( remove_quotes( $split_ad[0] ) ) eq 'A' ) {
                $split_ad[5] =~ s/<wbr>.*//i;
                my %ad_hash = (
                    title       => remove_quotes( $split_ad[2] ),
                    body        => remove_quotes( $split_ad[3] ),
                    vendor_link => remove_quotes( $split_ad[5] ),
                    link        => remove_quotes( $split_ad[4] ), );
                push( @ads, \%ad_hash );
            } elsif ( uc( remove_quotes( $split_ad[0] ) ) eq 'RN' ) {
                if ( $split_ad[3] =~ /redir_url=(.*?)\"/ ) {
                    my $vendor_link = $1;
                    my %ad_hash = (
                        title       => remove_quotes( $split_ad[1] ),
                        body        => remove_quotes( $split_ad[2] ),
                        vendor_link => url_unencode( $self, url => $vendor_link ),
                        link        => remove_quotes( $split_ad[3] ), );
                    push( @ads, \%ad_hash );
                }
            } elsif ( uc( remove_quotes( $split_ad[0] ) ) eq 'RP' ) {
                my %ad_hash = (
                    title       => remove_quotes( $split_ad[1] ),
                    body        => remove_quotes( $split_ad[2] ),
                    vendor_link => remove_quotes( $split_ad[4] ),
                    link        => remove_quotes( $split_ad[3] ), );
                push( @ads, \%ad_hash );
            }
        }

        return( \@ads );
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: " . $res->status_line();
    }

    return;
}

sub url_unencode {
    my $self = shift;
    my ( %args ) = (
        url => '',
        @_,
    );

    if ( $args{ 'url' } ) {
        $args{ 'url' } =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack( "C", hex( $1 ) )/eg;
        return( $args{ 'url' } );
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: Must supply URL to unencode.";
        return;
    }
}

sub get_attachment {
    my ( $self ) = shift;
    my ( %args ) = (
        view   => 'att',
        disp   => 'attd',
        search => '',
        @_, );

    if ( defined( $args{ 'attid' } ) && defined( $args{ 'msgid' } ) ) {
        $args{ 'th' } = $args{ 'msgid' };
        delete( $args{ 'msgid' } );
    } elsif ( defined( $args{ 'attachment' } ) ) {
        if ( defined( $args{ 'attachment' }->{ 'id' } ) ) {
            $args{ 'attid' } = $args{ 'attachment' }->{ 'id' };
        } else {
            $self->{_error} = 1;
            $self->{_err_str} .= "Error: Not a valid attachment.1\n";
            return;
        }
        if ( defined( $args{ 'attachment' }->{ 'th' } ) ) {
            $args{ 'th' } = $args{ 'attachment' }->{ 'th' };
        } else {
            $self->{_error} = 1;
            $self->{_err_str} .= "Error: Not a valid attachment.2\n";
            return;
        }
        delete( $args{ 'attachment' } );        
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: Must supply attid and msgid or a reference to an attachment through 'attachment'.\n";
        return;
    }

    unless ( check_login( $self ) ) { return };
    
    my $res = get_page( $self, %args );

    if ( $res->is_success() ) {
        my $attachment = $res->content();
        return( \$attachment );
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: While requesting attachment: '$res->{_request}->{_uri}'.\n";
        return;
    }
}

sub update_prefs {
    my ( $self ) = shift;
    my ( %args ) = (
        view         => 'tl',
        act          => 'prefs',
        search       => 'inbox',
        @_, );

    unless ( check_login( $self ) ) { return };

    $args{ 'at' } = $self->{_cookies}->{GMAIL_AT};

    my ( %pref_mappings ) = (
        bx_hs => 'keyboard_shortcuts',
        ix_nt => 'max_page_size',
        bx_sc => 'indicators',
        sx_dn => 'display_name',
        bx_ns => 'snippets',
        sx_rt => 'reply_to',
        sx_sg => 'signature', );

    my ( %pref_args ) = (
        view    => 'pr',
        pnl     => 'g',
        search  => '',
        start   => '',
        method  => '',
    );

    my $pref_res = get_page( $self, %pref_args );

    if ( $pref_res->is_success() ) {
        my %functions = %{ parse_page( $self, $pref_res ) };

        if ( $self->{_error} ) {
            return;
        }

        unless ( defined( $functions{ 'p' } ) ) {
            return;
        }

        ### Delete if equal to the string '' ###
        foreach ( 'signature', 'reply_to', 'display_name' ) {
            if ( defined( $args{ $_ } ) ) {
                if ( $args{ $_ } eq '' ) {
                    $args{ $_ } = '%0A%0D';
                }
            }
        }

        ### Load Prefs if not redefined ###
        foreach ( @{ $functions{ 'p' } } ) {
            my ( @setting ) = @{ extract_fields( $_ ) };
            foreach ( @setting ) {
                $_ = remove_quotes( $_ );
            }
            unless ( defined( $args{ $pref_mappings{ $setting[0] } } ) ) {
                $args{ 'p_' . $setting[0] } = $setting[1];
            } else {
                $args{ 'p_' . $setting[0] } = $args{ $pref_mappings{ $setting[0] } };
            }
            delete( $args{ $pref_mappings{ $setting[0] } } );
        }

        ### Add preferences to be added ###
        my %rev_pref_mappings;
        foreach ( keys %pref_mappings ) {
            $rev_pref_mappings{ $pref_mappings{ $_ } } = $_;
        }
        foreach ( keys %args ) {
            if ( $rev_pref_mappings{ $_ } ) {
                $args{ 'p_' . $rev_pref_mappings{ $_ } } = $args{ $_ };
                delete( $args{ $_ } );
            }
        }

        my $res = get_page( $self, %args );
        if ( $res->is_success() ) {
            my %functions = %{ parse_page( $self, $res ) };
            if ( @{ $functions{ 'ar' } }[0] == 1 ) {
                return( 1 );
            } else {
                $self->{_error} = 1;
                $self->{_err_str} .= "Error: While updating user preferences: '" . remove_quotes( @{ $functions{ 'ar' } }[1] ) . "'.\n";
                return;
            }
        } else {
            $self->{_error} = 1;
            $self->{_err_str} .= "Error: While updating user preferences: '$res->{_request}->{_uri}'.\n";
            return;
        }    
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: While requesting user preferences: '$pref_res->{_request}->{_uri}'.\n";
        return;
    }
}

sub recurse_slash {
    my ( $field ) = @_;
    my $count_slashes = 0;
    my $end_slash = 0;
    my $cnt = length( $field );

    while ( ( $cnt > 0 ) && ( !$end_slash ) ){
        $cnt--;
        my $char = substr( $field, $cnt, 1 );
        if ( $char eq '\\' ) {
            if ( $count_slashes ) {
                $count_slashes = 0;
            } else {
                $count_slashes = 1;
            }
        } else {
            $end_slash = 1;
        }
    }

    return( $count_slashes );
}

sub extract_fields {
    my ( $line ) = @_;
    my @fields;
    my $in_quotes = 0;
    my $in_brackets = 0;
    my $in_brackets_quotes = 0;
    my $delim_count = 0;
    my $end_field = 0;
    my $field = '';
    my $char;

    my $cnt;
    for ( $cnt=0; $cnt < length( $line ); $cnt++ ) {
        $char = substr( $line, $cnt, 1 );
        if ( $in_quotes ) {
            if ( ( $char eq '"' ) && ( !recurse_slash( $field ) ) ) {
                $in_quotes = 0;
                $end_field = 1;
            }
            $field .= $char;
        } elsif ( $in_brackets ) {
            if ( $in_brackets_quotes ) {
                if ( ( $char eq '"' ) && ( !recurse_slash( $field ) ) ) {
                    $in_brackets_quotes = 0;
                }
                $field .= $char;
            } elsif ( $char eq '"' ) {
                $in_brackets_quotes = 1;
                $field .= $char;
            } else {
                if ( $char eq '[' ) {
                    $delim_count++;
                    $field .= $char;
                } elsif ( $char eq ']' ) {
                    $delim_count--;
                    if ( $delim_count == 0 ) {
                        $in_brackets = 0;
                        $end_field = 1;
                        if ( $field eq '' ) {
                            push( @fields, '' );
                        }
                    } else {
                        $field .= $char;
                    }
                } else {
                    $field .= $char;
                }
            }
        } elsif ( $char eq '"' ) {
            $in_quotes = 1;
            $field .= $char;
        } elsif ( $char eq '[' ) {
            $in_brackets = 1;
            $delim_count = 1;
        } elsif ( $char ne ',' ) {
            $field .= $char;
        } elsif ( $char eq ',' ) {
            $end_field = 1;
        }

        if ( $end_field ) {
            if ( $field ne '' ) {
                push ( @fields, $field );
            }
            $field = '';
            $end_field = 0;
        }
    }

    if ( $field ne '' ) {
        push ( @fields, $field );
    }
    return( \@fields );
}

sub remove_quotes {
    my ( $field ) = @_;

    if ( defined( $field ) ) {
        $field =~ s/^"(.*)"$/$1/;
    }

    return ( $field );
}

sub cat_to_search {
    my ( $cat ) = @_;

    my %REVERSE_CAT = map{ $FOLDERS{ $_ } => $_ }(keys %FOLDERS);

    if ( defined( $REVERSE_CAT{ uc( $cat ) } ) ) {
        return( lc( $REVERSE_CAT{ uc( $cat ) } ) );
    } else {
        return( $cat );
    }
}

sub parse_page {
    my ( $self, $res ) = @_;

    if ( $res->is_success() ) {
        my $page;
        $res->content() =~ /<!--(.*)\/\/-->/s;
        $page = $1;
        my ( %functions );
        while ( $page =~ /D\((.*?)\);\n/mgs ) {
            my $line = $1;
            $line =~ s/\n//g;
            $line =~ s/^\["(.*?)",?//;
            my $function = $1;
            $line =~ s/\]$//;
            if ( ( uc( $function ) eq 'MI' ) || ( uc( $function ) eq 'MB' ) ) {
                $functions{ $function } .= "[$line],";
            } else {
                $functions{ $function } .= "$line,";
            }
        }
        foreach ( keys %functions ) {
            chop( $functions{ $_ } );
            my $fields = extract_fields( $functions{ $_ } );
            $functions{ $_ } = $fields;
        }
        return ( \%functions );
    } else {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: While requesting: '$res->{_request}->{_uri}'.\n";
        return;
    }
}

1;

__END__

