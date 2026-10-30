package Mail::DKIM2::Digest;
use strict;
use warnings;

our $VERSION = '0.28';

use Carp;
use Crypt::Digest::SHA256 ();
use Crypt::Digest::SHA512 ();

# The hashes over message content -- every Message-Instance's header and
# body hashes -- are almost all of a verifier's work on a big message.
# CryptX's SHA-2 is portable C (about 460 MB/s on an Apple M-series, 150 on
# the dkim2.com box); OpenSSL's uses the CPU's SHA instructions where there
# are some (3.3 GB/s and 270 MB/s). So OpenSSL's, through Net::SSLeay, when
# that is installed (it usually is: IO::Socket::SSL needs it), and CryptX's
# otherwise. The digests are the same.

my %CRYPTX = (
    sha256 => 'Crypt::Digest::SHA256',
    sha512 => 'Crypt::Digest::SHA512',
);

my ($OPENSSL, %MD);
sub openssl_available {
    $OPENSSL //= eval {
        require Net::SSLeay;
        Net::SSLeay::OpenSSL_add_all_digests();
        for my $alg (keys %CRYPTX) {
            $MD{$alg} = Net::SSLeay::EVP_get_digestbyname($alg) or die "no $alg\n";
        }
        1;
    } ? 1 : 0;
    return $OPENSSL;
}

# 'openssl' or 'cryptx'; set (local) to choose, as the tests do.
our $BACKEND;

sub backend {
    $BACKEND //= openssl_available() ? 'openssl' : 'cryptx';
    return $BACKEND;
}

# new($alg): an object with add($data, ...) and digest(), as CryptX's.
sub new {
    my ($class, $alg) = @_;
    my $cx = $CRYPTX{$alg} or croak "unsupported hash algorithm: $alg";
    return $cx->new unless backend() eq 'openssl' && openssl_available();
    my $ctx = Net::SSLeay::EVP_MD_CTX_create();
    Net::SSLeay::EVP_DigestInit($ctx, $MD{$alg});
    return bless \$ctx, $class;
}

sub add {
    my $self = shift;
    Net::SSLeay::EVP_DigestUpdate($$self, $_) for @_;
    return $self;
}

sub digest {
    my ($self) = @_;
    my $d = Net::SSLeay::EVP_DigestFinal($$self);
    Net::SSLeay::EVP_MD_CTX_destroy($$self);
    $$self = undef;
    return $d;
}

sub DESTROY {
    my ($self) = @_;
    Net::SSLeay::EVP_MD_CTX_destroy($$self) if $$self;
}

# digest($alg, $data): the raw digest of $data.
sub digest_data {
    my $d = __PACKAGE__->new($_[0]);
    $d->add($_[1]);
    return $d->digest;
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::Digest - SHA-2 over message content, by OpenSSL where it can

=head1 SYNOPSIS

  use Mail::DKIM2::Digest;

  my $d = Mail::DKIM2::Digest->new('sha256');
  $d->add($chunk) for @chunks;
  my $raw = $d->digest;

  my $raw = Mail::DKIM2::Digest::digest_data('sha512', $data);

=head1 DESCRIPTION

Every hash over message content (Message-Instance header and body hashes)
goes through here. With L<Net::SSLeay> installed it is OpenSSL's, which uses
the CPU's SHA instructions where there are any (several times quicker than
CryptX's on such a CPU); otherwise L<CryptX>'s. The digests are the same.

=head1 FUNCTIONS AND METHODS

=head2 new($alg)

C<sha256> or C<sha512>; croaks on anything else. The object has C<add(@data)>
and C<digest()> (once), as a L<Crypt::Digest> object has.

=head2 add(@data)

Hashes more data; returns the object.

=head2 digest()

The raw digest. The object is finished with.

=head2 digest_data($alg, $data)

A function: the raw digest of C<$data>.

=head2 backend()

C<openssl> or C<cryptx>: what C<new> uses. C<$Mail::DKIM2::Digest::BACKEND>
set to either (C<local>ly) chooses; C<cryptx> is used if OpenSSL's is not
available.

=head2 openssl_available()

True if L<Net::SSLeay> is installed and has OpenSSL's SHA-256 and SHA-512.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
