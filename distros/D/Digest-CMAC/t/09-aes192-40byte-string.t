use Test::More tests => 2;
use Digest::CMAC;
use Digest::OMAC2;


sub cmac {
	my $class = shift;

	my $cmac = "Digest::$class"->new(pack 'H*', '8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b');

	$cmac->add(pack 'H*',
		'6bc1bee22e409f96e93d7e117393172a'.
		'ae2d8a571e03ac9c9eb76fac45af8e51'.
		'30c81c46a35ce411'
	);

	return $cmac;
}

is(cmac("CMAC")->hexdigest, '8a1de5be2eb31aad089a82e6ee908b0e');
is(cmac("OMAC2")->hexdigest, 'b35e2d1b73aed49b78bdbdfe61f646df');
