use strict;
use warnings;
use Test::More tests => 3;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/default_values/belongs_to_lookup_table_combobox.yml');

my $schema = new_schema();

$form->stash->{schema} = $schema;

my $rs = $schema->resultset('Master');

{
    my $type_rs  = $schema->resultset('Type');

    # types
    $type_rs->delete;
    $type_rs->create( { type => 'type 1' } );
    $type_rs->create( { type => 'type 2' } );
    $type_rs->create( { type => 'type 3' } );
}

# filler row

$rs->create( { text_col => 'filler', } );

# row we're going to use

$rs->create( {
        text_col => 'a',
        type_id  => 3,
    } );

{
    my $row = $rs->find(2);

    $form->process;

    $form->model->default_values($row);

    is( $form->get_field('id')->default, 2 );

    my $type_field = $form->get_field('type');

    is( $type_field->default, 3 );

    # test correct select option is selected

    like( "$type_field", qr{<option value="3" selected="selected">type 3</option>} );
}
