package IO::Stream::MatrixSSL;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.2';

use IO::Stream::const;
use IO::Stream::MatrixSSL::const;
use Crypt::MatrixSSL3 qw( :all );

use IO::Stream::MatrixSSL::Client;
use IO::Stream::MatrixSSL::Server;


sub stream {
    my ($self) = @_;
    my $stream = $self;
    while ($stream->{_master}) {
        $stream = $stream->{_master};
    }
    return $stream;
}

sub T {
    my ($self) = @_;
    my $m = $self->{_master};
    $m->EVENT(0, ETOHANDSHAKE);
    return;
}

sub WRITE {
    my ($self) = @_;
    my $m = $self->{_master};
    if ($self->{_closed}) {
        $m->EVENT(0, 'ssl closed: closure alert or fatal alert was sent');
    }
    elsif (!$self->{_handshaked}) {
        $self->{_want_write} = 1;
    }
    elsif (!$self->{_want_close}) {
        my $s = substr $m->{out_buf}, $m->{out_pos}||0;
        my $n = length $s;
ENCODE:
        while (length $s) {
            my $s2 = substr $s, 0, SSL_MAX_PLAINTEXT_LEN, q{};
            my $rc = $self->{_ssl}->encode_to_outdata($s2);
            return $m->EVENT(0, 'ssl error: '.get_ssl_error($rc)) if $rc <= 0;
            while (my $bytes = $self->{_ssl}->get_outdata($self->{out_buf})) {
                $rc = $self->{_ssl}->sent_data($bytes);
                last if $rc == PS_SUCCESS;
                next if $rc == MATRIXSSL_REQUEST_SEND;
                next if $rc == MATRIXSSL_HANDSHAKE_COMPLETE;
                if ($rc == MATRIXSSL_REQUEST_CLOSE) {
                    $self->{_want_close} = 1;
                    # XXX Will report to $m "{out_buf} was completely sent"
                    # while is may be only partially sent.
                    last ENCODE;
                }
                return $m->EVENT(0, 'ssl error: '.get_ssl_error($rc));
            }
        }
        if (defined $m->{out_pos}) {
            $m->{out_pos} += $n;
        } else {
            $m->{out_buf} = q{};
        }
        $m->{out_bytes} += $n;
        $m->EVENT(OUT);
        $self->{_slave}->WRITE();
    }
    return;
}

