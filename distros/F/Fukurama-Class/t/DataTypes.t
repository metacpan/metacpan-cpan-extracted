#!perl -T
use Test::More tests => 359;
use strict;
use warnings;

{
	package MyClass;
	sub new {
		bless({}, $_[0]);
	}
}
{
	package MyOwnClass;
	use base 'MyClass';
	our $NAME = 'MyOwnName2';
	sub get {
		return $NAME;
	}
}
{
	package MyWrongClass;
	sub new {
		bless({}, $_[0]);
	}
}

use Fukurama::Class::DataTypes();
Fukurama::Class::DataTypes->set_type_checker('MyOwnClass', sub {
	my $parameter = $_[0];
	my $data_type_checker_name = $_[1];

	my $error = undef;
	my $is_ok = 0;
	if(ref($parameter)) {
		if(UNIVERSAL::isa($parameter, 'MyOwnClass')) {
			if($parameter->get('name') eq 'CorrectName') {
				$is_ok = 1;
			} else {
				$error = 'nameIsNotCorrect';
			}
		} else {
			$error = 'wrongObject';
		}
	} else {
		$error = 'notAnObject';
	}
	return ($is_ok, $parameter, $error);
});

sub test_type {
	my $type = $_[0];
	my $success = $_[1];
	my $error_msg = $_[2];
	my $msg = $_[3];
	my $is_class = $_[4];
	my $data = $_[5];
	
	$msg = "$type(" . ($success ? 'ok' : 'nok') . ") - $msg";
	
	my $def = Fukurama::Class::DataTypes->get_check_definition($type, '');
	is($def->{'is_class'}, $is_class, "$msg: definition " . ($is_class ? 'is a class' : 'is no class'));
	is(ref($def->{'check'}), 'CODE', "$msg: type checker is there");
	is(ref($def->{'param_0'}), 'CODE', "$msg: ref checker is there");

	my ($r_success, $r_data, $r_error_msg) = &{$def->{'check'}}($def->{'param_0'}, $data, $type, \0, [$data]);
	is($r_success, $success, "$msg: result");
	if($is_class && !$success) {
		is($r_data, $data, "$msg: returned class data");
	} elsif(!$is_class && $success) {
		is($r_data, undef, "$msg: returned data");
	}
	is($r_error_msg, $error_msg, "$msg: error message");
}

$MyOwnClass::NAME = 'CorrectName';
test_type('MyOwnClass', 1, undef, 'normal', 1, MyOwnClass->new());
$MyOwnClass::NAME = 'WrongName';
test_type('MyOwnClass', 0, 'nameIsNotCorrect', 'wrong content', 1, MyOwnClass->new());
test_type('MyOwnClass', 0, 'notAnObject', 'not an instance', 1, 'MyOwnClass');
test_type('MyOwnClass', 0, 'wrongObject', 'wrong instance', 1, MyWrongClass->new());

test_type('int', 1, undef, 'normal', 0, 11934);
test_type('int', 1, undef, 'negative', 0, -11934);
test_type('int', 0, 'noInt', 'decimal', 0, 1.1);

my $overflowing_int = 0;
my $overfloating_int_string = '';
my $i = 1;
while($i++) {
	$overfloating_int_string = '1' x $i;
	$overflowing_int = $overfloating_int_string * 1;
	last if($overflowing_int =~ /[^1]/);
	last if($i > 1_000_000_000);
}
is($overflowing_int =~ /[^1]/, 1, 'found integer overflow');
diag("\nInteger-overflow at: $overflowing_int");

my $overfloating_float = 0;
my $overfloating_float_string = '';
$i = 98;
while($i++) {
	$overfloating_float = '1.2e+' . $i;
	my $result = ($overfloating_float * 1) - $overfloating_float;
	if($result ne '0') {
		diag("Overflow substraction result: $result, Overflow: " . ($overfloating_float * 1));
		$overfloating_float_string = '12' . ('0' x ($i - 1));
		diag("Overflowinf float: $overfloating_float");
		diag("Overflowinf float base length: " . length($overfloating_float_string));
		last; 
	}
	last if($i > 1_000_000_000);
}
my $overfloat_length = $i;
unlike($overfloating_float * 1, qr/1.2/, 'found floatingpoint overflow');
unlike($overfloating_float_string * 1, qr/1\.?2/, 'found floatingpoint overflow string'); 

