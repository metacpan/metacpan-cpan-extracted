use Test::More tests => 2;
use Digest::CMAC;
use Digest::OMAC2;

sub cmac {
	my $class = shift;

	my $cmac = "Digest::$class"->new(pack 'H*', '603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4');

	$cmac->add(pack 'H*',
		'6bc1bee22e409f96e93d7e117393172a'.
		'ae2d8a571e03ac9c9eb76fac45af8e51'.
		'30c81c46a35ce411e5fbc1191a0a52ef'.
		'f69f2445df4f9b17ad2b417be66c3710'
	);

	return $cmac;
}

is(cmac("CMAC")->hexdigest, 'e1992190549f6ed5696a2c056c315410');
is(cmac("OMAC2")->hexdigest, 'e1992190549f6ed5696a2c056c315410');

