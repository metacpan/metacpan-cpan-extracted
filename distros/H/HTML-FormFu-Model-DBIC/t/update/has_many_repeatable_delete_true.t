use strict;
use warnings;
use Test::More tests => 5;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/has_many_repeatable_delete_true.yml');

my $schema = new_schema();

my $master = $schema->resultset('Master')->create({ id => 1 });

# filler rows
{
    # user 1
    my $u1 = $master->create_related( 'user', { name => 'foo' } );

    # address 1
    $u1->create_related( 'addresses' => { address => 'somewhere' } );
}

{
    # user 2
    my $u2 = $master->create_related( 'user', { name => 'nick', } );

    # adresses 2,3,4
    $u2->create_related( 'addresses', { address => 'home' } );
    $u2->create_related( 'addresses', { address => 'office' } );
    $u2->create_related( 'addresses', { address => 'temp' } );
}

{
    # changing address 2 and deleting address 3+4
    $form->process( {
            'id'                  => 2,
            'name'                => 'new nick',
            'count'               => 3,
            'addresses_1.id'      => 2,
            'addresses_1.address' => 'new home',
            'addresses_1.delete'  => 1,
            'addresses_2.id'      => 3,
            'addresses_2.address' => 'new office',
            'addresses_3.id'      => 4,
            'addresses_3.address' => 'new office',
            'addresses_3.delete'  => 1,
         } );

    ok( $form->submitted_and_valid );

    my $row = $schema->resultset('User')->find(2);

    $form->model->update($row);
}

{
    my $user = $schema->resultset('User')->find(2);

    is( $user->name, 'new nick' );

    my @add = $user->addresses->all;

    is( scalar @add, 1 );

    is( $add[0]->id,      3 );
    is( $add[0]->address, 'new office' );
}

