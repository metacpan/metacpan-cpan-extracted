package Math::Erf::Approx;

use 5.010;
use strict;
use warnings;
use Scalar::Util qw< blessed >;
use Sub::Exporter -setup => { exports => [qw< erf erfc >] };
use Test::More;

BEGIN {
	no warnings 'once';
	$Math::Erf::Approx::AUTHORITY = 'cpan:TOBYINK';
	$Math::Erf::Approx::VERSION   = '0.002';
};

sub erf
{
	my ($x) = @_;
	
	if ($x < 0)
	{
		return -erf(-$x);
	}
	
	my @a = qw< 1.0 0.278393 0.230389 0.000972 0.078108>;
	
	my $sum;
	for my $i (0 .. 4)
	{
		$sum += $a[$i] * ($x ** $i);
	}
	
	1.0 - ($sum ** -4);
}

sub erfc
{
	my ($x, $erf) = @_;
	$erf //= \&erf;
	1.0 - $erf->($x);
}


sub _test_cases
{
	my @numbers = grep { /\d/ } split /\s+/, q{
0.00	0.0000000	1.0000000	1.30	0.9340079	0.0659921
0.05	0.0563720	0.9436280	1.40	0.9522851	0.0477149
0.10	0.1124629	0.8875371	1.50	0.9661051	0.0338949
0.15	0.1679960	0.8320040	1.60	0.9763484	0.0236516
0.20	0.2227026	0.7772974	1.70	0.9837905	0.0162095
0.25	0.2763264	0.7236736	1.80	0.9890905	0.0109095
0.30	0.3286268	0.6713732	1.90	0.9927904	0.0072096
0.35	0.3793821	0.6206179	2.00	0.9953223	0.0046777
0.40	0.4283924	0.5716076	2.10	0.9970205	0.0029795
0.45	0.4754817	0.5245183	2.20	0.9981372	0.0018628
0.50	0.5204999	0.4795001	2.30	0.9988568	0.0011432
0.55	0.5633234	0.4366766	2.40	0.9993115	0.0006885
0.60	0.6038561	0.3961439	2.50	0.9995930	0.0004070
0.65	0.6420293	0.3579707	2.60	0.9997640	0.0002360
0.70	0.6778012	0.3221988	2.70	0.9998657	0.0001343
0.75	0.7111556	0.2888444	2.80	0.9999250	0.0000750
0.80	0.7421010	0.2578990	2.90	0.9999589	0.0000411
0.85	0.7706681	0.2293319	3.00	0.9999779	0.0000221
0.90	0.7969082	0.2030918	3.10	0.9999884	0.0000116
0.95	0.8208908	0.1791092	3.20	0.9999940	0.0000060
1.00	0.8427008	0.1572992	3.30	0.9999969	0.0000031
1.10	0.8802051	0.1197949	3.40	0.9999985	0.0000015
1.20	0.9103140	0.0896860	3.50	0.9999993	0.0000007
	};
	
	my @test_cases;
	while (@numbers)
	{
		push @test_cases, [shift @numbers, shift @numbers, shift @numbers];
	}
	
	return @test_cases;
}

sub _close_enough
{
	my ($x, $y) = @_;
	my $err = abs($x - $y);
	return 1 if $err < 0.0005;
	diag "Got:     $x";
	diag "Expected $y";
	return;
}

sub run_tests
{		
	my ($class) = @_;
	my @cases = $class->_test_cases;
	
	plan tests => (2 * @cases);
	
	foreach my $tc (@cases)
	{
		my ($x, $erf, $erfc) = @$tc;
		ok _close_enough(erf($x), $erf), "erf($x)";
		ok _close_enough(erfc($x), $erfc), "erfc($x)";
	}
}

caller(0) or __PACKAGE__->run_tests;
__END__

=head1 NAME

Math::Erf::Approx - pure Perl approximate implementation of the error function

=head1 DESCRIPTION

This is a pure Perl implementation of the error function (a.k.a. the Gauss
error function). It gives an approximation with a maximum absolute difference
of 0.0005 from the real value.

=head2 Functions

This module can export two functions. Neither is exported by default.
This module uses L<Sub::Exporter>, so the functions can be renamed:

 use Math::Erf::Approx -all => { -prefix => 'math_' };

=over

=item C<< erf($x) >>

Calculates the result of the error function for value $x.

=item C<< erfc($x, \&erf) >>

Given a value $x and a code reference to an implementation of erf(),
calculates the complement.

If the code reference is ommitted (which I'd expect would be the most
usual case), then the default is the C<erf> function provided by this
module.

=back

=head2 Testing

It is possible to run a small test suite on this module using:

 use Math::Erf::Approx;
 Math::Erf::Approx->run_tests;
 
=head1 BENCHMARKS

Benchmarking against L<Games::Go::Erf> (on a fairly underpowered netbook)...

 Benchmark: timing 100000 iterations of GGE, MEA...
   GGE:  6 wallclock secs ( 6.34 usr +  0.01 sys =  6.35 CPU) @ 15748.03/s (n=100000)
   MEA:  3 wallclock secs ( 2.71 usr +  0.00 sys =  2.71 CPU) @ 36900.37/s (n=100000)

There are considerations other than raw speed though...

=over

=item * Games::Go::Erf provides much more accurate results

=item * ... and it can calculate inverses

=item * ... B<but> it has a dependency on L<Tk>

=item * ... B<and> it sets C<< $[ >> to 1, which has been deprecated since Perl 5.12.

=back

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Error_function>.

I<Handbook of Mathematical Functions with Formulas, Graphs, and Mathematical Tables>,
ed Milton Abramowitz and Irene Stegun. ISBN 0-486-61272-4.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=begin trustme

=item run_tests

=end trustme