sub EVENT { ## no critic (ProhibitExcessComplexity)
    my ($self, $e, $err) = @_;
    my $m = $self->{_master};
    if ($e & SENT && $self->{_want_close}) {
        $self->{_closed} = 1;
        $err ||= 'ssl closed: closure alert or fatal alert was sent';
    }
    $e &= ~OUT;
    if (!$self->{_handshaked}) {
        $e &= ~SENT;
    }
    return if !$e && !$err;
    if ($e & IN) {
        $e &= ~IN;
RECV:
        my @warnings;
        while (length $self->{in_buf}) {
            my $rc = $self->{_ssl}->received_data($self->{in_buf}, my $buf);
RC:
            last if $rc == PS_SUCCESS;
            next if $rc == MATRIXSSL_REQUEST_RECV;
            next if $rc == MATRIXSSL_REQUEST_SEND;
            if ($rc == MATRIXSSL_HANDSHAKE_COMPLETE) {
                $self->_handshaked();
                next;
            }
            if ($rc == MATRIXSSL_RECEIVED_ALERT) {
                my ($level, $descr) = get_ssl_alert($buf);
                if ($level == SSL_ALERT_LEVEL_FATAL) {
                    $self->{_ssl}->processed_data($buf);
                    $err ||= "ssl fatal alert: $descr";
                    last;
                }
                if ($descr != SSL_ALERT_CLOSE_NOTIFY) {
                    push @warnings, $descr;
                }
            }
            elsif ($rc == MATRIXSSL_APP_DATA) {
                $self->_handshaked();
                $e |= IN;
                $m->{in_buf}    .= $buf;
                $m->{in_bytes}  += length $buf;
            }
            elsif ($rc == MATRIXSSL_APP_DATA_COMPRESSED) {
                $self->_handshaked();
                $err ||= 'ssl error: not implemented because USE_ZLIB_COMPRESSION should not be enabled';
                last;
            }
            else {
                $err ||= 'ssl error: '.get_ssl_error($rc);
                last;
            }
            $rc = $self->{_ssl}->processed_data($buf);
            goto RC;
        }
        if (@warnings) {
            # XXX warning alert(s) may be lost if some other error or
            # fatal alert happens after warning alert(s).
            $err ||= join q{ }, 'ssl warning alert:', @warnings;
        }
SEND:
        while (my $bytes = $self->{_ssl}->get_outdata($self->{out_buf})) {
            my $rc = $self->{_ssl}->sent_data($bytes);
            last if $rc == PS_SUCCESS;
            next if $rc == MATRIXSSL_REQUEST_SEND;
            if ($rc == MATRIXSSL_HANDSHAKE_COMPLETE) {
                $self->_handshaked();
                next;
            }
            if ($rc == MATRIXSSL_REQUEST_CLOSE) {
                $self->{_want_close} = 1;
                last;
            }
            $err ||= 'ssl error: '.get_ssl_error($rc);
            last;
        }
        if (length $self->{out_buf}) {
            $self->{_slave}->WRITE();
        }
    }
    if ($e & RESOLVED) {
        $m->{ip} = $self->{ip};
    }
    if ($e & EOF) {
        $m->{is_eof} = $self->{is_eof};
        if (!$self->{_handshaked}) {
            $err ||= 'ssl handshake error: unexpected EOF';
        }
    }
    if ($e & CONNECTED) {
        $self->{_t} = EV::timer(TOHANDSHAKE, 0, $self->{_cb_t});
    }
    $m->EVENT($e, $err);
    return;
}

