#!perl -T
use Test::More tests => 68;
use strict;
use warnings;
use Fukurama::Class::AttributesHandler();
BEGIN {
	Fukurama::Class::AttributesHandler->register_helper_method('test_check_def');
}

{
	package LowercaseAttributeClass;
	sub test_check_def {}
	sub nothing {}
}
{
	package EmptyAttributeClass;
	my $TEST = 0;
}
{
	package NoCheckerAttributeClass;
	sub Tester {}
}
{
	package CorrectAttributeClass;
	our $ATT_COUNTER;
	our $CALL_COUNTER;
	sub Tester {
		my $class = $_[0];
		my $def = $_[1];
		if($def->{'class'} eq 'MySecondClass') {
			main::is(ref($def), 'HASH', 'att-definition is ok');
			main::is($def->{'resolved'}, 1, 'sub is allways resolved');
			main::is($def->{'executed'}, 0, 'sub-att is not executed before');
			main::is($def->{'attribute'}, 'Tester', 'att-name is resolved');
			main::like($def->{'sub_name'}, qr/^new2?$/, 'sub-name is resolved');
			main::is($def->{'data'}, 2, 'data is given');
			return 1;
		}
		
		main::is(ref($def), 'HASH', 'att-definition is ok');
		main::is($def->{'resolved'}, 1, 'sub is allways resolved');
		main::is($def->{'executed'}, 0, 'sub-att is not executed before');
		main::is($def->{'attribute'}, 'Tester', 'att-name is resolved');
		main::is(UNIVERSAL::isa($def->{'class'}, 'MyClass'), 1, 'class-name is resolved');
		main::like($def->{'sub_name'}, qr/^new2?$/, 'sub-name is resolved');
		main::is($def->{'data'}, 2, 'data is given');
		
		{

			no strict 'refs';
			no warnings 'redefine';
			
			*{"$def->{'class'}\::$def->{'sub_name'}"} = sub {
				$CALL_COUNTER++;
				goto($def->{'sub'});
			};
		}
		$ATT_COUNTER++;
		return 1;
	}
	sub test_check_def {
		main::failed('checkroutine is never called');
		return;
	}
}
{
	package MyClass;
	our $CODE_ATTRIBUTES;
	sub MODIFY_CODE_ATTRIBUTES {
		my $classname = shift(@_);
		my $coderef = shift(@_);
		my @att_list = @_;
		
		$CODE_ATTRIBUTES++;
		if($CODE_ATTRIBUTES == 1 || $CODE_ATTRIBUTES == 3) {
			main::is(UNIVERSAL::isa($classname, 'MyClass'), 1, 'only class attributes are uses');
			main::is(scalar(@att_list), 1, 'single attribute is handeled');
			main::is($att_list[0], 'Undef', 'only unhandled attributes are used');
		} else {
			main::is(UNIVERSAL::isa($classname, 'MyClass'), 1, 'only class attributes are uses');
			main::is(scalar(@att_list), 2, 'double attribute is handeled');
			main::is($att_list[0], 'Undef2(test)', 'only unhandled attributes are used');
			main::is($att_list[1], 'Undef3', 'only unhandled attributes are used');
		}
		return ();
	}
	BEGIN {
		my $low_att = eval("Fukurama::Class::AttributesHandler->register_attributes('LowercaseAttributeClass');return 1");
		main::is($low_att, undef, 'lowercase attribute class failed');
		main::like($@, qr/Attribute 'nothing'/, 'lowercase attribute failed');
		
		my $empty_att = eval("Fukurama::Class::AttributesHandler->register_attributes('EmptyAttributeClass');return 1");
		main::is($empty_att, undef, 'empty attribute class failed');
		main::like($@, qr/Failed to load/, 'cant load empty class');
		
		my $nc_att = eval("Fukurama::Class::AttributesHandler->register_attributes('NoCheckerAttributeClass');return 1");
		main::is($nc_att, undef, 'attribute class with no checker failed');
		main::like($@, qr/Needed helper method/, 'need checker method');
		
		eval("CorrectAttributeClass->can('nonExistingSub')");
		my $att = eval("Fukurama::Class::AttributesHandler->register_attributes('CorrectAttributeClass');return 1");
		main::is($att, 1, "attribute class loaded: $@");
		main::is($@, '', 'no load errors');
		
		main::is(Fukurama::Class::AttributesHandler->export('MyClass'), 1, 'init once');
		main::is(Fukurama::Class::AttributesHandler->export('MyClass'), 0, 'init twice');
	}
	
	sub new : Tester(2) {}
	sub new2 : Undef : Tester(2) {}
	sub old_two : Undef2(test) : Undef3 {}
	
	main::is($CODE_ATTRIBUTES, 4, 'Class-att-handler was called');
	main::is($CorrectAttributeClass::ATT_COUNTER, 4, 'each att-method is resolved before check');
}
{
	package MyInheritedClass;
	use base 'MyClass';

	sub new : Tester(2) {}
	sub new2 : Undef : Tester(2) {}
	sub old_two : Undef2(test) : Undef3 {}
	
	main::is($MyClass::CODE_ATTRIBUTES, 4, 'Class-att-handler was called');
	main::is($CorrectAttributeClass::ATT_COUNTER, 4, 'each att-method is resolved before check');
}
Fukurama::Class::AttributesHandler->run_check();
main::is($CorrectAttributeClass::ATT_COUNTER, 4, 'each att-method is resolved');

main::is($CorrectAttributeClass::CALL_COUNTER, undef, 'method-call-counter');
MyClass->new();
main::is($CorrectAttributeClass::CALL_COUNTER, 1, 'method-call-counter after call');
MyClass->new2();
MyClass->new2();
main::is($CorrectAttributeClass::CALL_COUNTER, 3, 'method-call-counter after another call');

{
		package MySecondClass;
		BEGIN {
			main::is(Fukurama::Class::AttributesHandler->export('MySecondClass'), 1, 'init once');
			main::is(Fukurama::Class::AttributesHandler->export('MySecondClass'), 0, 'init twice');
		}
		sub new : Tester(2) {}
}

