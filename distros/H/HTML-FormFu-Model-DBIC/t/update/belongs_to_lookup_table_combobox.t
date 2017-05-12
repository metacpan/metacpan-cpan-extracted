use strict;
use warnings;
use Test::More tests => 6;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/belongs_to_lookup_table_combobox.yml');

my $schema = new_schema();

$form->stash->{schema} = $schema;

my $rs = $schema->resultset('Master');

# filler rows
{
    # insert some entries we'll ignore, so our rels don't have same ids
    $rs->create( { id => 1 } );
    $rs->create( { id => 2 } );

    # types
    my $type_rs  = $schema->resultset('Type');
    $type_rs->delete;
    $type_rs->create( { type => 'type 1' } );
    $type_rs->create( { type => 'type 2' } );
    $type_rs->create( { type => 'type 3' } );
}

# master 3
my $master = $rs->create( { text_col => 'aaa' } );

{
    # submit combobox select ID
    $form->process( {
            "id"          => 3,
            "text_col"    => 'bbb',
            "type_select" => '2',
            "type_text"   => '',
        } );

    $form->model->update($master);

    my $row = $rs->find(3);

    is( $row->text_col, 'bbb');
    is( $row->type->id, 2 );
    is( $row->type->type, 'type 2' );
}

{
    # submit combobox text field
    # will create a new 'type' related row
    $form->process( {
            "id"          => 3,
            "text_col"    => 'ccc',
            "type_select" => '',
            "type_text"   => 'type 4',
        } );

    $form->model->update($master);

    my $row = $rs->find(3);

    is( $row->text_col, 'ccc');
    is( $row->type->id, 4 );
    is( $row->type->type, 'type 4' );
}