sub _handshaked {
    my ($self) = @_;
    if (!$self->{_handshaked}) {
        $self->{_handshaked} = 1;
        undef $self->{_t};
        if ($self->{_want_write}) {
            $self->WRITE();
        }
    }
    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=for stopwords crt

=head1 NAME

IO::Stream::MatrixSSL - Crypt::MatrixSSL plugin for IO::Stream


=head1 VERSION

This document describes IO::Stream::MatrixSSL version v2.0.2


=head1 SYNOPSIS

    use IO::Stream;
    use IO::Stream::MatrixSSL;

    # SSL server
    IO::Stream->new({
        ...
        plugin => [
            ...
            ssl     => IO::Stream::MatrixSSL::Server->new({
                crt     => 'mysrv.crt',
                key     => 'mysrv.key',
            }),
            ...
        ],
    });

    # SSL client
    IO::Stream->new({
        ...
        plugin => [
            ...
            ssl     => IO::Stream::MatrixSSL::Client->new({
                cb      => \&validate,
            }),
            ...
        ],
    });
    sub validate {
        my ($ssl, $certs) = @_;
        my $stream = $ssl->stream();
        # check cert, for ex.: $certs->[0]{subject}{commonName}
        return 0;
    }


=head1 DESCRIPTION

This module is plugin for IO::Stream which allow you to use SSL (on both
client and server streams).


=head1 INTERFACE

=head2 IO::Stream::MatrixSSL::Client

=head3 new

    $plugin_ssl_client = IO::Stream::MatrixSSL::Client->new();

    $plugin_ssl_client = IO::Stream::MatrixSSL::Client->new({
        crt         => '/path/to/client.crt',
        key         => '/path/to/client.key',
        pass        => 's3cret',
        trusted_CA  => '/path/to/ca-bundle.crt',
        cb          => \&validate,
    });

Create and returns new IO::Stream plugin object.

=over

=item crt

=item key

=item pass

Authenticate client on server using client's certificate.
(You'll need Crypt::MatrixSSL3 compiled with support for client authentication.)

C<crt> and C<key> should contain file names of client's certificate and
private key (in PEM format), C<pass> should contain password (as string)
for private key.

You can provide multiple file names with client's certificates in C<crt>
separated by C<;>.

All optional (C<crt> and C<key> should be either both provided or both omitted,
C<pass> should be provided only if C<key> file protected by password).

=item trusted_CA

This should be name of file (or files) with allowed CA certificates,
required to check RSA signature of server certificate. Crypt::MatrixSSL3
provides such a file, so chances are you doesn't need to change default
{trusted_CA} value (C<$Crypt::MatrixSSL3::CA_CERTIFICATES>) if you just
wanna connect to public https servers.

There may be many files listed in {trusted_CA}, separated by C<;>.
Each file can contain many CA certificates.

=item cb

This should be CODE ref to your callback, which will check server
certificate. Callback will be called with two parameters:
IO::Stream::MatrixSSL::Client (or IO::Stream::MatrixSSL::Server - if
you're validating client's certificate) object and HASH ref with
certificate details (see L</SYNOPSIS> for example).

Callback should return a number >=0 if this certificate is acceptable,
and we can continue with SSL handshake, or number <0 if this certificate
isn't acceptable and we should interrupt this connection and return error
to IO::Stream user callback. If this function will throw exception, it will
be handled just as return(-1).

Hash with certificate details will looks this way:

    verified       => $verified,
    notBefore      => $notBefore,
    notAfter       => $notAfter,
    subjectAltName => {
        dns             => $dns,
        uri             => $uri,
        email           => $email,
        },
    subject        => {
        country         => $country,
        state           => $state,
        locality        => $locality,
        organization    => $organization,
        orgUnit         => $orgUnit,
        commonName      => $commonName,
        },
    issuer         => {
        country         => $country,
        state           => $state,
        locality        => $locality,
        organization    => $organization,
        orgUnit         => $orgUnit,
        commonName      => $commonName,
        },

where all values are just strings except these:

    $verified
        Status of cetrificate RSA signature check:
        -1  signature is wrong
         1  signature is correct
    $notBefore
    $notAfter
        Time period when certificate is active, in format
        YYYYMMDDHHMMSSZ     (for ex.: 20061231235959Z)

=back

=head3 stream

    $stream = $plugin_ssl_client->stream();

Returns IO::Stream object related to this plugin object.


=head2 IO::Stream::MatrixSSL::Server

Same as above for IO::Stream::MatrixSSL::Client.


=head1 MIGRATION

MatrixSSL often makes incompatible API changes, and so does
Crypt::MatrixSSL3. Sometimes because of this IO::Stream::MatrixSSL also
change API in incompatible way, and below explained how to migrate your
code.

=head2 1.1.2 to 2.0.0

Parameters for validation callback was changed:

    sub validate {
        ### WAS
        my ($certs, $ssl, $stream) = ($_[0], @{ $_[1] });

        ### NOW
        my ($ssl, $certs) = @_;
        my $stream = $ssl->stream();

        ...
    }

Some error messages was changed too.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-IO-Stream-MatrixSSL/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-IO-Stream-MatrixSSL>

    git clone https://github.com/powerman/perl-IO-Stream-MatrixSSL.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=IO-Stream-MatrixSSL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/IO-Stream-MatrixSSL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-Stream-MatrixSSL>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=IO-Stream-MatrixSSL>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/IO-Stream-MatrixSSL>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The GNU General Public License version 2

instead of less restrictive MIT only because…

MatrixSSL is distributed under the GNU General Public License…

Crypt::MatrixSSL3 uses MatrixSSL, and so inherits the same license…

IO::Stream::MatrixSSL uses Crypt::MatrixSSL3, and so inherits the same license.

GPL is a virus, avoid it whenever possible!


=cut
