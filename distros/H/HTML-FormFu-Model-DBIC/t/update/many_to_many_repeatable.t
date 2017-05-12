use strict;
use warnings;
use Test::More tests => 9;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/many_to_many_repeatable.yml');

my $schema = new_schema();

my $master = $schema->resultset('Master')-> create({ id => 1 });

# filler rows
{
    # user 1
    my $u1 = $master->create_related( 'user', { name => 'foo' } );

    # band 1
    $u1->add_to_bands({ band => 'a' });
}

# rows we're going to use
{
    # user 2
    my $u2 = $master->create_related( 'user', { name => 'nick', } );

    # band 2,3,4
    $u2->add_to_bands({ band => 'b' });
    $u2->add_to_bands({ band => 'c' });
    $u2->add_to_bands({ band => 'd' });
}

{
    $form->process( {
            'id'           => 2,
            'name'         => 'new nick',
            'count'        => 2,
            'bands_1.id'   => 2,
            'bands_1.band' => 'b++',
            'bands_2.id'   => 3,
            'bands_2.band' => 'c++',
        } );

    ok( $form->submitted_and_valid );

    my $row = $schema->resultset('User')->find(2);

    $form->model->update($row);
}

{
    my $user = $schema->resultset('User')->find(2);

    is( $user->name, 'new nick' );

    my @add = $user->bands->all;

    is( scalar @add, 3 );

    is( $add[0]->id,   2 );
    is( $add[0]->band, 'b++' );

    is( $add[1]->id,   3 );
    is( $add[1]->band, 'c++' );

    # band 4 should be unchanged

    is( $add[2]->id,   4 );
    is( $add[2]->band, 'd' );
}

