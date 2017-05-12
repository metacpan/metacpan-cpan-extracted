use strict;
use warnings;
use Test::More tests => 9;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/basic.yml');

my $schema = new_schema();

my $rs = $schema->resultset('Master');

{
    my $row = $rs->new_result( {
            text_col       => 'xyza',
            password_col   => 'xyzb',
            checkbox_col   => 'xyzfoo',
            select_col     => 'xyz2',
            combobox_col   => 'combo',
            radio_col      => 'xyzyes',
            radiogroup_col => 'xyz3',
            array_col      => [qw(abc xyz)],
        } );

    $row->insert;
}

# Fake submitted form
$form->process( {
        id                  => 1,
        text_col            => 'a',
        password_col        => 'b',
        checkbox_col        => 'foo',
        select_col          => '2',
        combobox_col_select => '',
        combobox_col_text   => 'txt',
        radio_col           => 'yes',
        radiogroup_col      => '3',
        array_col           => [qw(one two)],
    } );

{
    my $row = $rs->find(1);

    $form->model->update($row);
}

{
    my $row = $rs->find(1);

    is( $row->text_col,       'a' );
    is( $row->password_col,   'b' );
    is( $row->checkbox_col,   'foo' );
    is( $row->combobox_col,   'txt' );
    is( $row->select_col,     '2' );
    is( $row->radio_col,      'yes' );
    is( $row->radiogroup_col, '3' );
    is( ($row->array_col)->[0], 'one' );
    is( ($row->array_col)->[1], 'two' );
}

