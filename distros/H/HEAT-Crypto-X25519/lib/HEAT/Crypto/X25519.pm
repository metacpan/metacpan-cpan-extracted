#!/usr/bin/perl

package HEAT::Crypto::X25519;

use strict;
use warnings;

use XSLoader;
use Digest::SHA;

our $VERSION = '0.04';
XSLoader::load('HEAT::Crypto::X25519', $VERSION);

sub KEYSIZE()
{
	32;
}

sub KEYBUFF()
{
	"\0" x KEYSIZE;
}

sub hash
{
	my $sha = Digest::SHA->new(256);
	$sha->add($_) for @_;
	return $sha->digest;
}

sub keyhash($)
{
	my $k = hash($_[0]);
	_clamp($k);
	return $k;
}

sub keygen($)
{
	my $k = shift;
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

sub shared($$)
{
	my ($k, $p) = @_;
	my $z = KEYBUFF;
	_core($z, undef, $k, $p);
	return $z;
}

sub sign($$)
{
	my ($k, $msg) = @_;

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
	my ($s, $m, $k) = @_;

	my $v = substr($s, 0, 32);
	my $h = substr($s, 32, 64);

	my $y = KEYBUFF;
	_verify($y, $v, $h, $k);

	return hash(hash($m), $y) eq $h;
}

1;

__END__

=head1 NAME

HEAT::Crypto::X25519 - Low-level Curve25519 ECDH and signing routines

=head1 DESCRIPTION

This module provides perl bindings for Matthijs van Duin's implementation of
Daniel J. Bernstein's Curve25519.

=head1 AUTHOR

Toma Mazilu

C implementation by Matthijs van Duin.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself

=head1 SEE ALSO

L<HEAT::Crypto>

=cut

