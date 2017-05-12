use Test::More;
use strict;
use warnings;

use Test::Exception;

BEGIN {
    use_ok('HTML::FormBuilder');
    use_ok('HTML::FormBuilder::FieldSet');
}

my $form = HTML::FormBuilder->new(data => {id => 'testid'});
my $fieldset = $form->add_fieldset({});
isa_ok($fieldset, 'HTML::FormBuilder::FieldSet');
my $field;
lives_ok(
    sub {
        $field = $fieldset->add_field({input => {name => "input1"}});
    },
    'add field ok'
);
is_deeply($fieldset->{fields}[0], $field, 'field is correct');
isa_ok($field, 'HTML::FormBuilder::Field', 'field is a Field');
my $num;
lives_ok(
    sub {
        $num = $fieldset->add_fields({input => {name => "input2"}}, {input => {name => "input3"}});
    },
    'add fields ok'
);

is($num, 2, 'add_fields return number of fields added');
my $fields = $fieldset->fields;
is_deeply([map { $_->data->{input}[0]{name} } @$fields], [qw(input1 input2 input3)], 'the fields are ok');
done_testing;
