use strict;
use warnings;
use Test::More tests => 3;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/default_values/many_to_many_select.yml');

my $schema = new_schema();

my $master = $schema->resultset('Master')->create({ id => 1 });

# filler

{
    $master->create_related( 'user', { name => 'John', } );

    $master->create_related( 'user', { name => 'Ringo', } );

    my $user3 = $master->create_related( 'user', { name => 'George', } );

    $user3->add_to_bands( { band => 'the kinks', } );
}

# row we're going to use

{
    my $paul = $master->create_related( 'user', { name => 'Paul', } );

    $paul->add_to_bands( { band => 'the beatles', } );

    $paul->add_to_bands( { band => 'wings', } );
}

{
    my $row = $schema->resultset('User')->find(4);

    $form->model->default_values($row);

    is( $form->get_field('id')->default,   4 );
    is( $form->get_field('name')->default, 'Paul' );

    is_deeply( $form->get_field('bands')->default, [ 2, 3 ] );
}

