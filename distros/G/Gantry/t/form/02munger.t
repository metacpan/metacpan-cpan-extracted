use strict;
use Test::More tests => 14;

use Gantry::Utils::FormMunger;

my $munger;
my $form;
my $internal_form;
my $returned_field;
my $field;

#-----------------------------------------------------------------
# from scratch add field
#-----------------------------------------------------------------

$munger = Gantry::Utils::FormMunger->new();

$munger->append_field( { name => 'new_field', label => 'New Field' } );

$internal_form = $munger->{ form };

$form = {
    fields => [
        {
            name => 'new_field',
            label => 'New Field',
        },
    ],
};

is_deeply( $internal_form, $form, 'appending to empty list' );

#-----------------------------------------------------------------
# add at front
#-----------------------------------------------------------------

$munger->unshift_field( { name => 'first_field', label => 'First Field' } );

$internal_form = $munger->{ form };

$form = {
    fields => [
        {
            name => 'first_field',
            label => 'First Field',
        },
        {
            name => 'new_field',
            label => 'New Field',
        },
    ],
};

is_deeply( $internal_form, $form, 'adding at front' );

#-----------------------------------------------------------------
# add after
#-----------------------------------------------------------------

$munger->add_field_after(
        'first_field', { name => 'second_field', label => 'Second Field' }
);

$internal_form = $munger->{ form };

$form = {
    fields => [
        {
            name => 'first_field',
            label => 'First Field',
        },
        {
            name => 'second_field',
            label => 'Second Field',
        },
        {
            name => 'new_field',
            label => 'New Field',
        },
    ],
};

is_deeply( $internal_form, $form, 'add after field' );

#-----------------------------------------------------------------
# add before
#-----------------------------------------------------------------

$munger->add_field_before(
        'new_field', { name => 'third_field', label => 'Third Field' }
);

$internal_form = $munger->{ form };

$form = {
    fields => [
        {
            name => 'first_field',
            label => 'First Field',
        },
        {
            name => 'second_field',
            label => 'Second Field',
        },
        {
            name => 'third_field',
            label => 'Third Field',
        },
        {
            name => 'new_field',
            label => 'New Field',
        },
    ],
};

is_deeply( $internal_form, $form, 'add before field' );

#-----------------------------------------------------------------
# drop field
#-----------------------------------------------------------------

$returned_field = $munger->drop_field( 'third_field' );

$internal_form = $munger->{ form };

$form = {
    fields => [
        {
            name => 'first_field',
            label => 'First Field',
        },
        {
            name => 'second_field',
            label => 'Second Field',
        },
        {
            name => 'new_field',
            label => 'New Field',
        },
    ],
};

is_deeply( $internal_form, $form, 'drop field' );

$field = {
            name => 'third_field',
            label => 'Third Field',
};

is_deeply( $returned_field, $field, 'drop return value' );

#-----------------------------------------------------------------
# get field
#-----------------------------------------------------------------

$returned_field = $munger->get_field( 'second_field' );

$field = {
            name => 'second_field',
            label => 'Second Field',
};

is_deeply( $returned_field, $field, 'get return value' );

#-----------------------------------------------------------------
# clear all props
#-----------------------------------------------------------------

$munger->clear_all_props( 'second_field' );

$field = { name => 'second_field' };

is_deeply( $returned_field, $field, 'cleared all props' );

#-----------------------------------------------------------------
# set some props on one field, not replacing
#-----------------------------------------------------------------

$munger->set_props(
    'second_field',
    { name  => 'second_field',
      label => 'Second Field', }
);

$field = {
            name => 'second_field',
            label => 'Second Field',
};

is_deeply( $returned_field, $field, 'set props - one field' );

#-----------------------------------------------------------------
# set props on all fields, not replacing
#-----------------------------------------------------------------

$munger->set_props_all(
    { type  => 'display', }
);

$internal_form = $munger->{ form };

$form = {
    fields => [
        {
            name => 'first_field',
            label => 'First Field',
            type => 'display',
        },
        {
            name => 'second_field',
            label => 'Second Field',
            type => 'display',
        },
        {
            name => 'new_field',
            label => 'New Field',
            type => 'display',
        },
    ],
};

is_deeply( $internal_form, $form, 'set props - all fields' );

#-----------------------------------------------------------------
# set some props on one field, replacing
#-----------------------------------------------------------------

$munger->set_props(
    'second_field',
    { name  => 'second_field_name',
      label => 'Second Field Name', },
    'replacing',
);

$field = {
            name => 'second_field_name',
            label => 'Second Field Name',
};

is_deeply( $returned_field, $field, 'set props - one field, replacing' );

#-----------------------------------------------------------------
# clear props
#-----------------------------------------------------------------

$munger->append_field(
    { name     => 'last_field',
      label    => 'Last Field',
      raw_html => '<br/>',
      dummy    => 'value', },
);

$munger->clear_props( 'last_field', qw( raw_html dummy ) );

$internal_form = $munger->{ form };

$form = {
    fields => [
        {
            name => 'first_field',
            label => 'First Field',
            type => 'display',
        },
        {
            name => 'second_field_name',
            label => 'Second Field Name',
        },
        {
            name => 'new_field',
            label => 'New Field',
            type => 'display',
        },
        {
            name => 'last_field',
            label    => 'Last Field',
        },
    ],
};

is_deeply( $internal_form, $form, 'clear props' );

#-----------------------------------------------------------------
# set props for multiple fields
#-----------------------------------------------------------------

$munger->set_props_for_fields(
    [ qw( second_field_name last_field ) ],
    { type => 'display_two', foreign => 1 }
);

$internal_form = $munger->{ form };

$form = {
    fields => [
        {
            name => 'first_field',
            label => 'First Field',
            type => 'display',
        },
        {
            name => 'second_field_name',
            label => 'Second Field Name',
            type => 'display_two',
            foreign => 1,
        },
        {
            name => 'new_field',
            label => 'New Field',
            type => 'display',
        },
        {
            name => 'last_field',
            label    => 'Last Field',
            type => 'display_two',
            foreign => 1,
        },
    ],
};

is_deeply( $internal_form, $form, 'set_props_for_fields' );

#-----------------------------------------------------------------
# set props for multiple fields, naming fields skipped
#-----------------------------------------------------------------

$munger->set_props_except_for(
    [ qw( second_field_name last_field ) ],
    { type => 'hidden' }
);

$internal_form = $munger->{ form };

$form = {
    fields => [
        {
            name => 'first_field',
            label => 'First Field',
            type => 'hidden',
        },
        {
            name => 'second_field_name',
            label => 'Second Field Name',
            type => 'display_two',
            foreign => 1,
        },
        {
            name => 'new_field',
            label => 'New Field',
            type => 'hidden',
        },
        {
            name => 'last_field',
            label    => 'Last Field',
            type => 'display_two',
            foreign => 1,
        },
    ],
};

is_deeply( $internal_form, $form, 'set_props_except_for' );

