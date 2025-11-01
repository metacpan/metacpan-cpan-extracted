package Digest::prvhash64;
use strict;
use warnings;
our $VERSION = '0.1.2';

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(prvhash64 prvhash64_64m prvhash64_hex prvhash64_64m_hex);

require XSLoader;
XSLoader::load('Digest::prvhash64', $VERSION);

sub prvhash64_hex {
	my ($msg, $hash_len, $seed) = @_;
	$seed //= 0;

	my $bin = prvhash64($msg, $hash_len, $seed);
	my $ret = unpack('H*', $bin);

	return $ret;
}

sub prvhash64_64m_hex {
	my ($msg, $seed) = @_;
	$seed //= 0;

	my $v   = prvhash64_64m($msg, $seed);
	my $ret = sprintf('%016x', $v);

	return $ret;
}

1;

################################################################################
################################################################################

=pod

=head1 NAME

Digest::prvhash64 - Variable length hashing

=head1 SYNOPSIS

    use Digest::prvhash64;

    my $raw  = prvhash64($str, $hash_bytes);     # Raw bytes
    my $hex  = prvhash64_hex($str, $hash_bytes); # Hex string

    # 64bit "minimal" variant
    my $num  = prvhash64_64m($str);     # 64bit unsigned integer
    my $hex2 = prvhash64_64m_hex($str); # 64bit hex string

=head1 DESCRIPTION

Digest::prvhash64 is a I<variable length> hashing algorithm. It is NOT suitable for
cryptographic purposes (password storage, signatures, etc.).

=head1 METHODS

All functions accept data as a byte string. For deterministic results, callers
should ensure text is encoded to bytes.

=head2 B<prvhash64($str, $hash_size, $seed = 0)>

Compute the hash of C<$str> and return the digest as raw bytes.
The digest may contain NULs and other non-printable bytes.

=head2 B<prvhash64_hex($str, $hash_size, $seed = 0)>

Like C<prvhash64>, but returns the digest encoded as a lowercase hexadecimal
string.

=head2 B<prvhash64_64m($str, $seed = 0)>

Compute the "minimal" 64bit hash of C<$str> and return a 64bit unsigned integer.

=head2 B<prvhash64_64m_hex($str, $seed = 0)>

Compute the "minimal" 64bit hash of C<$str> and return a lowercase hexadecimal
string.

=head1 ENCODING AND PORTABILITY

This hash operates on bytes. If you pass Perl characters (wide/unicode strings)
the result may vary across platforms and Perl builds. For reproducible results,
encode strings to a byte representation explicitly, for example:

    use Encode qw(encode);
    my $hex = prvhash64_hex( encode('UTF-8', $text) );

=head1 SEE ALSO

Digest(3), Encode, Digest::MD5, Digest::SHA

=head1 AUTHOR

Scott Baker - https://www.perturb.org/

=cut
