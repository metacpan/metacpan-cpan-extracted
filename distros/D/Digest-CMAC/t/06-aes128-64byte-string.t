use Test::More tests => 2;
use Digest::CMAC;
use Digest::OMAC2;

sub cmac {
	my $class = shift;

	my $cmac = "Digest::$class"->new(pack 'H*', '2b7e151628aed2a6abf7158809cf4f3c');

	$cmac->add(pack 'H*',
		'6bc1bee22e409f96e93d7e117393172a'.
		'ae2d8a571e03ac9c9eb76fac45af8e51'.
		'30c81c46a35ce411e5fbc1191a0a52ef'.
		'f69f2445df4f9b17ad2b417be66c3710'
	);

	return $cmac;
}

is( cmac("CMAC")->hexdigest, '51f0bebf7e3b9d92fc49741779363cfe');
is( cmac("OMAC2")->hexdigest, '51f0bebf7e3b9d92fc49741779363cfe');