test_type('int', 0, 'noInt', 'float', 0, $overflowing_int);
test_type('int', 0, 'overflow', 'float as string', 0, $overfloating_int_string);
test_type('int', 0, 'overflow', 'overflowed', 0, $overfloating_float_string);
test_type('int', 0, 'noInt', 'string', 0, 'a1');

test_type('void', 1, undef, 'normal', 0, undef);
test_type('void', 0, undef, 'not void', 0, '');

test_type('scalar', 1, undef, 'normal int', 0, 1);
test_type('scalar', 1, undef, 'normal string', 0, '');
test_type('scalar', 1, undef, 'normal undef', 0, undef);
test_type('scalar', 1, undef, 'reference', 0, \undef);
test_type('scalar', 1, undef, 'array reference', 0, []);

test_type('scalarref', 1, undef, 'normal', 0, \undef);
test_type('scalarref', 0, undef, 'no ref', 0, '');

test_type('arrayref', 1, undef, 'normal', 0, []);
test_type('arrayref', 0, undef, 'no ref', 0, \undef);

test_type('hashref', 1, undef, 'normal', 0, {});
test_type('hashref', 0, undef, 'no ref', 0, []);

test_type('typglobref', 1, undef, 'normal', 0, \*STDIN);
test_type('typglobref', 0, undef, 'no ref', 0, []);

test_type('string', 1, undef, 'normal', 0, 'test');
test_type('string', 1, undef, 'int', 0, 1);
test_type('string', 0, undef, 'undef', 0, undef);
test_type('string', 0, undef, 'array reference', 0, []);

test_type('boolean', 1, undef, 'true', 0, 1);
test_type('boolean', 1, undef, 'false', 0, 0);
test_type('boolean', 0, undef, 'undef', 0, undef);
test_type('boolean', 0, undef, '2', 0, 2);

test_type('float', 1, undef, 'int', 0, 1);
test_type('float', 1, undef, 'decimal', 0, 1.1);
test_type('float', 1, undef, 'float', 0, 1.1e15);
test_type('float', 1, undef, 'float as string', 0, '1.1111111111e99');

test_type('float', 0, 'overflow', 'overflow', 0, $overfloating_float);
test_type('float', 0, 'NaN', 'not a number', 0, '1..1111111111e99999');
test_type('float', 0, undef, 'undef', 0, undef);

test_type('decimal', 1, undef, 'int', 0, 78);
test_type('decimal', 1, undef, 'decimal', 0, 1.1);
test_type('decimal', 1, undef, 'negative decimal', 0, -51.1);
test_type('decimal', 0, 'noDec', 'float', 0, $overflowing_int * 1);
test_type('decimal', 0, 'NaN', 'string', 0, '1a1');
test_type('decimal', 0, 'overflow', 'overflow', 0, $overfloating_float);
test_type('decimal', 0, 'NaN', 'not a number', 0, '1..1111111111e99999');
test_type('decimal', 0, undef, 'undef', 0, undef);
test_type('decimal', 0, 'overflow', 'cutted int', 0, ('1.'. ('0' x $overfloat_length) . '5'));

test_type('class', 1, undef, 'classname', 1, 'MyOwnClass');
test_type('class', 0, undef, 'instance', 1, MyOwnClass->new());
test_type('class', 0, undef, 'no classname', 1, 'MyNonexistingClass');
test_type('class', 0, undef, 'undef', 1, undef);

test_type('object', 0, undef, 'classname', 1, 'MyOwnClass');
test_type('object', 1, undef, 'instance', 1, MyOwnClass->new());
test_type('object', 0, undef, 'no classname', 1, 'MyNonexistingClass');
test_type('object', 0, undef, 'undef', 1, undef);

test_type('MyClass', 1, undef, 'instance', 1, MyClass->new());
test_type('MyClass', 1, undef, 'child', 1, MyOwnClass->new());
test_type('MyClass', 0, undef, 'not a child', 1, MyWrongClass->new());
test_type('MyClass', 0, undef, 'classname', 1, 'MyClass');
test_type('MyClass', 0, undef, 'no classname', 1, 'MyNonexistingClass');
test_type('MyClass', 0, undef, 'undef', 1, undef);
