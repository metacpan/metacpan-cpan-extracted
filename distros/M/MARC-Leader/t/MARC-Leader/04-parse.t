use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use MARC::Leader;
use Test::More 'tests' => 56;
use Test::NoWarnings;
use Test::Output;

# Test.
my $obj = MARC::Leader->new;
my $ret = $obj->parse('02200cem a2200541 i 4500');
diag('Leader: 02200cem a2200541 i 4500');
is($ret->length, 2200, 'Get length (2200).');
is($ret->status, 'c', 'Get status (c).');
is($ret->type, 'e', 'Get type (e).');
is($ret->bibliographic_level, 'm', 'Get bibliographic level (m).');
is($ret->type_of_control, ' ', 'Get type of control ( ).');
is($ret->char_coding_scheme, 'a', 'Get character coding scheme (a).');
is($ret->indicator_count, '2', 'Get indicator count (2).');
is($ret->subfield_code_count, '2', 'Get subfield code count (2).');
is($ret->data_base_addr, 541, 'Get data base address (541).');
is($ret->encoding_level, ' ', 'Get encoding level ( ).');
is($ret->descriptive_cataloging_form, 'i', 'Get descriptive cataloging form (i).');
is($ret->multipart_resource_record_level, ' ', 'Get multipart resource record level ( ).');
is($ret->length_of_field_portion_len, '4', 'Get length of the length-of-field portion (4).');
is($ret->starting_char_pos_portion_len, '5', 'Get length of the starting-character-position portion (5).');
is($ret->impl_def_portion_len, '0', 'Get length of the implementation-defined portion (0).');
is($ret->undefined, '0', 'Get undefined (0).');

# Test.
$obj = MARC::Leader->new;
$ret = $obj->parse('     nam a22        4500');
diag('Leader:      nam a22        4500');
is($ret->length, 0, 'Get length (0).');
is($ret->status, 'n', 'Get status (n).');
is($ret->type, 'a', 'Get type (a).');
is($ret->bibliographic_level, 'm', 'Get bibliographic level (m).');
is($ret->type_of_control, ' ', 'Get type of control ( ).');
is($ret->char_coding_scheme, 'a', 'Get character coding scheme (a).');
is($ret->indicator_count, '2', 'Get indicator count (2).');
is($ret->subfield_code_count, '2', 'Get subfield code count (2).');
is($ret->data_base_addr, 0, 'Get data base address (0).');
is($ret->encoding_level, ' ', 'Get encoding level ( ).');
is($ret->descriptive_cataloging_form, ' ', 'Get descriptive cataloging form ( ).');
is($ret->multipart_resource_record_level, ' ', 'Get multipart resource record level ( ).');
is($ret->length_of_field_portion_len, '4', 'Get length of the length-of-field portion (4).');
is($ret->starting_char_pos_portion_len, '5', 'Get length of the starting-character-position portion (5).');
is($ret->impl_def_portion_len, '0', 'Get length of the implementation-defined portion (0).');
is($ret->undefined, '0', 'Get undefined (0).');

# Test.
$obj = MARC::Leader->new;
$ret = $obj->parse('-----nam-a22------ia4500');
diag('Leader:      nam a22        4500');
is($ret->length, 0, 'Get length (0).');
is($ret->status, 'n', 'Get status (n).');
is($ret->type, 'a', 'Get type (a).');
is($ret->bibliographic_level, 'm', 'Get bibliographic level (m).');
is($ret->type_of_control, ' ', 'Get type of control ( ).');
is($ret->char_coding_scheme, 'a', 'Get character coding scheme (a).');
is($ret->indicator_count, '2', 'Get indicator count (2).');
is($ret->subfield_code_count, '2', 'Get subfield code count (2).');
is($ret->data_base_addr, 0, 'Get data base address (0).');
is($ret->encoding_level, ' ', 'Get encoding level ( ).');
is($ret->descriptive_cataloging_form, 'i', 'Get descriptive cataloging form ( ).');
is($ret->multipart_resource_record_level, 'a', 'Get multipart resource record level ( ).');
is($ret->length_of_field_portion_len, '4', 'Get length of the length-of-field portion (4).');
is($ret->starting_char_pos_portion_len, '5', 'Get length of the starting-character-position portion (5).');
is($ret->impl_def_portion_len, '0', 'Get length of the implementation-defined portion (0).');
is($ret->undefined, '0', 'Get undefined (0).');

# Test.
$obj = MARC::Leader->new(
	'verbose' => 1,
);
my $right_ret = "Leader: |     nam a22      ia4500|\n";
stdout_is(
	sub {
		$ret = $obj->parse('-----nam-a22------ia4500');
	},
	$right_ret,
	'Verbose output.',
);
isa_ok($ret, 'Data::MARC::Leader');

# Test.
$obj = MARC::Leader->new;
eval {
	$obj->parse('foo');
};
is($EVAL_ERROR, "Bad length of MARC leader.\n", 'Bad length of MARC leader.');
clean();

# Test.
$obj = MARC::Leader->new;
eval {
	$obj->parse('x1981nam a2200517 i 4500');
};
is($EVAL_ERROR, "Bad number in length.\n", 'Bad number in length (x1981).');
my $err_hr = err_msg_hr();
is($err_hr->{'String'}, 'x1981', 'Get bad string (x1981).');
clean();

# Test.
$obj = MARC::Leader->new;
eval {
	$obj->parse('01981nam a22x0517 i 4500');
};
is($EVAL_ERROR, "Bad number in data base address.\n", 'Bad number in data base address (x0517).');
$err_hr = err_msg_hr();
is($err_hr->{'String'}, 'x0517', 'Get bad string (x0517).');
clean();
