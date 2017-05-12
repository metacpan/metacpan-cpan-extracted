use strict;
use warnings;
use Test::More tests => 3;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/many_to_many_checkboxgroup.yml');

my $schema = new_schema();

my $master = $schema->resultset('Master')-> create({ id => 1 });

my $band1;

# filler rows
{
    # user 1
    my $u1 = $master->create_related( 'user', { name => 'John' } );

    # band 1
    $band1 = $u1->add_to_bands({ band => 'the beatles' });
}

# rows we're going to use
{
    # user 2
    my $u2 = $master->create_related( 'user', { name => 'Paul', } );

    # band 2
    $u2->add_to_bands({ band => 'wings' });

    # band 3 - not used
    $schema->resultset('Band')->create({ band => 'the kinks' });

    # band 1
    $u2->add_to_bands($band1);
}

# currently,
# user [2] => bands [2, 1]

{
    $form->process( {
            id    => 2,
            name  => 'Paul McCartney',
            # no bands - if you unselect all options,
            # the browser doesn't submit that param at all
        } );

    ok( $form->submitted_and_valid );

    my $row = $schema->resultset('User')->find(2);

    $form->model->update($row);
}

{
    my $row = $schema->resultset('User')->find(2);

    is( $row->name, 'Paul McCartney' );

    my @bands = $row->bands->all;

    is( scalar(@bands), 0 );
}

