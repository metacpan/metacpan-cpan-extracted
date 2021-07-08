#!/usr/bin/perl

package HEAT::Crypto;

use strict;
use warnings;

use Carp;
use XSLoader;
use Digest::SHA;
use Crypt::Mode::CBC;
use Crypt::PRNG qw(random_bytes);

our $VERSION = '0.07';
XSLoader::load('HEAT::Crypto', $VERSION);

use Exporter qw(import);
our @EXPORT_OK = qw(hash keyspec keygen priv_to_pub_key
	shared_key sign verify encrypt decrypt account_id tohex unhex);

my $cbc = Crypt::Mode::CBC->new('AES');

sub KEYSIZE()
{
	32;
}

sub KEYBUFF()
{
	"\0" x KEYSIZE;
}

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

sub hash
{
	my $sha = Digest::SHA->new(256);
	$sha->add($_) for @_;
	return $sha->digest;
}

sub keyhash
{
	my $k = hash(@_);
	_clamp($k);
	return $k;
}

sub keygen(;$)
{
	my $k = defined($_[0]) ? keyspec($_[0]) : random_bytes(KEYSIZE);
	my $p = KEYBUFF;
	my $s = KEYBUFF;

	_clamp($k);
	_core($p, $s, $k, undef);

	return {
		p => $p,
		s => $s,
		k => $k,
	};
}

sub shared_key($$)
{
	my $k = keyspec($_[0], 1);
	my $p = keyspec($_[1]);
	my $z = KEYBUFF;
	_core($z, undef, $k, $p);

	return $z;
}

sub sign($$)
{
	my $k = keyspec($_[0], 1);
	my $msg = $_[1];

	my $m = hash($msg);
	my $r = keygen($k);
	my $x = hash($m, $r->{s});
	my $y = keygen($x);
	my $h = hash($m, $y->{p});

	my $v = KEYBUFF;
	if (_sign($v, $h, $x, $r->{s})) {
		return $v . $h;
	}

	return undef;
}

sub verify($$$)
{
	my ($s, $m) = @_;
	my $k = keyspec($_[2]);

	unless (defined $s) {
		croak('undefined signature');
	} elsif ($s =~ /^[[:xdigit:]]{128}$/) {
		$s = unhex($s);
	} elsif (length $s != 64) {
		croak('invalid signature: %q', $s);
	}

	my $v = substr($s, 0, 32);
	my $h = substr($s, 32, 64);

	my $y = KEYBUFF;
	_verify($y, $v, $h, $k);

	return hash(hash($m), $y) eq $h;
}

sub keyspec($;$)
{
	my ($spec, $is_private) = @_;

	unless (defined $spec) {
		croak('undefined key spec');
	} elsif ($is_private && $spec =~ /^([a-z]{3,12}( |\Z)){12}$/) {
		return keyhash($spec);
	} elsif (length $spec == KEYSIZE) {
		return $spec;
	} elsif ($spec =~ /^[[:xdigit:]]{64}$/) {
		return unhex($spec);
	} else {
		croak('invalid key spec: %q', $spec);
	}
}

sub priv_to_pub_key($)
{
	my $k = keyspec($_[0], 1);
	my $r = keygen($k);
	return $r->{p};
}

sub account_id($)
{
	my $k = keyspec($_[0]);
	my $h = hash($k);

	my ($id, $t1, $t2) = (0);

	for (my $i = 7; $i >= 0; $i--) {
		$t1 = $id * 256;
		$t2 = $t1 + vec($h, $i, 8);
		$id = $t2;
	}

	return $id;
}

sub encrypt($$;$)
{
	my ($data, $k, $p) = @_;

	my $key = @_ == 3 ? shared_key($k, $p) : keyspec($k);

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

	my $key = @_ == 3 ? shared_key($k, $p) : keyspec($k);

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
  my $alice = keygen();
  my $bob = keygen();
 
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
message encryption ported to perl from the HEAT SDK.

The functions provided below need to be imported explicitly.

=over 4

=item keygen()

=item keygen( $seed_key );

Generates a new key pair. It returns a hash with 3 values:

  {
    p => <public key bytes>,
    k => <private key bytes>,
    s => <signing key bytes>,
  }

=item shared_key( $private_key, $public_key );

Computes shared secret.

Returns the key bytes.

=item sign( $private_key, $message );

Sign message with the private key.

Returns the signature bytes.

=item verify( $signature, $message, $public_key );

Verifies the message signature against the public key.

Returns 1 on success.

=item encrypt( $data, $key );

Encrypts data with the given key.

In array context it returns the encryption nonce, initialization vector and
cypher text. In scalar context it concatenates them.

=item decrypt( $data, $key );

Decrypts data with the given key. Data is expected to be in the format returned
by encrypt();

It returns the decrypted data on success or undefined in case of failure.

=item priv_to_pub_key( $private_key )

Derives the public key from the private key.

=item account_id( $public_key )

Derives the account ID from the public key.

=item keyspec( $key )

=item keyspec( $key, $is_private )

Parses the key specification into a 32 bytes buffer. A key can be specified as
a 64 characters hexadecimal string and a private key can be specified as a
secret phrase. All functions accepting key parameters use this functions to
read them.

=back

=head1 AUTHOR

Toma Mazilu

Curve25519 ECDH C implementation by Matthijs van Duin

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself

=head1 SEE ALSO

=over

=item * L<https://github.com/heatcrypto/heat-sdk>

=back

=cut
