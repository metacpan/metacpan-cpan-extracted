#!/usr/bin/perl

package HEAT::Crypto;

use strict;
use warnings;

use Carp;
use HEAT::Crypto::X25519;
use Crypt::Mode::CBC;

use Exporter qw(import);
our @EXPORT_OK = qw(hash heat_key get_private_key keygen priv_to_pub_key
	shared_key sign verify encrypt decrypt account_id random_bytes tohex unhex);

our $VERSION = '0.04';

my $cbc = Crypt::Mode::CBC->new('AES');
*hash = \&HEAT::Crypto::X25519::hash;

sub tohex($)
{
	return undef unless defined $_[0];
	unpack('H*', $_[0]);
}

sub unhex($)
{
	return undef unless defined $_[0];
	pack('H*', $_[0]);
}

sub heat_key($)
{
	my $spec = shift;

	unless (defined $spec) {
		croak('undefined key spec');
	} elsif (length $spec == HEAT::Crypto::X25519::KEYSIZE) {
		return $spec;
	} elsif ($spec =~ /^[[:xdigit:]]{64}$/) {
		return unhex($spec);
	} else {
		croak('invalid key spec: %q', $spec);
	}
}

sub get_private_key($)
{
	my $spec = shift;

	if ($spec =~ /^([a-z]{3,12}( |\Z)){12}$/) {
		return HEAT::Crypto::X25519::keyhash($spec);
	} else {
		return heat_key($spec);
	}
}

sub priv_to_pub_key($)
{
	my $p = get_private_key($_[0]);
	my $r = HEAT::Crypto::X25519::keygen($p);
	return tohex($r->{p});
}

sub account_id($)
{
	my $k = heat_key($_[0]);
	my $h = hash($k);

	my ($id, $t1, $t2) = (0);

	for (my $i = 7; $i >= 0; $i--) {
		$t1 = $id * 256;
		$t2 = $t1 + vec($h, $i, 8);
		$id = $t2;
	}

	return $id;
}

sub random_bytes(;$)
{
	my $n = $_[0] || 32;
	my $b = '';

	while (length $b < $n)
	{
		$b .= pack('i', int rand(0xffffffff));
	}

	return $b;
}

sub keygen(;$)
{
	my $k = shift // random_bytes(HEAT::Crypto::X25519::KEYSIZE);
	my $r = HEAT::Crypto::X25519::keygen($k);

	return {
		p => tohex($r->{p}),
		s => tohex($r->{s}),
		k => tohex($r->{k}),
	};
}

sub shared_key($$)
{
	my $k = get_private_key($_[0]);
	my $p = heat_key($_[1]);

	return tohex(HEAT::Crypto::X25519::shared($k, $p));
}

sub sign($$)
{
	my $k = get_private_key($_[0]);
	my $msg = $_[1];
	return tohex(HEAT::Crypto::X25519::sign($k, $msg));
}

sub verify($$$)
{
	my ($s, $m) = @_;
	my $k = heat_key($_[2]);

	unless (defined $s) {
		croak('undefined signature');
	} elsif ($s =~ /^[[:xdigit:]]{128}$/) {
		$s = unhex($s);
	} elsif (length $s != 64) {
		croak('invalid signature: %q', $s);
	}

	HEAT::Crypto::X25519::verify($s, $m, $k);
}

sub encrypt($$;$)
{
	my ($data, $k, $p) = @_;

	my $key = @_ == 3 ? unhex(shared_key($k, $p)) : heat_key($k);

	my $iv = random_bytes(16);
	my $nonce = random_bytes(32);

	for (my $i = 0; $i < 32; $i++) {
		vec($key, $i, 8) = vec($key, $i, 8) ^ vec($nonce, $i, 8);
	}

	my $encrypted = eval { $cbc->encrypt($data, hash($key), $iv) };
	return undef if $@;

	return wantarray ? ($nonce, $iv, $encrypted) : $nonce . $iv . $encrypted;
}

sub decrypt($$;$)
{
	my ($data, $k, $p) = @_;

	my $key = @_ == 3 ? unhex(shared_key($k, $p)) : heat_key($k);

	my ($nonce, $iv, $encrypted) = ref($data) eq 'ARRAY'
		? @{$data} : unpack('a32 a16 a*', $data);

	for (my $i = 0; $i < 32; $i++) {
		vec($key, $i, 8) = vec($key, $i, 8) ^ vec($nonce, $i, 8);
	}

	my $decrypted = eval { $cbc->decrypt($encrypted, hash($key), $iv) };
	return undef if $@;

	return $decrypted;
}

1;

__END__

=head1 NAME

HEAT::Crypto - HEAT cryptographic routines

=head1 SYNOPSIS

  use HEAT::Crypto qw(keygen shared_key sign verify encrypt decrypt);
 
  # generate public-private key pairs
  my $alice = keygen($seed);
  my $bob = keygen($seed);
 
  # compute shared secret
  my $secret = shared_key($alice->{k}, $bob->{p});
  shared_key($bob->{k}, $alice->{p}) eq $secret or die;
 
  # message signing and verifying
  my $signature = sign($alice->{k}, $message);
  verify($signature, $message, $alice->{p}) or die;
 
  # message encryption and decryption
  my $encrypted = encrypt($message, $secret);
  decrypt($encrypted, $secret) eq $message or die;

=head1 DESCRIPTION

This module provides HEAT compatible ECDH key agreement, signing and
encryption ported to perl from the HEAT SDK.

The functions below are not exported by default and need to be imported
explicitly:

=over 4

=item keygen()

=item keygen( $seed );

Generate a new key pair. It returns a hash with 3 values:

  {
    p => <public key bytes>,
    k => <private key bytes>,
    s => <signing key bytes>,
  }

=item shared_key( $private_key, $public_key );

Compute shared secret.

Returns the key as a hexadecimal string.

=item sign( $private_key, $message );

Sign message with the private key.

Returns the signature as a hexadecimal string.

=item verify( $signature, $message, $public_key );

Verifies the message signature against the public key.

Returns 1 on success.

=item encrypt( $data, $key );

Encrypts data with the given key.

In array context it returns the encryption nonce, initialization vector and
cypher text. In scalar context it concatenates them.

=item decrypt( $data, $key );

Decrypts data with the given key. Data is expected to be returned by encrypt();

It returns the decrypted data on success. This function might die in case of errors.

=item priv_to_pub_key( $private_key )

Derives the public key from the private key.

Returns the public key as a hexadecimal string.

=item account_id( $public_key )

Derives the account ID from the public key.

Returns an integer.

=back

=head1 AUTHOR

Toma Mazilu

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself

=head1 SEE ALSO

=over

=item * L<https://github.com/heatcrypto/heat-sdk>

=back

=cut
