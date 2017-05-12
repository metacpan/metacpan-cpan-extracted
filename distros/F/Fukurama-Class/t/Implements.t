#!perl -T
use Test::More tests => 16;
use strict;
use warnings;

{
	package MyFirstInterface;
	sub new { 1 }
}
{
	package MySecondInterface;
	sub new { 2 }
	sub get { 3 }
}
{
	package MyFirstClass;
	use Fukurama::Class::Implements('MyFirstInterface');
	use Fukurama::Class::Implements('MySecondInterface');
	sub new {}
	sub get {}
	sub set {}
}
is(eval("return MyFirstInterface->new()"), 1, 'automatic use of interface');
is($@, '', 'no errors');
is(scalar(@MyFirstClass::ISA), 0, 'isa is empty');
is(MyFirstClass->isa('MyFirstInterface'), 1, 'is first interface');
is(MyFirstClass->isa('MySecondInterface'), 1, 'is second interface');
isnt(eval("MyFirstClass->get()"), 3, 'interface isnt inherited');
{
	package MySecondClass;
	eval("use Fukurama::Class::Implements('MyNonexistingInterface')");
	main::like($@, qr(Can't locate), 'croak at nonexisting interface');
}

{
	package MyOtherInterfaceParent;
	sub set {}
}
{
	package MyOtherInterface;
	use base 'MyOtherInterfaceParent';
	sub new {}
}
eval(<<HERE
	{
		package MySecondClass;
		use Fukurama::Class::Implements('MyFirstInterface');
		use Fukurama::Class::Implements('MySecondInterface');
		use Fukurama::Class::Implements('MyOtherInterface');
	}
HERE
);
eval("Fukurama::Class::Implements->run_check('MyRun');");
ok($@, 'error thrown');
like($@, qr/'get'/, 'get missed');
like($@, qr/'new'/, 'new missed');
like($@, qr/'set'/, 'inherited method missed');
my @list = split(/\n/, $@);
is(scalar(@list), 5, 'three failures throwed');

eval("Fukurama::Class::Implements->run_check('MyRun2');");
is($@, '', 'error not thrown twice');

eval(<<HERE
	{
		package MyThirdClass;
		use Fukurama::Class::Implements('MyFirstInterface');
	}
HERE
);
eval("Fukurama::Class::Implements->run_check('MyRun3');");
ok($@, 'more error thrown');
like($@, qr/'new'/, 'new even missed');
my @list2 = split(/\n/, $@);
is(scalar(@list2), 3, 'one failure throwed');
