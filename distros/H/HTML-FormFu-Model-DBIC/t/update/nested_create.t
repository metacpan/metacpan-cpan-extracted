use strict;
use warnings;
use Test::More tests => 7;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/nested.yml');

my $schema = new_schema();

my $rs = $schema->resultset('Master');

# Fake submitted form
$form->process( {
        "foo.id"                  => 1,
        "foo.text_col"            => 'a',
        "foo.password_col"        => 'b',
        "foo.checkbox_col"        => 'foo',
        "foo.select_col"          => '2',
        "foo.combobox_col_select" => "",
        "foo.combobox_col_text"   => "combo",
        "foo.radio_col"           => 'yes',
        "foo.radiogroup_col"      => '3',
    } );

{
    my $row = $rs->new( {} );

    $form->model->update( $row, { nested_base => 'foo' } );
}

{
    my $row = $rs->find(1);

    is( $row->text_col,       'a' );
    is( $row->password_col,   'b' );
    is( $row->checkbox_col,   'foo' );
    is( $row->select_col,     '2' );
    is( $row->combobox_col,   'combo' );
    is( $row->radio_col,      'yes' );
    is( $row->radiogroup_col, '3' )
}

