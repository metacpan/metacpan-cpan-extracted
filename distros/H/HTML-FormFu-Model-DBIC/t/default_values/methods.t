use strict;
use warnings;
use Test::More tests => 1;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/default_values/methods.yml');

my $schema = new_schema();

my $rs = $schema->resultset('Master');

# filler row

$rs->create( { text_col => 'filler', } );

{
    my $row = $rs->find(1);

    $form->model->default_values($row);

    my $field = $form->get_element('method_test');

    is( $field->render_data->{value},           "filler" );

}

