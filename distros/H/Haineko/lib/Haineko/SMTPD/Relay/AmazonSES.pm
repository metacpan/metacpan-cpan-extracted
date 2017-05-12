package Haineko::SMTPD::Relay::AmazonSES;
use parent 'Haineko::SMTPD::Relay';
use strict;
use warnings;
use Furl;
use Try::Tiny;
use Encode;
use Email::MIME;
use MIME::Base64;
use Time::Piece;
use Digest::SHA 'hmac_sha256_base64';
use Haineko::SMTPD::Response;

use constant 'SES_ENDPOINT' => 'email.us-east-1.amazonaws.com';
use constant 'SES_APIVERSION' => '2010-12-01';

sub new {
    my $class = shift;
    my $argvs = { @_ };

    $argvs->{'time'}    ||= Time::Piece->new;
    $argvs->{'sleep'}   ||= 5;
    $argvs->{'timeout'} ||= 30;
    return bless $argvs, __PACKAGE__;
}

sub sign {
    my $class = shift;
    my $value = shift;  # (String) Text
    my $skeyv = shift;  # (String) Key

    my $signedtext = Digest::SHA::hmac_sha256_base64( $value, $skeyv );
    while( length( $signedtext ) % 4 ) {
        $signedtext .= '=';
    }
    return $signedtext;
}

sub sendmail {
    my $self = shift;

    if( ! $self->{'username'} || ! $self->{'password'} ) {
        # Access Key ID(username) or Secret Key(password) is empty
        my $r = {
            'host'    => SES_ENDPOINT,
            'port'    => 443,
            'rcpt'    => $self->{'rcpt'},
            'code'    => 400,
            'error'   => 1,
            'mailer'  => 'AmazonSES',
            'message' => [ 'Empty Access Key ID or Secret Key' ],
            'command' => 'POST',
        };
        $self->response( Haineko::SMTPD::Response->new( %$r ) );
        return 0
    }

    # Create email as string
    my $headerlist = [];
    my $emencoding = uc( $self->{'attr'}->{'charset'} || 'UTF-8' );
    my $methodargv = {
        'body' => Encode::encode( $emencoding, ${ $self->{'body'} } ),
        'attributes' => $self->{'attr'},
    };
    utf8::encode $methodargv->{'body'} if utf8::is_utf8 $methodargv->{'body'};

    for my $e ( @{ $self->{'head'}->{'Received'} } ) {
        # Convert email headers
        push @$headerlist, 'Received' => $e;
    }

    for my $e ( keys %{ $self->{'head'} } ) {
        # Make email headers except ``MIME-Version''
        next if $e eq 'MIME-Version';

        if( ref $self->{'head'}->{ $e } eq 'ARRAY' ) {
            # Such as Received: header
            for my $f ( @{ $self->{'head'}->{ $e } } ) {
                push @$headerlist, $e => $f;
            }

        } else { 
            push @$headerlist, $e => $self->{'head'}->{ $e };
        }
    }
    $methodargv->{'header'} = $headerlist;

    my $mimeobject = Email::MIME->create( %$methodargv );
    my $mailstring = MIME::Base64::encode_base64 $mimeobject->as_string;

    # http://docs.aws.amazon.com/ses/latest/DeveloperGuide/query-interface.html
    my $amazonses1 = sprintf( "https://%s/", SES_ENDPOINT );
    my $dateheader = gmtime;
    my $datestring = $dateheader->strftime;
    my $parameters = {
        'Action' => 'SendRawEmail',
        'Source' => $self->{'mail'},
        'RawMessage.Data' => $mailstring,
        'Destinations.member.1' => $self->{'rcpt'},
        'Timestamp' => $dateheader->datetime.'.000Z',
        'Version' => SES_APIVERSION,
    };

    # AWS3 AWSAccessKeyId=AKIAIOSFODNN7EXAMPLE,Signature=lBP67vCvGlDMBQ=dofZxg8E8SUEXAMPLE,Algorithm=HmacSHA256,SignedHeaders=Date;Host
    my $headerkeys = [ 'AWSAccessKeyId', 'Signature', 'Algorithm' ];
    my $reqheaders = {
        'Date' => $datestring,
        'Host' => SES_ENDPOINT,
    };
    my $identifier = {
        'AWSAccessKeyId' => $self->{'username'},
        'Signature' => __PACKAGE__->sign( $reqheaders->{'Date'}, $self->{'password'} ),
        'Algorithm' => 'HmacSHA256',
        'SignedHeaders' => 'Date',
    };
    my $authheader = join( ', ', map { sprintf( "%s=%s", $_, $identifier->{ $_ } ) } @$headerkeys );


    $methodargv = { 
        'agent' => $self->{'ehlo'},
        'timeout' => $self->{'timeout'},
        'ssl_opts' => { 'SSL_verify_mode' => 0 },
        'headers' => [
            'date' => $datestring,
            'host' => SES_ENDPOINT,
            'content-type' => 'application/x-www-form-urlencoded',
            'if-ssl-cert-subject' => sprintf( "/CN=%s", SES_ENDPOINT ),
            'x-amzn-authorization' => sprintf( "AWS3-HTTPS %s", $authheader ),
        ],
    };
    my $httpclient = Furl->new( %$methodargv );
    my $htresponse = undef;
    my $retryuntil = $self->{'retry'} || 0;
    my $smtpstatus = 0;
    my $exceptions = 0;
    my $sendmailto = sub {
        $htresponse = $httpclient->post( $amazonses1, undef, $parameters );
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
        # Check response from API
        my $htcontents = undef;
        my $htmimetype = $htresponse->content_type || q();
        my $nekoparams = { 
            'code'    => $htresponse->code,
            'host'    => SES_ENDPOINT,
            'port'    => 443,
            'rcpt'    => $self->{'rcpt'},
            'error'   => $htresponse->is_success ? 0 : 1,
            'mailer'  => 'AmazonSES',
            'message' => [ $htresponse->message ],
            'command' => 'POST',
        };

        if( $htmimetype eq 'text/xml' ) {
            # text/xml
            try { 
                require XML::Simple;

            } catch {
                # XML::Simple is not installed
                $nekoparams->{'error'} = 1;
                $nekoparams->{'message'} = [ 'Please install XML::Simple 2.20 or later' ];
                $exceptions = 1;
            };

            if( not $exceptions ) {
                # XML::Simple is already installed
                try {
                    # Amazon SES respond contents as a XML
                    $htcontents = XML::Simple::XMLin( $htresponse->content );

                    for my $e ( keys %{ $htcontents->{'Error'} } ) {
                        # Get error messages
                        my $v = $htcontents->{'Error'}->{ $e };
                        push @{ $nekoparams->{'message'} }, sprintf( "%s=%s", $e, $v );
                    }

                } catch {
                    # It was not JSON
                    require Haineko::E;
                    my $v = $htresponse->body || q();

                    $nekoparams->{'error'} = 1;
                    $nekoparams->{'message'} = [ Haineko::E->new( $v )->text ] if $v;
                    push @{ $nekoparams->{'message'} }, Haineko::E->new( $_ )->text;
                };
            }

        } else {

            require Haineko::E;
            $nekoparams->{'error'} = 1;
            $nekoparams->{'message'} = [ Haineko::E->new( $htresponse->message )->text ];
        }
        $self->response( Haineko::SMTPD::Response->new( %$nekoparams ) );
    }

    return $smtpstatus;
}

