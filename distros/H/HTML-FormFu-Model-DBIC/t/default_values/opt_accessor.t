use strict;
use warnings;
use Test::More tests => 2;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/default_values/opt_accessor.yml');

my $schema = new_schema();

my $master = $schema->resultset('Master')->create({ id => 1 });

# filler row

$master->create_related( 'user', { name => 'foo', } );

# row we're going to use

$master->create_related( 'user', {
        title => 'mr',
        name  => 'billy bob',
    } );

{
    my $row = $schema->resultset('User')->find(2);

    $form->model->default_values($row);

    my $fs = $form->get_element;

    is( $fs->get_field('id')->render_data->{value},       2 );
    is( $fs->get_field('fullname')->render_data->{value}, 'mr billy bob' );
}

