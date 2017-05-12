package Haineko::SMTPD::Relay::Mandrill;
use parent 'Haineko::SMTPD::Relay';
use strict;
use warnings;
use Furl;
use Try::Tiny;
use Time::Piece;
use Haineko::JSON;
use Haineko::SMTPD::Response;
use Email::MIME;
use Encode;
use Class::Accessor::Lite;

use constant 'MANDRILL_ENDPOINT' => 'mandrillapp.com';
use constant 'MANDRILL_APIVERSION' => '1.0';

my $rwaccessors = [
    'queueid',  # (String) Queue ID on Mandrill API
];
Class::Accessor::Lite->mk_accessors( @$rwaccessors );

sub new {
    my $class = shift;
    my $argvs = { @_ };

    $argvs->{'time'}    ||= Time::Piece->new;
    $argvs->{'sleep'}   ||= 5;
    $argvs->{'timeout'} ||= 30;
    $argvs->{'queueid'}   = undef;
    return bless $argvs, __PACKAGE__;
}

sub sendmail {
    my $self = shift;

    if( not $self->{'password'} ) {
        # API-KEY(password) is empty
        my $r = {
            'code'    => 400,
            'host'    => MANDRILL_ENDPOINT,
            'port'    => 443,
            'rcpt'    => $self->{'rcpt'},
            'error'   => 1,
            'mailer'  => 'Mandrill',
            'message' => [ 'Empty API-KEY' ],
            'command' => 'POST',
        };
        $self->response( Haineko::SMTPD::Response->new( %$r ) );
        return 0
    }

    # * All API calls should be made with HTTP POST.
    # * You can consider any non-200 HTTP response code an error 
    #   - the returned data will contain more detailed information
    # * All methods are accessed via: https://mandrillapp.com/api/1.0/SOME-METHOD.OUTPUT_FORMAT
    my $mandrillep = sprintf( "https://%s/api/%s/messages/send-raw.json", MANDRILL_ENDPOINT, MANDRILL_APIVERSION );
    my $timestamp1 = Time::Piece->new;
    my $headerlist = [];
    my $emencoding = uc( $self->{'attr'}->{'charset'} || 'UTF-8' );
    my $mimeparams = {
        'body' => Encode::encode( $emencoding, ${ $self->{'body'} } ),
        'attributes' => $self->{'attr'},
    };
    utf8::decode $mimeparams->{'body'} unless utf8::is_utf8 $mimeparams->{'body'} ;

    for my $e ( @{ $self->{'head'}->{'Received'} } ) {
        # Convert email headers
        push @$headerlist, 'Received' => $e;
    }
    push @$headerlist, 'To' => $self->{'rcpt'};

    for my $e ( keys %{ $self->{'head'} } ) {
        # Make email headers except ``Received'' and ``MIME-Version''
        next if $e eq 'Received';
        next if $e eq 'MIME-Version';

        if( ref $self->{'head'}->{ $e } eq 'ARRAY' ) {

            for my $f ( @{ $self->{'head'}->{ $e } } ) {
                push @$headerlist, $e => $f;
            }
        }
        else { 
            push @$headerlist, $e => $self->{'head'}->{ $e };
        }
    }
    $mimeparams->{'header'} = $headerlist;

    my $mimeobject = Email::MIME->create( %$mimeparams );
    my $parameters = {
        'key'         => $self->{'password'},
        'to'          => [ $self->{'rcpt'} ],
        'from_email'  => $self->{'mail'},
        'raw_message' => $mimeobject->as_string,
    };

    my $methodargv = { 
        'agent'    => $self->{'ehlo'},
        'timeout'  => $self->{'timeout'},
        'ssl_opts' => { 'SSL_verify_mode' => 0 }
    };
    my $httpclient = Furl->new( %$methodargv );
    my $htrequest1 = Haineko::JSON->dumpjson( $parameters );
    my $htresponse = undef;
    my $retryuntil = $self->{'retry'} || 0;
    my $smtpstatus = 0;

    my $sendmailto = sub {
        $htresponse = $httpclient->post( $mandrillep, undef, $htrequest1 );

        return 0 unless defined $htresponse;
        return 0 unless $htresponse->is_success;

        $smtpstatus = 1;
        return 1;
    };

    while(1) {
        last if $sendmailto->();
        last if $retryuntil == 0;

        $retryuntil--;
        sleep $self->{'sleep'};
    }

    if( defined $htresponse ) {
        # Check the response from Mandrill API
        my $htcontents = undef;
        my $nekoparams = { 
            'code'    => $htresponse->code,
            'host'    => MANDRILL_ENDPOINT,
            'port'    => 443,
            'rcpt'    => $self->{'rcpt'},
            'error'   => $htresponse->is_success ? 0 : 1,
            'mailer'  => 'Mandrill',
            'message' => [ $htresponse->message ],
            'command' => 'POST',
        };

        try { 
            # Mandrill respond contents as a JSON
            $htcontents = Haineko::JSON->loadjson( $htresponse->body );
            my $v = [];

            if( ref $htcontents eq 'HASH' ) {
                # Example Error Response JSON
                # {
                #     "status": "error",
                #     "code": 12,
                #     "name": "Unknown_Subaccount",
                #     "message": "No subaccount exists with the id 'customer-123'"
                # }
                for my $e ( 'status', 'code', 'name', 'message' ) {
                    # Parse error response
                    next unless exists $htcontents->{ $e };
                    next unless defined $htcontents->{ $e };
                    push @$v, sprintf( "%s: s", $e, $htcontents->{ $e } );
                }
                $self->{'queueid'} = q();

            } elsif( ref $htcontents eq 'ARRAY' ){
                # Example Response JSON
                # [
                #     {
                #         "email": "recipient.email@example.com",
                #         "status": "sent",
                #         "reject_reason": "hard-bounce",
                #         "_id": "abc123abc123abc123abc123"
                #     }
                # ]
                while( my $r = shift @{ $htcontents } ) {
                    # Parse each response
                    for my $e ( '_id', 'status', 'reject_reason' ) {
                        next unless exists $r->{ $e };
                        next unless defined $r->{ $e };
                        push @$v, sprintf( "%s: %s", $e, $r->{ $e } );
                        $self->{'queueid'} ||= $r->{ $e } if $e eq '_id';
                    }
                }
            } 
            push @{ $nekoparams->{'message'} }, @$v;
        
        } catch {
            # It was not JSON
            require Haineko::E;
            $nekoparams->{'error'} = 1;
            $nekoparams->{'message'} = [ Haineko::E->new( $htresponse->body )->text ];
            push @{ $nekoparams->{'message'} }, Haineko::E->new( $_ )->text;
        };
        $self->response( Haineko::SMTPD::Response->new( %$nekoparams ) );
    }

    return $smtpstatus;
}

