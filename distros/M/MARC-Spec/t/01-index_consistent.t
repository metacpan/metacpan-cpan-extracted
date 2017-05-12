use Test::More;
use MARC::Spec;
use MARC::Spec::Field;

# new Field
my $field = MARC::Spec::Field->new('650');

# new MARCspec with field
my $ms = MARC::Spec->new($field);

ok $ms->field->index_start == 0, 'index_start default';
ok $ms->field->index_end eq '#', 'index_end default';
ok $ms->field->index_length == -1, 'index_lenght default';
ok $ms->field->to_string() eq '650[0-#]', 'base default';

$field->index_start(0);
$field->index_end(2);

ok $ms->field->index_start == 0, 'index_start 0';
ok $ms->field->index_end == 2, 'index_end 2';
ok $ms->field->index_length == 3, 'index_lenght 3';
ok $ms->field->to_string() eq '650[0-2]', 'base 0-2';


$field->index_end('#');

ok $ms->field->index_length == -1, 'index_lenght -1';
ok $ms->field->to_string() eq '650[0-#]', 'base string 0-#';

$field->index_end(0);
$field->index_start(3);

ok $ms->field->index_end == 3, 'index_end 3';
ok $ms->field->index_length == 1, 'index_lenght 1';

done_testing();