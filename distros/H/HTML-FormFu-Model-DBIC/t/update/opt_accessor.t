use strict;
use warnings;
use Test::More tests => 3;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/opt_accessor.yml');

my $schema = new_schema();

my $master = $schema->resultset('Master')->create({ id => 1 });

# filler rows
{
    # user 1
    my $u1 = $master->create_related( 'user', {
        name => 'mr. bar',
    } );
}

# rows we're going to use
{
    # user 2
    my $u2 = $master->create_related( 'user', {
        name => 'mr. foo',
    } );
}

{
    $form->process( {
        id       => 2,
        fullname => 'mr billy bob',
    } );

    my $row = $schema->resultset('User')->find(2);

    $form->model->update($row);
}

{
    my $row = $schema->resultset('User')->find(2);

    is( $row->title,    'mr' );
    is( $row->name,     'billy bob' );
    is( $row->fullname, 'mr billy bob' );
}

