use strict;
use warnings;
use Test::More tests => 22;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/default_values/many_to_many-has_many.yml');

my $schema = new_schema();

my $master = $schema->resultset('Master')->create({ id => 1 });

# filler rows

{
    # user 1
    my $user = $master->create_related( 'user', { name => 'filler', } );

    # band 1
    $user->add_to_bands( { band => 'a', } );

    # address 1
    $user->add_to_addresses( { address => 'b' } );

    # user 2,3,4
    $master->create_related( 'user', { name => 'filler2', } );
    $master->create_related( 'user', { name => 'filler3', } );
    $master->create_related( 'user', { name => 'filler4', } );
}

# rows we're going to use

{
    # band 2
    my $band = $schema->resultset('Band')->create({ band => 'band 2' });

    # user 5,6
    my $user1 = $band->add_to_users({ name => 'user 5', master => $master->id });
    my $user2 = $band->add_to_users({ name => 'user 6', master => $master->id });

    # address 2,3
    $user1->create_related( 'addresses', { address => 'add 2' } );
    $user1->create_related( 'addresses', { address => 'add 3' } );

    # address 4
    $user2->create_related( 'addresses', { address => 'add 4' } );
}

{
    my $row = $schema->resultset('Band')->find(2);

    $form->model->default_values($row);

    is( $form->get_field('band')->default,  'band 2' );
    is( $form->get_field('count')->default, '2' );

    my $user_repeatable = $form->get_all_element( { nested_name => 'users' } );

    my @users = @{ $user_repeatable->get_elements };

    is( scalar @users, 2 );

    # user 5
    {
        is( $users[0]->nested_name,                'users_1' );
        is( $users[0]->get_field('id')->default,   '5' );
        is( $users[0]->get_field('name')->default, 'user 5' );

        is( $users[0]->get_field('count')->default, '2' );

        my $addresses_repeatable = $users[0]->get_all_element({ nested_name => 'addresses' });

        my @addresses = @{ $addresses_repeatable->get_elements };

        is( scalar @addresses, 2 );

        # address 2
        is( $addresses[0]->nested_name,                   'addresses_1' );
        is( $addresses[0]->get_field('id')->default,      '2' );
        is( $addresses[0]->get_field('address')->default, 'add 2' );

        # address 3
        is( $addresses[1]->nested_name,                   'addresses_2' );
        is( $addresses[1]->get_field('id')->default,      '3' );
        is( $addresses[1]->get_field('address')->default, 'add 3' );
    }

    # user 6
    {
        is( $users[1]->nested_name,                'users_2' );
        is( $users[1]->get_field('id')->default,   '6' );
        is( $users[1]->get_field('name')->default, 'user 6' );

        is( $users[1]->get_field('count')->default, '1' );

        my $addresses_repeatable = $users[1]->get_all_element({ nested_name => 'addresses' });

        my @addresses = @{ $addresses_repeatable->get_elements };

        is( scalar @addresses, 1 );

        # address 4
        is( $addresses[0]->nested_name,                       'addresses_1' );
        is( $addresses[0]->get_field('id')->default,      '4' );
        is( $addresses[0]->get_field('address')->default, 'add 4' );
    }
}
