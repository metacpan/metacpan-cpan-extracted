package Haineko::SMTPD::Relay::File;
use parent 'Haineko::SMTPD::Relay';
use strict;
use warnings;
use Haineko::SMTPD::Response;
use Email::MIME;
use Time::Piece;
use Try::Tiny;
use IO::File;
use Encode;

sub new {
    my $class = shift;
    my $argvs = { @_ };

    $argvs->{'host'}    ||= '/tmp';
    $argvs->{'port'}      = undef,
    $argvs->{'time'}    ||= Time::Piece->new;
    $argvs->{'sleep'}     = 0;
    $argvs->{'retry'}     = 0;
    $argvs->{'timeout'}   = 0;
    $argvs->{'startls'}   = 0;
    return bless $argvs, __PACKAGE__;
}

sub sendmail {
    my $self = shift;

    my $headerlist = [];
    my $emencoding = uc( $self->{'attr'}->{'charset'} || 'UTF-8' );
    my $methodargv = {
        'body' => Encode::encode( $emencoding, ${ $self->{'body'} } ),
        'attributes' => $self->{'attr'},
    };
    utf8::decode $methodargv->{'body'} unless utf8::is_utf8 $methodargv->{'body'} ;

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
    $methodargv->{'header'} = $headerlist;

    my $mimeobject = Email::MIME->create( %$methodargv );
    my $mailstring = $mimeobject->as_string;
    my $mailfolder = $self->{'host'};
    my $messageid0 = undef;

    if( exists $self->{'head'}->{'Message-Id'} ) {
        # Use the local part of the Message-Id header as a file name.
        $messageid0 = [ split( '@', $self->{'head'}->{'Message-Id'} ) ]->[0];

    } else {
        # Message-Id header is not defined or does not exist
        require Haineko::SMTPD::Session;
        $messageid0 = sprintf( "%s.%d.%d.%03d", 
                        Haineko::SMTPD::Session->make_queueid, $$,
                        $self->time->epoch, int(rand(100)) );
    }

    my $timestring = sprintf( "%s-%s", $self->time->ymd('-'), $self->time->hms );
    my $outputfile = sprintf( "%s/haineko.%s.%s.eml", $mailfolder, $timestring, $messageid0 );
    my $filehandle = undef;
    my $smtpparams = undef;
    my $smtpstatus = 0;

    try {
        $outputfile =~ y{/}{}s;
        $smtpparams = {
            'dsn'     => undef,
            'code'    => 200,
            'host'    => undef,
            'port'    => undef,
            'rcpt'    => $self->{'rcpt'},
            'error'   => 0,
            'mailer'  => 'File',
            'message' => [ $outputfile ],
            'command' => 'DATA',
        };
        $filehandle =  IO::File->new( $outputfile, 'w' ) || die $!;
        utf8::encode $mailstring if utf8::is_utf8 $mailstring;

        $filehandle->print( $mailstring );
        $filehandle->close;
        push @{ $smtpparams->{'message'} }, 'Successfully saved';
        $smtpstatus = 1;

    } catch {
        require Haineko::E;
        my $E = Haineko::E->new( $_ );
        $smtpparams->{'code'} = 400;
        $smtpparams->{'error'} = 1;
        push @{ $smtpparams->{'message'} }, 'Failed to save: '.join( ' ', @{ $E->mesg } );
    };

    $self->response( Haineko::SMTPD::Response->new( %$smtpparams ) );
    return $smtpstatus;
}

1;
__END__

=encoding utf8

=head1 NAME

Haineko::SMTPD::Relay::File - Just save an email message

=head1 DESCRIPTION

Haineko::SMTPD::Relay::File is a dummy connection class for saving an email
message to the specified directory or /tmp. This mailer is useful to debug.

=head1 SYNOPSIS

    use Haineko::SMTPD::Relay::File;
    my $h = { 'Subject' => 'Test', 'To' => 'neko@example.org' };
    my $v = { 
        'mail' => 'kijitora@example.jp',
        'rcpt' => 'neko@example.org',
        'head' => $h,
        'body' => 'Email message',
    };
    my $e = Haineko::SMTPD::Relay::File->new( %$v );
    my $s = $e->sendmail;

    print $s;                   # 1 = Saved, 0 = Failed to save
    print $e->response->error;  # 0 = Saved, 1 = Failed to save
    print $e->response->dsn;    # D.S.N. is always "undef"

    warn Data::Dumper::Dumper $e->response;
    $VAR1 = bless( {
             'dsn' => undef,
             'error' => 0,
             'code' => '200',
             'host' => undef,
             'port' => undef,
             'rcpt' => 'neko@example.org',
             'message' => [
                '/tmp/haineko.2013-12-25-10:43:11.rBPAhBR70454ovYt.70454.1387935791.079.eml',
                'Successfully saved'
             ],
             'command' => 'DATA'
            }, 'Haineko::SMTPD::Response' );

=head1 CLASS METHODS

=head2 C<B<new( I<%arguments> )>>

C<new()> is a constructor of Haineko::SMTPD::Relay::File

    my $e = Haineko::SMTPD::Relay::File->new( 
            'attr' => {                     # Args for Email::MIME
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

C<sendmail()> will save an email to the specified directory or /tmp

    my $e = Haineko::SMTPD::Relay::File->new( %argvs );
    print $e->sendmail;         # 1 = Saved, 0 = Failed to save
    print Dumper $e->response;  # Dumps Haineko::SMTPD::Response object

=head1 MAILERTABLE

"File" mailer can be specified in Mailer table file stored in etc/ directory 
such as C<mailertable> or C<sendermt> as the followings:

=head2 C<mailer: "File">

An email will be saved in /tmp directory.

=head2 C<mailer: "/var/tmp">

An email will be saved in /var/tmp directory. When the specified directory does
not exist or cannot be written, Haineko returns error response.

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut



