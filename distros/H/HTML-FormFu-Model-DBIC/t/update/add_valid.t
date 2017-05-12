use strict;
use warnings;
use Test::More tests => 7;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/basic.yml');

my $schema = new_schema();

my $rs = $schema->resultset('Master');

# Fake submitted form
$form->process( {
        id             => 1,
        text_col       => 'a',
        password_col   => 'b',
        checkbox_col   => 'foo',
        select_col     => '2',
        radio_col      => 'yes',
        radiogroup_col => '3',
    } );

{
    $form->add_valid( 'not_in_form', 'xyz' );

    my $row = $rs->new( {} );

    $form->model->update($row);
}

{
    my $row = $rs->find(1);

    is( $row->text_col,       'a' );
    is( $row->password_col,   'b' );
    is( $row->checkbox_col,   'foo' );
    is( $row->select_col,     '2' );
    is( $row->radio_col,      'yes' );
    is( $row->radiogroup_col, '3' );
    is( $row->not_in_form,    'xyz' );
}

