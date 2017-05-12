use Test::More;
use MARC::Spec;
use MARC::Spec::Field;

# new Field
my $field = MARC::Spec::Field->new('650');

# new MARCspec with field
my $ms = MARC::Spec->new($field);

$field->char_start(0);

ok $ms->field->char_start == 0, 'char_start 0';
ok $ms->field->char_end eq 0, 'char_end 0';
ok $ms->field->char_length == 1, 'char_lenght -1';
ok $ms->field->to_string() eq '650[0-#]/0', 'base default got '.$ms->field->to_string();

$field->char_end(2);

ok $ms->field->char_start == 0, 'char_start 0';
ok $ms->field->char_end == 2, 'char_end 2';
ok $ms->field->char_length == 3, 'char_lenght 3';
ok $ms->field->to_string() eq '650[0-#]/0-2', 'base 0-2';


$field->char_end('#');

ok $ms->field->char_length == -1, 'char_lenght -1';
ok $ms->field->to_string() eq '650[0-#]', 'base string 0-#';

done_testing();