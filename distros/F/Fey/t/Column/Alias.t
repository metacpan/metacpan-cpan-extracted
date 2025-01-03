use strict;
use warnings;

use lib 't/lib';

use Test::More 0.88;

use Fey::Table;
use Fey::Column::Alias;

my $t = Fey::Table->new( name => 'Test' );
my $c = Fey::Column->new(
    name => 'test_id',
    type => 'text',
);
$t->add_column($c);

{
    my $alias = $c->alias();
    isa_ok( $alias, 'Fey::Column::Alias' );

    ok( $alias->is_alias(), 'is_alias is true' );
    is( $alias->name(), 'test_id', 'name is test_id' );
    is(
        $alias->alias_name(), 'test_id1',
        'alias_name is test_id1'
    );
    is(
        $alias->id(), 'Test.test_id1',
        'id is Test.test_id1'
    );

    is(
        $alias->table(), $t,
        'table for column alias is same as original column'
    );

    is( $alias->name(),         'test_id', 'column alias name is test_id' );
    is( $alias->type(),         'text',    'column alias type is text' );
    is( $alias->generic_type(), 'text', 'column alias generic type is text' );
    ok( !defined $alias->length(),    'column alias has no length' );
    ok( !defined $alias->precision(), 'column alias has no precision' );
    ok( !$alias->is_auto_increment(), 'column alias is not auto increment' );
    ok( !$alias->is_nullable(), 'column alias defaults to not nullable' );
}

{
    my $alias = $c->alias();
    is(
        $alias->alias_name(), 'test_id2',
        'alias_name is test_id2'
    );
}

{
    my $alias = $c->alias( alias_name => 'foobar' );
    is(
        $alias->alias_name(), 'foobar',
        'explicitly set alias_name to foobar'
    );
}

{
    my $c = Fey::Column->new(
        name => 'testy',
        type => 'text',
    );
    my $alias = $c->alias();
    eval { $alias->id() };
    isa_ok( $@, 'Fey::Exception::ObjectState' );
}

{
    my $alias = $c->alias('renamed');
    is( $alias->name(), 'test_id', 'name is test_id' );
    is(
        $alias->alias_name(), 'renamed',
        'alias_name is renamed'
    );
}

done_testing();
