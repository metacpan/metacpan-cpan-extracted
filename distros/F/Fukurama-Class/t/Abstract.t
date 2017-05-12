#!perl -T
use Test::More tests => 19;
use lib qw(./ ./t);
use strict;
use warnings;

our $REGISTER = [];
our @CALLER = ();
our $IMPORT;

END {
	main::is(scalar(@$REGISTER), 1, 'END is called correct');
}
use Abstract::MyAbstractClass;
{
	package MyChild;
	use base 'Abstract::MyAbstractClass';
	sub get {
		my $class = shift;
		
		$class->SUPER::get(@_);
	}
}
isnt(eval("return Abstract::MyAbstractClass->create();"), 1, 'call create method');
like($@, qr/call/, 'call create method croaked');
isnt(eval("return Abstract::MyAbstractClass::create();"), 1, 'call create direct');
like($@, qr/call/, 'call create direct croaked');


is(MyChild->create(), 1, 'call create method');
is(MyChild->get(), 2, 'call get method');

@CALLER = ();
is(MyChild->get(3), 3, 'pass parameters');
is(scalar(@CALLER), 2, 'caller length');
is($CALLER[0]->[0], 'MyChild', 'caller 1');
is($CALLER[1]->[0], 'main' , 'caller 2');

isnt(eval("return Abstract::MyAbstractClass->new();"), 1, 'call new method');
like($@, qr/call/, 'call new method croaked');
isnt(eval("return Abstract::MyAbstractClass::new();"), 1, 'call new direct');
like($@, qr/call/, 'call new direct croaked');

my $obj = MyChild->new();
is(UNIVERSAL::isa($obj, 'MyChild'), 1, 'child-object is ok');
is(UNIVERSAL::isa($obj, 'Abstract::MyAbstractClass'), 1, 'child-objects has abstract as parent');

eval("use Abstract::MyAbstractClass;");
is($@, '', 'no errors by abstract special-method-call');
is($IMPORT, 2, 'Import is called correct');