sub getbounce {
    my $self = shift;

    return 0 unless $self->{'password'};

    my $mandrillep = sprintf( "https://%s/api/%s/messages/search.json", MANDRILL_ENDPOINT, MANDRILL_APIVERSION );
    my $parameters = {
        'key'       => $self->{'password'},
        'query'     => $self->{'rcpt'},
        'date_from' => $self->{'time'}->ymd('-'),
        'date_to'   => $self->{'time'}->ymd('-'),
        'senders'   => [ $self->{'mail'} ],
        'api_keys'  => [ $self->{'password'} ],
        'limit'     => 2,
    };

    my $methodargv = { 
        'agent'     => $self->{'ehlo'},
        'timeout'   => $self->{'timeout'},
        'ssl_opts'  => { 'SSL_verify_mode' => 0 }
    };
    my $httpclient = Furl->new( %$methodargv );
    my $htrequest1 = Haineko::JSON->dumpjson( $parameters );
    my $htresponse = undef;
    my $retryuntil = $self->{'retry'} || 0;
    my $httpstatus = 0;

    my $getbounced = sub {
        $htresponse = $httpclient->post( $mandrillep, undef, $htrequest1 );

        return 0 unless defined $htresponse;
        return 0 unless $htresponse->is_success;

        $httpstatus = 1;
        return 1;
    };

    while(1) {
        last if $getbounced->();
        last if $retryuntil == 0;

        $retryuntil--;
        sleep $self->{'sleep'};
    }

    if( defined $htresponse ) {
        # Check the response of getting bounce from Mandrill API
        my $htcontents = undef;
        my $nekoparams = undef;

        eval { $htcontents = Haineko::JSON->loadjson( $htresponse->body ) };

        while(1) {
            last if $@;
            last unless ref $htcontents eq 'ARRAY';
            last unless scalar @$htcontents;

            while( my $r = shift @$htcontents ) {
                next unless ref $r eq 'HASH';
                next if $r->{'_id'} ne $self->{'queueid'};
                $nekoparams = { 
                    'message' => [ $r->{'diag'}, $r->{'bounce_description'} ],
                    'command' => 'POST',
                };
                last;
            }
            $self->response( Haineko::SMTPD::Response->p( %$nekoparams ) );
            last;
        }
    }
    return $httpstatus;
}

