package Math::LogRand;
use strict;
use warnings;
use POSIX;
require Exporter;

our $VERSION = '0.05';
our @ISA = qw(Exporter);
our @EXPORT = qw( LogRand );

sub LogRand {

	shift if $_[0] eq __PACKAGE__;

	my ($floor, $ceil) = @_;

	$ceil = $floor if $ceil < $floor;
	$ceil = $ceil; # + 1 ; #- $floor;

	return $ceil if $floor >= $ceil;
	my $x = $ceil  - int( log( rand( $ceil - 1 ) + 1 ) / log( $ceil ) * $ceil ) + $floor;
	
	return $x > $ceil? $ceil : $x;
}

1;

__END__

=head1 NAME

Math::LogRand - Perl extension to return a random number with log weighting.

=head1 SYNOPSIS

	use Math::LogRand;
	my %test;
	my $min = 20;
	my $max = 100;
	$test{ LogRand($min,$max) }++ for 0..1000;
	print "$_\toccured $test{$_} times.\n" foreach sort keys %test;

=head1 DESCRIPTION

This module attempts to implement a scalar version of the MATLAB logrand function.

Accepts two arguments: the floor of distribution, and the ceilling of distribution.

Returns a 'random' integer produced by the Perl C<rand()> function,
between input parameters, with weighting to low integers by log distribution.

How good/bad this is, I don't know: it's really for my own convenience, but
I hope you find it useful.  Any suggestions really very gratefully received!

=head2 EXPORT

	LogRand

=head1 AUTHOR

Lee Goddard <lgoddard(a)cpan.org>

=head1 SEE ALSO

	perl(1);
	rand;
	log;

=cut
