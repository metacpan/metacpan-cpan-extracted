use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

use Fey::Table::Alias;

my $t  = Fey::Table->new( name => 'Test' );
my $c1 = Fey::Column->new(
    name => 'test_id',
    type => 'text',
);

my $c2 = Fey::Column->new(
    name => 'size',
    type => 'integer',
);

$t->add_column($_) for $c1, $c2;

{
    my $alias = $t->alias();
    isa_ok( $alias, 'Fey::Table::Alias' );

    is( $alias->name(),       'Test',  'name is Test' );
    is( $alias->alias_name(), 'Test1', 'alias_name is Test1' );
    is( $alias->id(),         'Test1', 'id is Test1' );

    ok( $alias->is_alias(), 'is_alias is true' );

    my $col = $alias->column('test_id');
    is(
        $col->table(), $alias,
        'table for column from alias is the alias table'
    );
    is(
        $col, $alias->column('test_id'),
        'column() method for alias just clones a column once'
    );

    my @cols = sort { $a->name() cmp $b->name() } $alias->columns();
    is( scalar @cols,      2,         'columns() returns 2 columns' );
    is( $cols[0]->name(),  'size',    'first col is size' );
    is( $cols[0]->table(), $alias,    'table for first col is alias' );
    is( $cols[1]->name(),  'test_id', 'second col is test_id' );
    is( $cols[1]->table(), $alias,    'table for second col is alias' );

    ok(
        !$alias->column('no-such-thing'),
        'column() returns false for nonexistent column'
    );

    @cols = sort { $a->name() cmp $b->name() } $alias->columns('size');
    is( scalar @cols,     1,      'columns() returned named columns only' );
    is( $cols[0]->name(), 'size', 'column returned was size' );
}

{
    my $alias = $t->alias();
    is( $alias->alias_name, 'Test2', 'alias_name is Test2 - second alias' );
}

{
    my $alias = $t->alias( alias_name => 'Foo' );
    is( $alias->alias_name(), 'Foo', 'explicitly set alias name to foo' );
}

{
    my $s = Fey::Test->mock_test_schema();

    my $alias = $s->table('User')->alias();
    is( $alias->schema(), $s, 'schema method returns correct schema' );

    my $pk = $alias->primary_key();
    is( scalar @{$pk}, 1, 'one column in primary key' );
    is(
        $pk->[0]->name(), $s->table('User')->column('user_id')->name(),
        'primary_key() returns same columns as non-alias'
    );
    is( $pk->[0]->table(), $alias, 'table() for pk col is alias' );
}

{
    my $alias = $t->alias('renamed');
    is( $alias->name(),       'Test',    'name is Test' );
    is( $alias->alias_name(), 'renamed', 'alias_name is renamed' );
}

done_testing();
