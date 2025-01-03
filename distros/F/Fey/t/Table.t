use strict;
use warnings;

use lib 't/lib';

use Fey::Test 0.05;
use Test::More 0.88;

use Fey::Table;

{
    eval { my $t = Fey::Table->new() };
    like(
        $@, qr/\QAttribute (name) is required/,
        'name is a required param'
    );
}

{
    my $t = Fey::Table->new( name => 'Test' );

    is( $t->name(), 'Test', 'table name is Test' );
    ok( !$t->is_view(), 'table is not view' );

    is( $t->id(), 'Test', 'table id is Test' );

    ok( !$t->is_alias(), 'Test has no alias' );
}

{
    my $t = Fey::Table->new( name => 'Test', is_view => 1 );

    ok( $t->is_view(), 'table is view' );
}

{
    my $t  = Fey::Table->new( name => 'Test' );
    my $c1 = Fey::Column->new(
        name => 'test_id',
        type => 'text',
    );

    ok( !$c1->table(), 'column has no table' );

    $t->add_column($c1);
    ok( $t->column('test_id'), 'test_id column is in table' );

    is(
        $c1->table(), $t,
        'column has a table after calling add_column()'
    );

    my @cols = $t->columns;
    is( scalar @cols, 1,   'table has one column' );
    is( $cols[0],     $c1, 'columns() returned one column - test_id' );

    eval { $t->add_column($c1) };
    like(
        $@, qr/already has a column named test_id/,
        'cannot add a column twice'
    );

    $t->remove_column($c1);
    ok( !$t->column('test_id'), 'test_id column is not in table' );
    ok(
        !$c1->table(),
        'column has no table after calling remove_column()'
    );

    $t->add_column($c1);
    $t->remove_column( $c1->name() );
    ok( !$t->column('test_id'), 'test_id column is not in table' );
}

{
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

    is( scalar $t->columns, 2, 'table has two columns' );

    eval { $t->add_candidate_key('no_such_thing') };
    like(
        $@, qr/The column no_such_thing is not part of the Test table./,
        'add_candidate_key() called with invalid column name'
    );

    eval { $t->add_candidate_key() };
    like(
        $@, qr/\Q0 parameters/,
        'add_candidate_key() called with no parameters'
    );

    $t->add_candidate_key('test_id');
    is_deeply(
        _keys_to_names( $t->candidate_keys() ),
        [ ['test_id'] ],
        'one key set and it contains only test_id'
    );

    $t->add_candidate_key('test_id');
    is_deeply(
        _keys_to_names( $t->candidate_keys() ),
        [ ['test_id'] ],
        'one key set and it contains only test_id (after adding same key twice)'
    );

    my $pk = $t->primary_key();
    is( scalar @{$pk},    1,         'table has a one column pk' );
    is( $pk->[0]->name(), 'test_id', 'pk column is test_id' );

    $t->remove_column('test_id');
    $pk = $t->primary_key();
    is( scalar @{$pk}, 0, 'table has no pk' );

    $t->add_column($c1);
    $t->add_candidate_key('test_id');
    $t->remove_column($c2);

    $pk = $t->primary_key();
    is(
        scalar @{$pk}, 1,
        'table has a one column pk (removing a non-key column does not affect keys)'
    );
    is( $pk->[0]->name(), 'test_id', 'pk column is test_id' );
}

{
    my $s = Fey::Test->mock_test_schema();
    my $t = $s->table('User');

    my @cols = sort map { $_->name() } $t->columns( 'user_id', 'username' );

    is( scalar @cols, 2, 'columns() returns named columns' );
    is_deeply(
        \@cols, [ 'user_id', 'username' ],
        'columns are user_id & username'
    );

    @cols = sort map { $_->name() } $t->columns('no_such_column');
    is( scalar @cols, 0, 'columns() ignores columns which do not exist' );
}

{
    my $s = Fey::Test->mock_test_schema();
    my $t = $s->table('User');

    $t->remove_candidate_key( @{$_} ) for @{ $t->candidate_keys() };

    $t->add_candidate_key('user_id');
    $t->add_candidate_key( 'username', 'email' );

    is_deeply(
        _keys_to_names( $t->candidate_keys() ),
        [ ['user_id'], [ 'email', 'username' ] ],
        'two keys, one for user_id and one for email + username'
    );

    my $pk = $t->primary_key();
    is( scalar @{$pk},    1,         'table has one pk column' );
    is( $pk->[0]->name(), 'user_id', 'pk is user_id' );

    ok(
        $t->has_candidate_key('user_id'),
        'table has key for (user_Id)'
    );

    ok(
        $t->has_candidate_key( 'username', 'email' ),
        'table has key for (username, email)'
    );

    ok(
        !$t->has_candidate_key('username'),
        'table does not have key for (username)'
    );

    eval { $t->has_candidate_key() };
    like(
        $@, qr/\Q0 parameters/,
        'has_candidate_key() called with no parameters'
    );

    eval { $t->has_candidate_key('no_such_thing') };
    like(
        $@, qr/The column no_such_thing is not part of the User table./,
        'has_candidate_key() called with invalid column name'
    );

    $t->remove_candidate_key('user_id');
    is_deeply(
        _keys_to_names( $t->candidate_keys() ),
        [ [ 'email', 'username' ] ],
        'one key, email + username'
    );

    $t->remove_candidate_key('user_id');
    is_deeply(
        _keys_to_names( $t->candidate_keys() ),
        [ [ 'email', 'username' ] ],
        'one key, email + username after removing key which is not in table'
    );

    eval { $t->remove_candidate_key('no_such_thing') };
    like(
        $@, qr/The column no_such_thing is not part of the User table./,
        'remove_candidate_key() called with invalid column name'
    );

    eval { $t->remove_candidate_key() };
    like(
        $@, qr/\Q0 parameters/,
        'remove_candidate_key() called with no parameters'
    );
}

{
    my $s = Fey::Test->mock_test_schema();
    my $t = $s->table('User');

    my $a1 = $t->aliased_column( 'foo_', 'user_id' );
    is(
        $a1->alias_name(), 'foo_user_id',
        'aliased_column return column alias with expected alias_name'
    );

    my ( $a2, $a3 ) = $t->aliased_columns( 'foo_', 'user_id', 'username' );
    is(
        $a2->alias_name(), 'foo_user_id',
        'aliased_columns return column aliases with expected alias_names'
    );
    is(
        $a3->alias_name(), 'foo_username',
        'aliased_columns return column aliases with expected alias_names'
    );
}

{
    my $s = Fey::Test->mock_test_schema();
    my $t = $s->table('User');

    my @a = $t->aliased_columns('foo_');
    is(
        scalar @a, 3,
        'aliased_columns with no explicit columns returns all columns'
    );
}

sub _keys_to_names {
    my @n;
    for my $k ( @{ $_[0] } ) {
        push @n, [ sort map { $_->name() } @{$k} ];
    }

    return \@n;
}

done_testing();