1;
__END__

=encoding utf8

=head1 NAME

Haineko::SMTPD::Relay::AmazonSES - Amazon SES API class for sending email

=head1 DESCRIPTION

Send an email to a recipient via Amazon SES using API.

=head1 SYNOPSIS

    use Haineko::SMTPD::Relay::AmazonSES;
    my $h = { 'Subject' => 'Test', 'To' => 'neko@example.org' };
    my $v = { 
        'username' => 'Access Key ID', 'password' => 'Secret Key',
        'ehlo' => 'UserAgent name for Furl',
        'mail' => 'kijitora@example.jp', 'rcpt' => 'neko@example.org',
        'head' => $h, 'body' => 'Email message',
    };
    my $e = Haineko::SMTPD::Relay::AmazonSES->new( %$v );
    my $s = $e->sendmail;

    print $s;                   # 0 = Failed to send, 1 = Successfully sent
    print $e->response->error;  # 0 = No error, 1 = Error
    print $e->response->dsn;    # always returns undef
    print $e->response->code;   # HTTP response code from AmazonSES API

    warn Data::Dumper::Dumper $e->response;
    $VAR1 = bless( {
             'dsn' => undef,
             'error' => 0,
             'code' => '200',
             'message' => [ 'OK' ],
             'command' => 'POST'
            }, 'Haineko::SMTPD::Response' );

=head1 CLASS METHODS

=head2 C<B<new( I<%arguments> )>>

C<new()> is a constructor of Haineko::SMTPD::Relay::AmazonSES

    my $e = Haineko::SMTPD::Relay::AmazonSES->new( 
            'username' => 'username',       # API Access Key ID for AmazonSES
            'password' => 'password',       # API Secret Key for AmazonSES
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

    my $e = Haineko::SMTPD::Relay::AmazonSES->new( %argvs );
    print $e->sendmail;         # 0 = Failed to send, 1 = Successfully sent
    print Dumper $e->response;  # Dumps Haineko::SMTPD::Response object

=head1 SEE ALSO

http://docs.aws.amazon.com/ses/latest/DeveloperGuide/query-interface.html

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
