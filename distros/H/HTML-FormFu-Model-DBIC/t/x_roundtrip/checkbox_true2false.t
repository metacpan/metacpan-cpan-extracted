use strict;
use warnings;
use Test::More tests => 3;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $config_file = 't/x_roundtrip/checkbox.yml';

my $schema = new_schema();

my $rs = $schema->resultset('Master');

# filler row

$rs->create( { text_col => 'filler', } );

# row we're going to use
# column value starts off true

$rs->create( {
        checkbox_col => 1,
    } );

# default_values()

{
    my $form = HTML::FormFu->new;

    $form->load_config_file( $config_file );

    my $row = $rs->find(2);

    $form->model->default_values($row);

    # check field value

    my $checkbox = $form->get_field('checkbox_col');

    is( $checkbox->default, '1' );

    my $expected_xhtml = q{<input name="checkbox_col" type="checkbox" value="1" checked="checked" />};

    like( "$checkbox", qr/\Q$expected_xhtml\E/ );
}

# update()
# value isn't submitted, so it becomes false

{
    my $form = HTML::FormFu->new;

    $form->load_config_file( $config_file );

    $form->process({
        id => 2,
    });

    my $row = $rs->find(2);

    $form->model->update($row);

    # check database

    is( $row->checkbox_col, '0' );
}

