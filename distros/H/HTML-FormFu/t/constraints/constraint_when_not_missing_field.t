use strict;
use warnings;

use Test::More tests => 15;

use HTML::FormFu;

my $form = HTML::FormFu->new;

$form->load_config_file('t/constraints/constraint_when_not_missing_field.yml');

# field + not

# invalid - checkbox unchecked (missing) - fieldname required
{
    $form->process( { fieldname => '' } );

    ok( !$form->submitted_and_valid, 'field+not: unchecked, empty' );
    ok( !$form->valid('fieldname'),  'fieldname not valid' );
}

# valid - checkbox unchecked (missing) - fieldname supplied
{
    $form->process( { fieldname => 'x' } );

    ok( $form->valid('fieldname'), 'field+not: unchecked, supplied' );
}

# valid - checkbox checked - fieldname optional
{
    $form->process( { fieldname => '', some_checkbox => 'it_is_checked' } );

    ok( $form->valid('fieldname'), 'field+not: checked, empty' );
}

# fields + not

# invalid - both missing - baz required
{
    $form->process( { baz => '' } );

    ok( !$form->valid('baz'), 'fields+not: both missing' );
}

# valid - one checked - condition not fulfilled
{
    $form->process( { baz => '', c1 => 1 } );

    ok( $form->valid('baz'), 'fields+not: one checked' );
}

# valid - both checked
{
    $form->process( { baz => '', c1 => 1, c2 => 1 } );

    ok( $form->valid('baz'), 'fields+not: both checked' );
}

# any_field + not

# invalid - both missing - quux required
{
    $form->process( { quux => '' } );

    ok( !$form->valid('quux'), 'any_field+not: both missing' );
}

# invalid - one missing - quux required
{
    $form->process( { quux => '', d1 => 1 } );

    ok( !$form->valid('quux'), 'any_field+not: one missing' );
}

# valid - both checked
{
    $form->process( { quux => '', d1 => 1, d2 => 1 } );

    ok( $form->valid('quux'), 'any_field+not: both checked' );
}

# fields without not

# valid - both missing - qux optional
{
    $form->process( { qux => '' } );

    ok( $form->valid('qux'), 'fields: both missing' );
}

# valid - one missing - qux optional
{
    $form->process( { qux => '', e1 => 1 } );

    ok( $form->valid('qux'), 'fields: one missing' );
}

# invalid - both checked - qux required
{
    $form->process( { qux => '', e1 => 1, e2 => 1 } );

    ok( !$form->valid('qux'), 'fields: both checked' );
}

# valid - both checked and qux supplied
{
    $form->process( { qux => 'x', e1 => 1, e2 => 1 } );

    ok( $form->valid('qux'), 'fields: both checked, supplied' );
}

# an unrelated field with no when is unaffected
{
    $form->process( { fieldname => 'x', baz => 'x', quux => 'x' } );

    ok( $form->submitted_and_valid, 'everything supplied' );
}
