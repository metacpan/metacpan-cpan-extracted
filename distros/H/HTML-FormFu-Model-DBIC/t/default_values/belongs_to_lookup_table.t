use strict;
use warnings;
use Test::More tests => 2;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/default_values/belongs_to_lookup_table.yml');

my $schema = new_schema();

my $rs = $schema->resultset('Master');

# filler row

$rs->create( { text_col => 'filler', } );

# row we're going to use

$rs->create( {
        text_col => 'a',
        type_id  => 3,
    } );

{
    my $row = $rs->find(2);

    $form->model->default_values($row);

    is( $form->get_field('id')->default, 2 );

    is( $form->get_field('type_id')->default, 3 );
}