1;
__END__

=encoding utf8

=head1 NAME

Haineko::SMTPD::Relay::Mandrill - Mandrill/MailChimp Web API class for sending email

=head1 DESCRIPTION

Send an email to a recipient via Mandrill using Web API.

=head1 SYNOPSIS

    use Haineko::SMTPD::Relay::Mandrill;
    my $h = { 'Subject' => 'Test', 'To' => 'neko@example.org' };
    my $v = { 
        'username' => 'api_user', 
        'password' => 'api_key',
        'ehlo' => 'UserAgent name for Furl',
        'mail' => 'kijitora@example.jp',
        'rcpt' => 'neko@example.org',
        'head' => $h,
        'body' => 'Email message',
    };
    my $e = Haineko::SMTPD::Relay::Mandrill->new( %$v );
    my $s = $e->sendmail;

    print $s;                   # 0 = Failed to send, 1 = Successfully sent
    print $e->response->error;  # 0 = No error, 1 = Error
    print $e->response->dsn;    # always returns undef
    print $e->response->code;   # HTTP response code from Mandrill API

    warn Data::Dumper::Dumper $e->response;
    $VAR1 = bless( {
             'dsn' => undef,
             'error' => 0,
             'code' => '200',
             'host' => 'mandrillapp.com',
             'port' => 443,
             'rcpt' => 'neko@example.org',
             'message' => [ 'OK' ],
             'command' => 'POST'
            }, 'Haineko::SMTPD::Response' );

=head1 CLASS METHODS

=head2 C<B<new( I<%arguments> )>>

C<new()> is a constructor of Haineko::SMTPD::Relay::Mandrill

    my $e = Haineko::SMTPD::Relay::Mandrill->new( 
            'username' => 'username',       # API User for Mandrill
            'password' => 'password',       # API Key for Mandrill
            'timeout' => 60,                # Timeout for Furl
            'attr' => {
                'content_type' => 'text/plain'
            },
            'head' => {                     # Email header
                'Subject' => 'Test',
                'To' => 'neko@example.org',
            },
            'body' => 'Email message',      # Email body
            'mail' => 'kijitora@example.jp',# Envelope sender
            'rcpt' => 'cat@example.org',    # Envelope recipient
    );

=head1 INSTANCE METHODS

=head2 C<B<sendmail>>

C<sendmail()> will send email to the specified recipient via specified host.

    my $e = Haineko::SMTPD::Relay::Mandrill->new( %argvs );
    print $e->sendmail; # 0 = Failed to send, 1 = Successfully sent

    print Dumper $e->response; # Dumps Haineko::SMTPD::Response object

=head2 C<B<getbounce>>

C<getbounce()> retrieve bounced records using Mandrill API.

    my $e = Haineko::SMTPD::Relay::Mandrill->new( %$argvs );
    print $e->getbounce;    # 0 = No bounce or failed to retrieve
                            # 1 = One or more bounced records retrieved

    print Data::Dumper::Dumper $e->response;
    $VAR1 = bless( {
                 'dsn' => '5.1.1',
                 'error' => 1,
                 'code' => '550',
                 'message' => [
                                '550 5.1.1 <user@example.org>... User unknown '
                              ],
                 'command' => 'POST'
               }, 'Haineko::SMTPD::Response' );

=head2 SEE ALSO

https://mandrillapp.com/api/docs/

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut

