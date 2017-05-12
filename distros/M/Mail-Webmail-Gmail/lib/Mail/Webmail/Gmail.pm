package Mail::Webmail::Gmail;

use lib qw(lib);
use strict;

require LWP::UserAgent;
require HTTP::Headers;
require HTTP::Cookies;
require HTTP::Request::Common;
require Crypt::SSLeay;
require Exporter;

our $VERSION = "1.09";

our @ISA = qw(Exporter);
our @EXPORT_OK = ();
our @EXPORT = ();

our $USER_AGENT = "User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7.8) Gecko/20050511 Firefox/1.0.4";
our $MAIL_URL = "http://mail.google.com/mail";
our $SSL_MAIL_URL = "https://mail.google.com/mail";
our $LOGIN_URL = "https://www.google.com/accounts/ServiceLoginBoxAuth";

our %FOLDERS = (
    'INBOX'   => '^I',
    'STARRED' => '^T',
    'SPAM'    => '^S',
    'TRASH'   => '^K',
);

sub new {
    my $class = shift;
    my %args = @_;

    my $ua = new LWP::UserAgent( agent => $USER_AGENT, keep_alive => 1 );
    $ua->timeout( $args{timeout} ) if defined $args{timeout};

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
    $req->header( 'Cookie' => $self->{_cookie} );
    my ( $cookie );

    $req->content_type( "application/x-www-form-urlencoded" );
    $req->content( 'Email=' . $self->{_username} . '&Passwd=' . $self->{_password} . '&null=Sign+in' );

    my $res = $self->{_ua}->request( $req );

    if ( !$res->is_success() ) {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: Could not login with those credentials - the request was not a success\n";
        $self->{_err_str} .= "  Additionally, HTTP error: " . $res->status_line . "\n";
        return;
    }

    update_tokens( $self, $res );
    if ( $res->content() !~ /var url = (["'])(.*?)\1/ ) {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: Could not login with those credentials - could not find final URL\n";
        $self->{_err_str} .= "  Additionally, HTTP error: " . $res->status_line . "\n";
        return;
    }

    my $final_url;
    ( $final_url = $2 ) =~ s/\\u003d/=/;

    $req = HTTP::Request->new( GET => $final_url );
    $req->header( 'Cookie' => $self->{_cookie} );
    $res = $self->{_ua}->request( $req );
#    if ( ( $res->content() !~ /<a href="http:\/\/mail\.google\.com\/mail\?view=(?:.*?)&amp;fs=(?:.*?)" target="_blank"> (?:.*?) <\/a>/ ) &&
#       ( $res->content() !~ /<a href="http:\/\/mail\.google\.com\/mail">(?:.*?)<\/a>/ ) ) {
#        $self->{_error} = 1;
#        $self->{_err_str} .= "Error: Could not login with those credentials - could not find Gmail account.\n";
#        $self->{_err_str} .= "  Additionally, HTTP error: " . $res->status_line . "\n";
#        return;
#    }
    update_tokens( $self, $res );

    $req = HTTP::Request->new( GET => 'http://mail.google.com/mail?view=pr&amp;fs=1' );
    $req->header( 'Cookie' => $self->{_cookie} );
    $res = $self->{_ua}->request( $req );
    if ( $res->content() !~ /top.location="(.*?)"/ ) {
        $self->{_error} = 1;
        $self->{_err_str} .= "Error: Could not login with those credentials - could not find 'top.location'\n";
        $self->{_err_str} .= "  Additionally, HTTP error: " . $res->status_line . "\n";
        return;
    }
    update_tokens( $self, $res );

    $final_url = ( URI::Escape::uri_unescape( $1 ) );
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
    $res = get_page( $self, search => '', start => '', view => '', req_url => $final_url );
    $res = get_page( $self, search => 'inbox' );

    return ( 1 );
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
                $indv_email{ 'sender_email' } =~ /\\"(.*?)\\">/;
                $1 =~ /_(?:.*?)_(.*?)$/;
                $indv_email{ 'sender_email' } = $1;
            $indv_email{ 'sender_name' }   = remove_quotes( $email_line[4] );
                $indv_email{ 'sender_name' } =~ />(?:<b>)?(.*?)<\//;
                $indv_email{ 'sender_name' } = $1;
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

        unless ( defined( $functions{ 'cl' } ) ) {
            return;
        }

        foreach ( @{ $functions{ 'cl' } } ) {
            my @contact_line = @{ extract_fields( $_ ) };
            my %indv_contact;
            $indv_contact{ 'id' }            = remove_quotes( $contact_line[1] );
            $indv_contact{ 'name1' }         = remove_quotes( $contact_line[2] );
            $indv_contact{ 'name2' }         = remove_quotes( $contact_line[3] );
            $indv_contact{ 'email' }         = remove_quotes( $contact_line[4] );
            $indv_contact{ 'note' }          = remove_quotes( $contact_line[5] );
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

=head1 NAME

Mail::Webmail::Gmail - An interface to Google's webmail service

=head1 SYNOPSIS

    # Perl script that logs in to Gmail, retrieves the user defined labels
    # Then prints out all new messages under the first label

    use Mail::Webmail::Gmail;

    my $gmail = Mail::Webmail::Gmail->new( 
                username => 'username', password => 'password',
            );

    my @labels = $gmail->get_labels();

    my $messages = $gmail->get_messages( label => $labels[0] );

    foreach ( @{ $messages } ) {
        if ( $_->{ 'new' } ) {
            print "Subject: " . $_->{ 'subject' } . " / Blurb: " . $_->{ 'blurb' } . "\n";
        }
    }

=head1 ABSTRACT

This perl module uses objects to make it easy to interface with Gmail.  I eventually hope to
implement all of the functionality of the Gmail website, plus additional features.

=head1 DESCRIPTION

Because Gmail is currently in Beta testing, expect this module to break as they make updates
to thier interface.  I will attempt to keep this module in line with the changes they make, but,
if after updating to the newest version of this module, the feature that you require still doesn't
work, please contact me with the issue.

=head2 STARTING A NEW GMAIL SESSION

The standard call for starting a new Gmail session is simply

    my $gmail = Mail::Webmail::Gmail->new( username => 'username', password => 'password', );

This module does support the use of a proxy server

    my $gmail = Mail::Webmail::Gmail->new( username => 'username', password => 'password', 
                proxy_username => 'proxy_username',
                proxy_password => 'proxy_password',
                proxy_name => 'proxy_server' );

By default, this module only encrypts the logon process.  To encrypt the entire session, use
the argument encrypt_session

    my $gmail = Mail::Webmail::Gmail->new( username => 'username', password => 'password', encrypt_session => 1 );

After that, you are free to start making requests for data.

=head2 RETRIEVING LABELS

Returns an array of all user defined labels.

    my @labels = $gmail->get_labels();

=head2 EDITING LABELS

There are five actions that can currently be preformed on labels.  As a note, this module enforces Gmail's 
limits on label creation.  A label cannot be over 40 characters, and a label cannot contain the character '^'.  
On failure, error and error_msg are set.

    #creating new labels.
    $gmail->edit_labels( label => 'label_name', action => 'create' );

    #renaming existing labels.
    $gmail->edit_labels( label => 'label_name', action => 'rename', new_name => 'renamed_label' );

    #deleting labels.
    $gmail->edit_labels( label => 'label_name', action => 'delete' );

    #adding a label to a message.
    $gmail->edit_labels( label => 'label_name', action => 'add', msgid => $message_id );

    #removing a label from a message.
    $gmail->edit_labels( label => 'label_name', action => 'remove', msgid => $message_id );

=head2 UPDATING PREFERENCES

The following are the seven preferences and the allowed values that can currently be changed through Mail::Webmail::Gmail

    keyboard_shortcuts = ( 0, 1 )
    indicators         = ( 0, 1 )
    snippets           = ( 0, 1 )
    max_page_size      = ( 25, 50, 100 )
    display_name       = ( '', string value up to 96 Characters )
    reply_to           = ( '', string value up to 320 Characters )
    signature          = ( '', string value up to 1000 Characters )

Changing preferences can be accomplished by simply sending the preference(s) that you want to change, and the new value.

    $gmail->update_prefs( indicators => 0, reply_to => 'test@test.com' );

To delete display_name, reply_to, or signature simply send a blank string as in the following example.

    $gmail->update_prefs( signature => '' );

=head2 STARRING A MESSAGE

To star or unstar a message use these examples

    #star
    $gmail->edit_star( action => 'add', 'msgid' => $msgid );

    #unstar
    $gmail->edit_star( action => 'remove', 'msgid' => $msgid );

=head2 ARCHIVING

To archive or unarchive a message use these examples

    #archive
    $gmail->edit_archive( action => 'archive', 'msgid' => $msgid );

    #unarchive
    $gmail->edit_archive( action => 'unarchive', 'msgid' => $msgid );

=head2 RETRIEVING MESSAGE LISTS

By default, get_messages returns a reference to an AoH with the messages from the 'all'
folder.  To change this behavior you can either send a label

    my $messages = $gmail->get_messages( label => 'work' );

Or request a Gmail provided folder using one of the provided variables

    'INBOX'
    'STARRED'
    'SPAM'
    'TRASH'

    Ex.

    my $messages = $gmail->get_messages( label => $Mail::Webmail::Gmail::FOLDERS{ 'INBOX' } );

The Array of hashes is in the following format

    $indv_email{ 'id' }
    $indv_email{ 'new' }
    $indv_email{ 'starred' }
    $indv_email{ 'date_received' }
    $indv_email{ 'sender_email' }
    $indv_email{ 'subject' }
    $indv_email{ 'blurb' }
    @{ $indv_email{ 'labels' } }
    @{ $indv_email{ 'attachments' } }

=head2 SPACE REMAINING

Returns a scalar with the amount of MB remaining in you account.

    my $remaining = $gmail->size_usage();

If called in list context, returns an array as follows.
[ Used, Total, Percent Used ]
[ "0 MB", "1000 MB", "0%" ]

=head2 INDIVIDUAL MESSAGES

There are two ways to get an individual message:

    By sending a reference to a specific message returned by get_messages

    #prints out the message body for all messages in the starred folder
    my $messages = $gmail->get_messages( label => $Mail::Webmail::Gmail::FOLDERS{ 'STARRED' } );
    foreach ( @{ $messages } ) {
        my $message = $gmail->get_indv_email( msg => $_ );
        print "$message->{ $_->{ 'id' } }->{ 'body' }\n";
    }

    Or by sending a message ID and Label that the message resides in

    #retrieve specific email message for review
    my $msgid = 'F000000000';
    my $message = $gmail->get_indv_email( id => $msgid, label => 'label01' );
    print "$message->{ $msgid }->{ 'body' }\n";

returns a Hash of Hashes containing the data from an individual message in the following format:

Hash of messages in thread by ID

    $indv_email{ 'id' }
    $indv_email{ 'sender_email' }
    $indv_email{ 'sent' }
    $indv_email{ 'to' }
    $indv_email{ 'read' }
    $indv_email{ 'subject' }
    @{ $indv_email{ 'attachments' } }

    #If it is the main message in the thread
    $indv_email{ 'body' }
    %{ $indv_email{ 'ads' } } = (
        title       => '',
        body        => '',
        vendor_link => '',
        link        => '', );

=head2 MIME MESSAGES

This will return an individual message in MIME format.

    The parameters to this function are the same as get_indv_email.

    #prints out the MIME format for all messages in the inbox
    my $messages = $gmail->get_messages( label => $Mail::Webmail::Gmail::FOLDERS{ 'INBOX' } );
    foreach ( @{ $messages } ) {
        my $message = $gmail->get_mime_email( msg => $_ );
        print $message
    }

    returns a string that contains the MIME formatted email.

=head2 RETRIEVING CONTACTS

The get_contacts method returns a reference to an AoH with all of the
Contacts.  This can be limited to the 'Frequently Mailed' contacts
with a flag:

    my $contacts = $gmail->get_contacts( frequent => 1 );

The Array of hashes is in the following format

    $indv_contact{ 'id' }
    $indv_contact{ 'name1' }
    $indv_contact{ 'name2' }
    $indv_contact{ 'email' }
    $indv_contact{ 'note' }

=head2 SENDING MAIL

The basic format of sending a message is

    $gmail->send_message( to => 'user@domain.com', subject => 'Test Message', msgbody => 'This is a test.' );

To send to multiple users, send an arrayref containing all of the users

    my $email_addrs = [
        'user1@domain.com',
        'user2@domain.com',
        'user3@domain.com', ];
    $gmail->send_message( to => $email_addrs, subject => 'Test Message', msgbody => 'This is a test.' );

You may also send mail using cc and bcc.

To attach files to a message

    $gmail->send_message( to => 'user@domain.com', subject => 'Test Message', msgbody => 'This is a test.', file0 => ["/tmp/foo"], file1 => ["/tmp/bar"] );

=head2 DELETE MESSAGES

Use the following to move a message to the trash bin

    $gmail->delete_message( msgid => $msgid, del_message => 0 );

To permanently delete a message, just send a msgid

    $gmail->delete_message( msgid => $msgid );

=head2 ACTING ON MULTIPLE MESSAGES

To act on multiple messages at once send an array ref containing all of the message IDs you with to act on.  This is useful because
Gmail may temporarily ban you if you send too much traffic in a short amount of time (for instance deleting all of the messaging in
your SPAM folder one at a time).

    ### Delete Many Messages at once ###
    $gmail->delete_message( msgid => \@msgids, search => 'spam', del_message => 1 );

    ### Applying a label to multiple messages at once ###
    $gmail->edit_labels( label => 'label_name', action => 'add', msgid => \@msgids );

=head2 GETTING ATTACHMENTS

There are two ways to get an attachment:

    By sending a reference to a specific attachment returned by get_indv_email

    #creates an array of references to every attachment in your account
    my $messages = $gmail->get_messages();
    my @attachments;

    foreach ( @{ $messages } ) {
        my $email = $gmail->get_indv_email( msg => $_ );
        if ( defined( $email->{ $_->{ 'id' } }->{ 'attachments' } ) ) {
            foreach ( @{ $email->{ $_->{ 'id' } }->{ 'attachments' } } ) {
                push( @attachments, $gmail->get_attachment( attachment => $_ ) );
                if ( $gmail->error() ) {
                    print $gmail->error_msg();
                }
            }
        }
    }

    Or by sending the attachment ID and message ID

    #retrieve specific attachment
    my $msgid = 'F000000000';
    my $attachid = '0.1';
    my $attach_ref = $gmail->get_attachment( attid => $attachid, msgid => $msgid );

Returns a reference to a scalar that holds the data from the attachment.

=head1 SAMPLE GMAIL OUTPUT

This is included so you can get an idea of what the underlying HTML looks like for
Gmail.  It is also included to somewhat document what the current interface needs to
manipulate to extract data from Gmail.

    <html><head><meta content="text/html; charset=UTF-8" http-equiv="content-type"></head>
    <script>D=(top.js&&top.js.init)?function(d){top.js.P(window,d)}:function(){};
    if(window==top){top.location='/gmail?search=inbox&view=tl&start=0&init=1&zx=VERSION + RANDOM 9 DIGIT NUMBER&fs=1';}
    </script><script><!--
    D(["v","fc5985703d8fe4f8"]
    );
    D(["p",["bx_hs","1"]
    ,["bx_show0","1"]
    ,["bx_sc","1"]
    ,["sx_dn","username"]
    ]
    );
    D(["i",0]
    );
    D(["qu","0 MB","1000 MB","0%","#006633"]
    );
    D(["ds",1,0,0,0,0,0]
    );
    D(["ct",[["label 1",1]
    ,["label 2",0]
    ,["label 3",1]
    ]
    ]
    );
    D(["ts",0,50,10,0,"Inbox","",13]
    );
    D(["t",["MSG ID",1,0,"\<b\>12:53am\</b\>","\<span id=\'_user_sender@domain.com\'\>Sender Name\</span\>
    ","\<b\>&raquo;\</b\>&nbsp;","\<b\>Subject\</b\>","Blurb &hellip;",["label1","label 2"]
    ,"attachment name1, attachment name2","MSG ID",0]
    ]
    );

    D(["te"]);

    //--></script><script>var fp='';</script><script>var loaded=true;D(['e']);</script>

=head1 SAMPLE TEST SCRIPTS

below is a listing of some of the tests that I use as I test various features

SAMPLE USAGE

    my ( $gmail ) = Mail::Webmail::Gmail->new( 
            username => 'username', password => 'password', );

    ### Test Sending Message ####
    my $msgid = $gmail->send_message( to => 'mincus@gmail.com', subject => time(), msgbody => 'Test' );
    if ( $msgid ) {
        print "Msgid: $msgid\n";
        if ( $gmail->error() ) {
            print $gmail->error_msg();
        } else {
            ### Create new label ###
            my $test_label = "tl_" . time();
            $gmail->edit_labels( label => $test_label, action => 'create' );
            if ( $gmail->error() ) {
                print $gmail->error_msg();
            } else {
                ### Add this label to our new message ###
                $gmail->edit_labels( label => $test_label, action => 'add', 'msgid' => $msgid );
                if ( $gmail->error() ) {
                    print $gmail->error_msg();
                } else {
                    print "Added label: $test_label to message $msgid\n";
                }
            }
        }
    } else {
        if ( $gmail->error() ) {
            print $gmail->error_msg();
        }
    }
    ###

    ### Move message to trash ###
    my $msgid = $gmail->send_message( to => 'testuser@test.com', subject => "del_" . time(), msgbody => 'Test Delete' );
    if ( $gmail->error() ) {
        print $gmail->error_msg();
    } else {
        $gmail->delete_message( msgid => $msgid, del_message => 0 );
        if ( $gmail->error() ) {
            print $gmail->error_msg();
        } else {
            print "MSG: $msgid moved to trash\n";
        }
    }
    ###

    ### Delete all SPAM folder messages ###
    my $messages = $gmail->get_messages( label => $Mail::Webmail::Gmail::FOLDERS{ 'SPAM' } );
    if ( @{ $messages } ) {
        my @msgids;
        foreach ( @{ $messages } ) {
            push( @msgids, $_->{ 'id' } );
        }
        $gmail->delete_message( msgid => \@msgids, search => 'spam', del_message => 1 );
        if ( $gmail->error() ) {
            print $gmail->error_msg();
        } else {
            print "Deleted " . @msgids . " Messages\n";
        }
    }
    ###

    ### Print out all user defined labels
    my @labels = $gmail->get_labels();
    foreach ( @labels ) {
        print "Label: '" . $_ . "'\n";
    }
    ###

    ### Prints out all _New_ messages attached to the first label
    my @labels = $gmail->get_labels();
    unless ( $gmail->error() ) {
        my $messages = $gmail->get_messages( label => $labels[0] );
        unless( $gmail->error() ) {
            if ( defined( $messages ) ) {
                foreach ( @{ $messages } ) {
                    if ( $_->{ 'new' } ) {
                        print "Subject: " . $_->{ 'subject' } . " / Blurb: " . $_->{ 'blurb' } . "\n";
                    }
                }
            }
        } else {
            print $gmail->error_msg();
        }
    } else {
        print $gmail->error_msg();
    }
    ###

    ### Prints out all attachments
    my $messages = $gmail->get_messages();

    foreach ( @{ $messages } ) {
        my $email = $gmail->get_indv_email( msg => $_ );
        if ( defined( $email->{ $_->{ 'id' } }->{ 'attachments' } ) ) {
            foreach ( @{ $email->{ $_->{ 'id' } }->{ 'attachments' } } ) {
                print ${ $gmail->get_attachment( attachment => $_ ) } . "\n";
                if ( $gmail->error() ) {
                    print $gmail->error_msg();
                }
            }
        }
    }
    ###

    ### Prints out the vendor link from Ads attached to a message
    my $messages = $gmail->get_messages( label => $Mail::Webmail::Gmail::FOLDERS{ 'INBOX' } );

    foreach ( @{ $messages } ) {
        print "ID: " . $_->{ 'id' } . "\n";
        my %email = %{ $gmail->get_indv_email( msg => $_ ) };
        if ( $email{ $_->{ 'id' } }->{ 'ads' } ) {
            my $ads;
            foreach $ads ( @{ $email{ $_->{ 'id' } }->{ 'ads' } } ) {
                print " - AD LINK: $ads->{vendor_link}\n";
            }
        }
    }
    ###

    ### Shows different ways to look through your email
    my $messages = $gmail->get_messages();

    print "By folder\n";
    foreach ( keys %Mail::Webmail::Gmail::FOLDERS ) {
        print "KEY: $_\n";
        my $messages = $gmail->get_messages( label => $Mail::Webmail::Gmail::FOLDERS{ $_ } );
        print "\t$_:\n";
        if ( @{ $messages } ) {
            foreach ( @{ $messages } ) {
                print "\t\t$_->{ 'subject' }\n";
            }
        }
    }

    print "By label\n";
    foreach ( $gmail->get_labels() ) {
        $messages = $gmail->get_messages( label => $_ );
        print "\t$_:\n";
        if ( defined( $messages ) ) {
            if ( @{ $messages } ) {
                foreach ( @{ $messages } ) {
                    print "\t\t$_->{ 'subject' }\n";
                }
            }
        }
    }

    print "All (Note: the All folder skips trash)";
    $messages = $gmail->get_messages();
    if ( @{ $messages } ) {
        foreach ( @{ $messages } ) {
            print "\t\t$_->{ 'subject' }\n";
        }
    }
    ###

    ### Update preferences
        if ( $gmail->update_prefs( signature => 'Test Sig.', max_page_size => 100 ) ) {
            print "Preferences Updated.\n";
        } else {
            print "Unable to update preferences.\n";
        }
    ###

    ### Show all contact email addresses
    my ( @contacts ) = @{ $gmail->get_contacts() };
    foreach ( @contacts ) {
        print $_->{ 'email' } . "\n";
    }
    ###

    ### Print out space remaining in mailbox
    my $remaining = $gmail->size_usage();
    print "Remaining: '" . $remaining . "'\n";
    ###

=head1 AUTHOR INFORMATION

Copyright 2004-2005, Allen Holman.  All rights reserved.  

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

Address bug reports and comments to: 
email: mincus \at cpan \. org
AIM: mincus c03
Website: http://code.mincus.com

When sending bug reports, please provide the version of Gmail.pm, the version of
Perl and the name and version of the operating system you are using. 

=head1 CREDITS

I'd like to thank the following people who gave me a little direction in getting 
this module started (whether they know it or not)

=over 4

=item Simon Drabble (Mail::Webmail::Yahoo)

=item Erik F. Kastner (WWW::Scraper::Gmail)

=item Abiel J. (C# Gmail API - http://www.migraineheartache.com/)

=item Daniel Stutz (http://www.use-strict.net)

=back

=head1 BUGS

Please report them.

=cut
