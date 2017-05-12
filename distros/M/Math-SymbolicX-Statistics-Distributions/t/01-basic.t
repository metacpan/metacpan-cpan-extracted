# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl MSS-Dist1.t'

#########################
use strict;
use warnings;

use Test::LectroTest
	trials => 100, retries => 0;

use Math::Symbolic qw/parse_from_string PI EULER/;
use Math::SymbolicX::Statistics::Distributions qw/:all/;

#########################

use constant EPS => 0.000001;

my $normal = normal_distribution();
my $gen_mu = Float( range => [-5, 5] );
my $gen_sigma = Float( range => [0, 5] );
my $gen_x = Float( sized => 0, range => [ $gen_mu-$gen_sigma, $gen_mu+$gen_sigma ] );

Property {
	##[ mu <- $gen_mu, sigma <- $gen_sigma, x <- $gen_x ]##
	
	my $res = 1/$sigma/sqrt(2 * PI)
		  * EULER**(-($x-$mu)**2/(2*$sigma**2));
	my $value = $normal->value( x => $x, sigma => $sigma, mu => $mu );
	
	$value + EPS >= $res and $value - EPS <= $res
}, name => 'normal distribution';


my $gauss = gauss_distribution('foo*2', 'bar/2');

Property {
	##[ mu <- $gen_mu, sigma <- $gen_sigma, x <- $gen_x ]##

	my $res = 1/($sigma/2)/sqrt(2 * PI)
		  * EULER**(-($x-$mu*2)**2/(2*($sigma/2)**2));
	my $value = $gauss->value( x => $x, bar => $sigma, foo => $mu );

	$value + EPS >= $res and $value - EPS <= $res
}, name => 'gauss distribution with replace';



my $bivariate = bivariate_normal_distribution(
undef, undef, undef, undef, 'correlation/2');

Property {
	##[ mu1 <- $gen_mu, sigma1 <- $gen_sigma, x1 <- $gen_x, mu2 <- $gen_mu, sigma2 <- $gen_sigma, x2 <- $gen_x ]##

	my $sigma12 = ($sigma1*$sigma2) * rand();
	my $plug_in_as_sigma12 = $sigma12*2;

	my $res = 
		1/(2* PI*$sigma1*$sigma2*sqrt(1-($sigma12/$sigma1/$sigma2)**2))
		* EULER**(
			(2*$sigma12*($x1-$mu1)*($x2-$mu2)/($sigma1*$sigma2)**2
			-($x1-$mu1)**2/$sigma1**2
			-($x2-$mu2)**2/$sigma2**2
			)
			/ (2 - 2*($sigma12/$sigma1/$sigma2)**2)
		);	
	
	my $value = $bivariate->value(
		x1 => $x1,
		x2 => $x2,
		sigma1 => $sigma1,
		sigma2 => $sigma2,
		mu1 => $mu1,
		mu2 => $mu2,
		correlation => $plug_in_as_sigma12,
	);

	$value + EPS >= $res and $value - EPS <= $res
}, name => 'bivariate normal distribution';




my $cauchy = cauchy_distribution('foo*2', 'bar/2');

Property {
	##[ m <- $gen_mu, fwhm <- $gen_sigma, x <- $gen_x ]##

	my $res = ($fwhm/(2* PI))/( ($x-$m)**2 + $fwhm**2/4 );
	my $value = $cauchy->value( x => $x, bar => $fwhm*2, foo => $m/2 );
	
	$value + EPS >= $res and $value - EPS <= $res
}, name => 'cauchy distribution with replace';





