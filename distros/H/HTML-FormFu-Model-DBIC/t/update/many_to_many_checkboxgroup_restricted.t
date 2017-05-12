use strict;
use warnings;
use Test::More tests => 5;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use HTMLFormFu::MockContext;
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/many_to_many_checkboxgroup_restricted.yml');

my $schema = new_schema();

my $context = HTMLFormFu::MockContext->new( {
    model => $schema->resultset('Band'),
} );

$form->stash( { context => $context } );

my $master = $schema->resultset('Master')->create({ id => 1 });

my $band1;

# filler rows
{
    # user 1
    my $u1 = $master->create_related( 'user', { name => 'John' } );

    # band 1
    $band1 = $u1->add_to_bands( { band => 'the beatles', manager => 1 } );
}

# rows we're going to use
{
    # user 2
    my $u2 = $master->create_related( 'user', { name => 'Paul' } );

    $u2->add_to_bands($band1);

    # band 2
    $schema->resultset('Band')->create( { band => 'wings', manager => 1 } );

    # band 3
    $u2->add_to_bands( { band => 'the kinks', manager => 2 } );
}

# currently,
# user [2] => bands [3, 1]

{
    $form->process( {
            id    => 2,
            name  => 'Paul McCartney',
            bands => [ 1 ],
        } );

    ok( $form->submitted_and_valid );

    my $row = $schema->resultset('User')->find(2);

    $form->model->update($row);
}

{
    my $row = $schema->resultset('User')->find(2);

    is( $row->name, 'Paul McCartney' );

    my @bands = $row->bands->all;

    is( scalar @bands, 2 );

    my @id = sort map { $_->id } @bands;

    is( $id[0], 1 );
    is( $id[1], 3 );	# 3 should not have been touched
}

