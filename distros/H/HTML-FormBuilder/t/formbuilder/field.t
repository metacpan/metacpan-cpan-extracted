use Test::More;
use strict;
use warnings;

use Test::Exception;

BEGIN {
    use_ok('HTML::FormBuilder');
    use_ok('HTML::FormBuilder::FieldSet');
    use_ok('HTML::FormBuilder::Field');
}

my $form = HTML::FormBuilder->new(data => {id => 'testid'});
my $fieldset = $form->add_fieldset({});
my $field;
lives_ok(
    sub {
        $field = $fieldset->add_field({input => {trailing => "This is trailling"}});
    },
    'add field ok'
);
is($field->{data}{input}[0]{trailing}, 'This is trailling');
isa_ok($field, 'HTML::FormBuilder::Field');
done_testing;
