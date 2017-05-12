#!perl -T
use Test::More tests => 6;
use lib qw(./ ./t);
use strict;
use warnings;

{
	package RootClass;
	sub new {}
}
{
	package MyFirst;
	use base 'RootClass';
	use Fukurama::Class::Attributes;
	sub new : Constructor(|string) {}
	sub get : Method(public static|void@string()|int[],string;boolean) {}
}
{
	package MySecond;
	use Fukurama::Class::Attributes;
	use base 'MyFirst';
	sub new : Constructor(static|string) {}
}
{
	package MyThird;
	use base 'MyFirst';
	use Fukurama::Class::Attributes;
	sub new : Constructor(public static|string) {
		my $class = $_[0];
		
		return bless({}, $class);
	}
	sub get : Method(static final public|void@string()|int[],string;boolean,int) {
		my $class = $_[0];
		my $key = $_[1];
		
		return 1, 2, 3;
	}
}
{
	package MyClass;
	use base 'MyFirst';
	use base 'MySecond';
	use Fukurama::Class::Attributes;
	use Fukurama::Class::Implements('MyThird');
	
	sub new : Constructor(public static|string) {
		my $class = $_[0];
		
		return bless({}, $class);
	}
	sub _get : Method(static private|int@int()|string) {
		my $class = $_[0];
		my $key = $_[1];
		
		return (wantarray ? split(//, $key) : $key);
	}
	sub get : Method(static public|void@string()|int[],string;boolean,int) {
		my $class = $_[0];
		my $key = $_[1];
		
		return 1, 2, 3;
	}
}
{
	package MyChild;
	use base 'MyClass';
	sub new : Constructor(|string) {}
}
{
	package MyGrandChild;
	use Fukurama::Class::Implements('MyThird');
	use base 'MyChild';
	sub new : Constructor(|string) {}
	sub get : Method(static public|void@string()|int[],string;boolean,int) {}
}
eval {
	my $c = new MyClass(1, 2);
};
like($@, qr/no further parameter expected/, 'to much parameters');
eval {
	my $c = MyClass->_get(1);
};
like($@, qr/is declared as private/, 'not a private call');
{
	package MyClass;
	main::is(MyClass->_get(123), 123, 'scalar return');
	main::is_deeply([MyClass->_get(123)], [1, 2, 3], 'array return');
}
eval {
	my $result = MyClass->get([],1,1,1);
};
like($@, qr/'void' expected/, 'no void result');
eval {
	my @c = MyClass->get([], 1, 1, 1);
};
is($@, '', 'return an array in array context');
