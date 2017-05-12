use Test::More tests => 2;
use Digest::CMAC;
use Digest::OMAC2;

sub cmac {
	my $class = shift;

	my $cmac = "Digest::$class"->new(pack 'H*', '603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4');

	$cmac->add(pack 'H*',
		'6bc1bee22e409f96e93d7e117393172a'.
		'ae2d8a571e03ac9c9eb76fac45af8e51'.
		'30c81c46a35ce411'
	);

	return $cmac;
}

is(cmac("CMAC")->hexdigest, 'aaf3d8f1de5640c232f5b169b9c911e6');
is(cmac("OMAC2")->hexdigest, 'f018e6053611b34bc872d6b7ff24749f');

