use strict;
use warnings;
use Test::More tests => 16;
use MARC::Field;

my $field = MARC::Field->new('245', '0', '1', a=>'foo', b=>'bar', a=>'baz');
$field->delete_subfield(code => 'a');
is $field->as_string, 'bar', 'delete by subfield code';

$field = MARC::Field->new('245', '0', '1', a=>'foo', b=>'bar', a=>'baz');
$field->delete_subfield(code => qr/[^a]/);
is $field->as_string(), 'foo baz', 'delete by regex on subfield code';

$field = MARC::Field->new('245', '0', '1', a=>'foo', b=>'bar', c=>'baz');
$field->delete_subfield(code => ['a','c']);
is $field->as_string, 'bar', 'delete by multiple subfield codes';

$field = MARC::Field->new('245', '0', '1', a=>'foo', b=>'bar', a=>'baz');
$field->delete_subfield(pos => 0);
is $field->as_string, 'bar baz', 'delete by pos';

$field = MARC::Field->new('245', '0', '1', a=>'foo', b=>'bar', a=>'baz');
$field->delete_subfield(pos => [0,2]);
is $field->as_string, 'bar', 'delete by multiple pos';

$field = MARC::Field->new('245', '0', '1', a=>'foo', b=>'bar', a=>'baz');
$field->delete_subfield(code => 'a', pos => [0,2]);
is $field->as_string, 'bar', 'delete by multiple pos with code';

$field = MARC::Field->new('245', '0', '1', a=>'foo', b=>'bar', a=>'baz');
$field->delete_subfield(code => 'b', pos => [0,2]);
is $field->as_string, 'foo bar baz', 'delete by multiple pos with wrong code';

$field = MARC::Field->new('245', '0', '1', a=>'foo', b=>'bar', a=>'baz');
$field->delete_subfield(code => 'a', match => qr/baz/);
is $field->as_string, 'foo bar', 'delete all subfield a that match /baz/';

$field = MARC::Field->new('245', '0', '1', z => 'quux baz', a=>'foo', b=>'bar', a=>'baz');
$field->delete_subfield(match => qr/baz/);
is $field->as_string, 'foo bar', 'delete all subfields that match /baz/';

$field = MARC::Field->new('245', '0', '1', a=>'foo', b=>'bar', a=>'baz');
$field->delete_subfield(code => 'a', match => qr/bar/);
is $field->as_string, 'foo bar baz', 'do not delete wrong subfield match';

eval { $field->delete_subfield(match => 'uhoh'); };
like $@, qr/match must be a compiled regex/, 'exception if match is not regex'; 


$field = MARC::Field->new('245', '0', '1', a=>'foo', b=>'bar', a=>'baz');
$field->delete_subfields('a');
is $field->as_string, 'bar', 'backwards compat with delete_subfields()';

$field = MARC::Field->new('245', '0', '1', a=>'foo', b=>'bar');
$field->delete_subfield('a');
is $field->as_string, 'bar', q(RT#70346: calling delete_subfield('a') should DWIM, not clear entire field);

eval {
   $field->delete_subfield('a', 'b', 'c');
};
like $@, qr/delete_subfield must be called with single scalar or a hash/, 'exception if called with args that are neither single scalar or hash';

eval {
   $field->delete_subfield();
};
like $@, qr!must supply subfield code\(s\) and/or subfield position\(s\) and/or match patterns to delete_subfield!, 'exception if called no args';
eval {
   $field->delete_subfield(garbage => '123');
};
like $@, qr!must supply subfield code\(s\) and/or subfield position\(s\) and/or match patterns to delete_subfield!, 'exception if called unrecognized args';
