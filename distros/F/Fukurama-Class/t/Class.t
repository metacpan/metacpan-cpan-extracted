#!perl -T
use Test::More tests => 32;
use strict;
use warnings;

use CGI();
use Fukurama::Class();

BEGIN {
	$Fukurama::Class::Rigid::PACKAGE_NAME_CHECK = 0;
};


eval("use Fukurama::Class( 1, 2, 3 )");
like($@, qr/uneven/i, 'deny uneven parameter');
eval("use Fukurama::Class( 1, 2, 1, 3 )");
like($@, qr/twice/i, 'deny twice option-keys');
eval("use Fukurama::Class( 1, 2 )");
like($@, qr/not allowed/i, 'deny not allowed parameter');
eval("use Fukurama::Class( version => 'a' )");
like($@, qr/value.*version.*not allowed/i, 'croak at not allowed or incorrect value-type');
eval("use Fukurama::Class( extends => 'MyTestClass' )");
like($@, qr/value.*extends.*not allowed/i, 'croak at an unloaded class');
eval("use Fukurama::Class( extends => '' )");
is($@, '', 'can have no parent');
eval("use Fukurama::Class( implements => [] )");
is($@, '', 'can have no interface');
eval("use Fukurama::Class( implements => ['MyInterface', 'MySecondItf'] )");
like($@, qr/value.*MyInterface.*MySecondItf.*implements.*not allowed/i, 'croak at wrong interface');

{
	package MyVersion;
	eval("use Fukurama::Class( version => 1.5 )");
	main::is($@, '', 'accept versions');
	main::is($MyVersion::VERSION, 1.5, 'version works');
}

{
	package MyExtends;
	eval("use Fukurama::Class( extends => 'CGI' )");
	main::is($@, '', 'accept extends');
	main::is(join(', ', @MyExtends::ISA), 'CGI', 'extends works');
}
{
	package MyImplements;
	sub new {}
}
{
	package MyInterface;
	use Fukurama::Class( implements => 'MyVersion' );
	use Fukurama::Class( implements => ['MyVersion', 'MyImplements'] );
	main::is($@, '', 'accept implements');
	main::is(join(', ', @MyInterface::ISA), '', 'no ISA pollution');
	main::is(UNIVERSAL::isa('MyInterface', 'MyVersion'), 1, 'implements works as single');
	main::is(UNIVERSAL::isa('MyInterface', 'MyImplements'), 1, 'implements works as list');
	main::is(MyInterface->isa('MyImplements'), 1, 'isa is overwritten');
	sub new : Method(static|int|) {}
}
{
	package MyAbstract;
	use Fukurama::Class;
	sub new : Method(static|int|){}
	eval("use Fukurama::Class( abstract => 1 );Fukurama::Class::Abstract->run_check()");
	main::is($@, '', 'abstract works');
	eval("MyAbstract->new()");
	main::like($@, qr/abstract class/i, 'abstract croak at runtime');
}
{
	package MyAttributes;
	use base 'MyAbstract';
	no strict;
	sub new : Method(static|int|) { 1 }
}
is(MyAttributes->new(), 1, 'abstract method called by child');
{
	package MyFullUsage;
	use Fukurama::Class( extends => 'MyAbstract', implements => 'MyImplements', version => 1.10, abstract => 1 );
	sub new : Method(static|int|) {}
}
eval {
	MyFullUsage->new();
};
like($@, qr/Abstract class/, 'calling abstract class');
{
	package MyChild;
	use base 'MyFullUsage';
	sub new : Method(static|int|) {}
}

{
	package MyDefCheckParent;
	use Fukurama::Class(extends => '');
	
	sub new : Constructor(public|) {
		my $self =  bless({}, $_[0]);
		eval {
			$self->_test();
		};
		main::is($@, '', 'protected method can be called from parent');
		return $self;
	}
	sub _test : Method(protected|void|) {}
}
{
	package MyDefCheckChild;
	use Fukurama::Class(extends => 'MyDefCheckParent');
	
	sub _test : Method(protected|void|) {}
	
	__PACKAGE__->new()
}
{
	package MyChangeAccessLevelParent;
	use Fukurama::Class(extends => '');
	
	sub _prot : Method(protected|void|) {}
	sub _priv : Method(private|void|) {}
}
{
	package MyChangeAccessLevelChildPriv;
	use Fukurama::Class;
	
	sub _prot : Method(private|void|) {}
	eval("use Fukurama::Class( extends => 'MyChangeAccessLevelParent' );Fukurama::Class->run_check();");
	{
		
		no strict 'refs';
		
		%{*{__PACKAGE__ . '::'}} = ();
	}
	main::like($@, qr/can't be another/, 'cant change from protected to private');
}
{
	package MyChangeAccessLevelChildProt;
	use Fukurama::Class;
	
	sub _priv : Method(protected|void|) {}
	eval("use Fukurama::Class( extends => 'MyChangeAccessLevelParent' );Fukurama::Class->run_check();");
	{
		
		no strict 'refs';
		
		%{*{__PACKAGE__ . '::'}} = ();
	}
	main::like($@, qr/can't be another/, 'cant change from private to protected');
}
{
	package MyOtherStatic;
	use Fukurama::Class(extends => '');
	sub new : Constructor(public|) {
		bless({}, $_[0]);
	}
}
{
	package MyStatic;
	use Fukurama::Class(extends => '');
	sub new : Constructor(public|) {
		bless({}, $_[0]);
	}
	sub static : Method(public static|boolean|) {
		1
	}
	sub method : Method(public|boolean|) {
		1
	}
	
	my $o = __PACKAGE__->new();
	main::is(eval { $o->static() }, 1, 'can call static method from object');
	main::is(eval { __PACKAGE__->static() }, 1, 'can call static method from class');
	main::is(eval{ static('MyOtherStatic') }, undef, "can't call static method with wrong class-param");
	main::is(eval{ static() }, undef, "can't call static method with no class-param");
	
	main::is(eval { $o->method() }, 1, 'can call method from object');
	main::is(eval{ __PACKAGE__->method() }, undef, "can't call method from class");
	my $other_class = MyOtherStatic->new();
	main::is(eval{ method($other_class) }, undef, "can't call method with wrong object-param");
	main::is(eval{ method() }, undef, "can't call method with no object-param");
}

