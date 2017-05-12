use strict;
use warnings;
use Test::More tests => 34;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/options_from_model/has_many_repeatable_select.yml');

my $schema = new_schema();

$form->stash( { schema => $schema } );

my $master = $schema->resultset('Master')->create({ id => 1 });

# filler rows
{
    # user 1, 2
    $master->create_related( 'user', { name => 'user 1' } );
    $master->create_related( 'user', { name => 'user 2' } );
}

# rows we're going to use
{
    # manager 1
    my $manager = $schema->resultset('Manager')->create({ name => 'manager 1' });

    # band 1, 2
    my $band1 = $manager->create_related( 'bands', { band => 'band 1' } );
    my $band2 = $manager->create_related( 'bands', { band => 'band 2' } );

    # user 3, 4
    $band1->add_to_users({ name => 'user 3', master => $manager->id });
    $band1->add_to_users({ name => 'user 4', master => $manager->id });

    # user 5
    $band2->add_to_users({ name => 'user 5', master => $manager->id });
}

{
    $form->process;

    my $manager = $schema->resultset('Manager')->find(1);

    $form->model->default_values( $manager );

    is( $form->get_field('id')->default,    '1' );
    is( $form->get_field('name')->default,  'manager 1' );
    is( $form->get_field('count')->default, '2' );

    my $bands_repeatable = $form->get_all_element({ nested_name => 'bands' });

    my @bands = @{ $bands_repeatable->get_elements };

    is( scalar @bands, 2 );

    # band 1
    {
        is( $bands[0]->nested_name,                'bands_1' );
        is( $bands[0]->get_field('id')->default,   '1' );
        is( $bands[0]->get_field('band')->default, 'band 1' );

        # user 3
        my $select = $bands[0]->get_field('users');

        is_deeply( $select->default, [3, 4] );

        is( scalar @{ $select->options }, 5 );

        is( $select->options->[0]->{value}, '1' );
        is( $select->options->[0]->{label}, 'user 1' );
        is( $select->options->[1]->{value}, '2' );
        is( $select->options->[1]->{label}, 'user 2' );
        is( $select->options->[2]->{value}, '3' );
        is( $select->options->[2]->{label}, 'user 3' );
        is( $select->options->[3]->{value}, '4' );
        is( $select->options->[3]->{label}, 'user 4' );
        is( $select->options->[4]->{value}, '5' );
        is( $select->options->[4]->{label}, 'user 5' );
    }

    # band 2
    {
        is( $bands[1]->nested_name,                'bands_2' );
        is( $bands[1]->get_field('id')->default,   '2' );
        is( $bands[1]->get_field('band')->default, 'band 2' );

        # user 3
        my $select = $bands[1]->get_field('users');

        is_deeply( $select->default, [5] );

        is( scalar @{ $select->options }, 5 );

        is( $select->options->[0]->{value}, '1' );
        is( $select->options->[0]->{label}, 'user 1' );
        is( $select->options->[1]->{value}, '2' );
        is( $select->options->[1]->{label}, 'user 2' );
        is( $select->options->[2]->{value}, '3' );
        is( $select->options->[2]->{label}, 'user 3' );
        is( $select->options->[3]->{value}, '4' );
        is( $select->options->[3]->{label}, 'user 4' );
        is( $select->options->[4]->{value}, '5' );
        is( $select->options->[4]->{label}, 'user 5' );
    }
}
