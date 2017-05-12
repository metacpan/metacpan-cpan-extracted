use strict;
use warnings;
use Test::More tests => 16;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file(
    't/default_values/many_to_many_repeatable_nested.yml');

my $schema = new_schema();

my $master = $schema->resultset('Master')->create({ id => 1 });

# filler

{
    my $user = $master->create_related( 'user', { name => 'filler', } );

    $user->add_to_bands( { band => 'a', } );

    $master->create_related( 'user', { name => 'filler2', } );

    $master->create_related( 'user', { name => 'filler3', } );

    $master->create_related( 'user', { name => 'filler4', } );
}

# row we're going to use

{
    my $user = $master->create_related( 'user', { name => 'nick', } );

    $user->add_to_bands( { band => 'b', } );

    $user->add_to_bands( { band => 'c', } );

    $user->add_to_bands( { band => 'd', } );
}

{
    my $row = $schema->resultset('User')->find(5);

    $form->model->default_values( $row, { nested_base => 'foo' } );

    is( $form->get_field( { nested_name => 'foo.id' } )->default,    '5' );
    is( $form->get_field( { nested_name => 'foo.name' } )->default,  'nick' );
    is( $form->get_field( { nested_name => 'foo.count' } )->default, '3' );

    my $block = $form->get_all_element( { nested_name => 'bands' } );

    my @reps = @{ $block->get_elements };

    is( scalar @reps, 3 );

    is( $reps[0]->get_field('id')->default,   '2' );
    is( $reps[0]->get_field('band')->default, 'b' );

    is( $reps[1]->get_field('id')->default,   '3' );
    is( $reps[1]->get_field('band')->default, 'c' );

    is( $reps[2]->get_field('id')->default,   '4' );
    is( $reps[2]->get_field('band')->default, 'd' );

    # check the same values from the form, not the block

    is( $form->get_field( { nested_name => 'foo.bands_1.id' } )->default, '2' );
    is( $form->get_field( { nested_name => 'foo.bands_1.band' } )->default,
        'b' );

    is( $form->get_field( { nested_name => 'foo.bands_2.id' } )->default, '3' );
    is( $form->get_field( { nested_name => 'foo.bands_2.band' } )->default,
        'c' );

    is( $form->get_field( { nested_name => 'foo.bands_3.id' } )->default, '4' );
    is( $form->get_field( { nested_name => 'foo.bands_3.band' } )->default,
        'd' );
}

