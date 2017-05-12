use strict;
use warnings;
use Test::More tests => 2;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/default_values/nested_name_accessor.yml');

my $schema = new_schema();

my $master = $schema->resultset('Master')->create({ id => 1 });

# filler rows
{
    # user 1
    my $u1 = $master->create_related( 'user', {
        name => 'mr. bar',
    } );

    # hasmanys 2,3
    $u1->create_related( 'hasmanys', { key => 'bar', value => 'a' } );
    $u1->create_related( 'hasmanys', { key => 'foo', value => 'b' } );
}

# rows we're going to use
{
    # user 2
    my $u2 = $master->create_related( 'user', {
        name => 'mr. foo',
    } );

    # hasmanys 3 4
    $u2->create_related( 'hasmanys', { key => 'bar', value => 'c' } );
    $u2->create_related( 'hasmanys', { key => 'foo', value => 'd' } );
}

{
    $form->process( {
        'name'      => 'Mr. Foo',
        'foo.value' => 'e',
    } );

    my $row = $schema->resultset('User')->find(2);

    $form->model->update($row);
}

{
    my $row = $schema->resultset('User')->find(2);

    is ( $row->name, 'Mr. Foo' );
    is ( $row->foo->value, 'e' );
}

