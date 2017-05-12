use strict;
use warnings;
use Test::More tests => 15;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/default_values/many_to_many-has_many.yml');

my $schema = new_schema();

my $master = $schema->resultset('Master')->create( { id => 1 } );

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
    my $band = $schema->resultset('Band')->create( { band => 'band 2' } );

    # user 5,6
    my $user1
        = $band->add_to_users( { name => 'user 5', master => $master->id } );
    my $user2
        = $band->add_to_users( { name => 'user 6', master => $master->id } );

    # address 2,3
    $user1->create_related( 'addresses', { address => 'add 2' } );
    $user1->create_related( 'addresses', { address => 'add 3' } );

    # address 4
    $user2->create_related( 'addresses', { address => 'add 4' } );
}

{
    $form->process( {
            'band'                        => 'band 2 edit',
            'count'                       => 2,
            'users_1.id'                  => 5,
            'users_1.name'                => 'user 5 edit',
            'users_1.count'               => 2,
            'users_1.addresses_1.id'      => 2,
            'users_1.addresses_1.address' => 'add 2 edit',
            'users_1.addresses_2.id'      => 3,
            'users_1.addresses_2.address' => 'add 3 edit',
            'users_2.id'                  => 6,
            'users_2.name'                => 'user 6 edit',
            'users_2.count'               => 1,
            'users_2.addresses_1.id'      => 4,
            'users_2.addresses_1.address' => 'add 4 edit',
            'submit'                      => 'Submit',
        } );

    ok( $form->submitted_and_valid );

    my $row = $schema->resultset('Band')->find(2);

    $form->model->update($row);
}

{
    my $band = $schema->resultset('Band')->find(2);

    is( $band->band, 'band 2 edit' );

    my @user = $band->users->all;

    is( scalar @user, 2 );

    # user 5
    {
        is( $user[0]->id,   5 );
        is( $user[0]->name, 'user 5 edit' );

        my @address = $user[0]->addresses->all;

        is( scalar @address, 2 );

        # address 2
        is( $address[0]->id,      2 );
        is( $address[0]->address, 'add 2 edit' );

        # address 3
        is( $address[1]->id,      3 );
        is( $address[1]->address, 'add 3 edit' );
    }

    # user 6
    {
        is( $user[1]->id,   6 );
        is( $user[1]->name, 'user 6 edit' );

        my @address = $user[1]->addresses->all;

        is( scalar @address, 1 );

        # address 3
        is( $address[0]->id,      4 );
        is( $address[0]->address, 'add 4 edit' );
    }
}

