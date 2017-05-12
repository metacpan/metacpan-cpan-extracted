use strict;
use warnings;

use Test::More;

use Fey::DBIManager::Source;

my $DSN      = 'dbi:Mock:foo';
my $Username = 'user';
my $Password = 'password';

my $can_modify_pid = eval { local $$ = $$ + 1; 1 };

{
    my $source = Fey::DBIManager::Source->new( dsn => $DSN );

    is( $source->name(), 'default', 'source is named default' );
    is( $source->dsn(), $DSN, 'dsn passed to new() is returned by dsn()' );
    is( $source->username(), '', 'default username is empty string' );
    is( $source->password(), '', 'default password is empty string' );
    is_deeply(
        $source->attributes(), {
            AutoCommit         => 1,
            RaiseError         => 1,
            PrintError         => 0,
            PrintWarn          => 1,
            ShowErrorStatement => 1,
        },
        'check default attributes'
    );
    ok( !$source->post_connect(), 'no post_connect hook by default' );
    ok( $source->auto_refresh(),  'auto_refresh defaults to true' );
    ok( !$source->_threaded(),    'threads is false' );

    my $sub = sub { };
    $source = Fey::DBIManager::Source->new(
        dsn        => $DSN,
        username   => $Username,
        password   => $Password,
        attributes => {
            AutoCommit => 0,
            SomeThing  => 1,
        },
        post_connect => $sub,
        auto_refresh => 0,
    );

    is( $source->dsn(), $DSN, 'dsn passed to new() is returned by dsn()' );
    is( $source->username(), $Username, 'username is user' );
    is( $source->password(), $Password, 'password is password' );
    is_deeply(
        $source->attributes(), {
            AutoCommit         => 1,
            RaiseError         => 1,
            PrintError         => 0,
            PrintWarn          => 1,
            ShowErrorStatement => 1,
            SomeThing          => 1,
        },
        'attributes include values passed in, except AutoCommit is 1'
    );
    is( $source->post_connect(), $sub, 'post_connect is set' );
    ok( !$source->auto_refresh(), 'auto_refresh  is false' );
}

eval <<'EOF';
{
    package threads;

    $threads::tid = 42;
    sub tid { $threads::tid }
}
EOF

{
    my $source = Fey::DBIManager::Source->new( dsn => $DSN );

    ok( $source->_threaded(), 'threads is true' );
}

{
    my $post_connect = 0;
    my $count        = 0;
    my $sub          = sub { $post_connect = shift; $count++ };

    my $source = Fey::DBIManager::Source->new(
        dsn        => $DSN,
        username   => $Username,
        password   => $Password,
        attributes => {
            AutoCommit => 0,
        },
        post_connect  => $sub,
        ping_interval => 0,
    );

    my $dbh = $source->dbh();

    test_dbh( $dbh, $post_connect );

    my $expect_count = 1;

    is( $count, $expect_count, 'one DBI handle made so far' );

 SKIP:
    {
        skip 'Cannot modify $$ on this platform', 2,
            unless $can_modify_pid;

        local $$ = $$ + 1;
        $source->_ensure_fresh_dbh();

        ok( $dbh->{InactiveDestroy}, 'InactiveDestroy was set to true' );

        $dbh = $source->dbh();
        test_dbh( $dbh, $post_connect );

        $expect_count++;

        is( $count, $expect_count, 'new handle made when pid changes' );
    }

    # Need to do this since pid just changed again.
    $source->_unset_dbh(); $source->dbh();

    $expect_count++;

    $threads::tid++;
    $source->_ensure_fresh_dbh();

    ok( !$dbh->{InactiveDestroy}, 'InactiveDestroy was not set' );

    $dbh = $source->dbh();
    test_dbh( $dbh, $post_connect );

    $expect_count++;

    is( $count, $expect_count, 'new handle made when tid changes' );

    $source->_ensure_fresh_dbh();
    is( $count, $expect_count, 'no new handle made with same pid & tid' );

    $dbh->{mock_can_connect} = 0;
    $source->_ensure_fresh_dbh();

    $expect_count++;

    is( $count, $expect_count, 'new handle made when Active is false' );

    $dbh = $source->dbh();

    $dbh->{mock_can_connect} = 1;
    no warnings 'redefine';
    local *DBD::Mock::db::ping = sub { return 0 };

    $source->_ensure_fresh_dbh();

    $expect_count++;

    is( $count, $expect_count, 'new handle made when ping returns false' );
}

{
    my $count = 0;
    my $sub = sub { $count++ };

    my $source = Fey::DBIManager::Source->new(
        dsn        => $DSN,
        username   => $Username,
        password   => $Password,
        attributes => {
            AutoCommit => 0,
        },
        auto_refresh => 0,
        post_connect => $sub,
    );

    my $dbh = $source->dbh();

    is( $count, 1, 'one DBI handle made so far' );

 SKIP:
    {
        skip 'Cannot modify $$ on this platform', 1,
            unless $can_modify_pid;

        local $$ = $$ + 1;
        $dbh = $source->dbh();

        is( $count, 1, 'no new handle when pid changes' );
    }

    $threads::tid++;
    $dbh = $source->dbh();

    is( $count, 1, 'no new handle when tid changes' );

    $dbh->{mock_can_connect} = 0;
    $dbh = $source->dbh();

    is( $count, 1, 'no new handle made when Active is false' );

    $dbh->{mock_can_connect} = 1;
    no warnings 'redefine';
    local *DBD::Mock::db::ping = sub { return 0 };
    $dbh = $source->dbh();

    is( $count, 1, 'no new handle made when ping returns false' );
}

{
    my $source
        = Fey::DBIManager::Source->new( dsn => $DSN, name => 'another' );

    is(
        $source->name(), 'another',
        'explicit name passed to constructor'
    );
}

{
    my $source = Fey::DBIManager::Source->new( dsn => $DSN );

    ok(
        !$source->allows_nested_transactions(),
        'source allows nested transactions is false by default with DBD::Mock'
    );

    ok(
        $source->dbh()->{AutoCommit},
        'AutoCommit is true after checking allows_nested_transactions'
    );
}

{
    my $source = Fey::DBIManager::Source->new( dsn => $DSN );

    no warnings 'redefine', 'once';
    local *DBD::Mock::db::begin_work = sub { };
    local *DBD::Mock::db::rollback   = sub { };

    ok(
        $source->allows_nested_transactions(),
        'source allows nested transactions is true'
    );
}

{
    my %attr = Fey::DBIManager::Source->_required_dbh_attributes();
    my %bad_attr;

    $bad_attr{$_} = $attr{$_} ? 0 : 1 for keys %attr;

    my $dbh = DBI->connect( $DSN, '', '', \%bad_attr );
    my $source = Fey::DBIManager::Source->new( dsn => $DSN, dbh => $dbh );

    for my $k ( sort keys %attr ) {
        my $actual_val = $source->dbh()->{$k};
        ok(
            ( $attr{$k} ? $actual_val : !$actual_val ),
            "DBI attribute $k is set to required value for Source"
        );
    }
}

{
    my $connect = 0;

    my %p = (
        name         => 'foo',
        dsn          => $DSN,
        username     => 'foo',
        password     => 'bar',
        attributes   => { foo => 42 },
        post_connect => sub { $connect++ },
    );

    my $source = Fey::DBIManager::Source->new(%p);

    $source->dbh(); # force the creation of a handle

    ok( $source->_has_dbh(), 'source does have a handle' );

    my $clone = $source->clone();

    for my $attr (qw( dsn username password attributes )) {
        is_deeply(
            $source->$attr(), $clone->$attr(),
            "original and clone share the same $attr"
        );
    }

    ok( ! $clone->_has_dbh(), 'clone does not have a handle yet' );

    is(
        $clone->name(), 'Clone of foo',
        'name is Clone of foo'
    );

    isnt(
        $source->dbh(), $clone->dbh(),
        'original and clone have different handles'
    );

    is(
        $connect, 2,
        'post_connect sub has been called twice'
    );

    my $clone2 = $source->clone( name => 'bar' );

    is(
        $clone2->name(), 'bar',
        'can pass args to clone()'
    );
}

SKIP:
{
    skip 'These tests require Test::Output', 2
        unless eval "use Test::Output; 1";

    stderr_is(
        sub {
            ok(
                !Fey::DBIManager::Source->new( dsn => $DSN )
                    ->allows_nested_transactions(),
                'DBD::Mock does not support nested transactions'
            );
        },
        '',
        'no warnings checking for nested transaction support with DBD::Mock'
    );
}

sub test_dbh {
    my $dbh          = shift;
    my $post_connect = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    isa_ok( $dbh, 'DBI::db' );
    is(
        $dbh->{Name}, 'foo',
        'db name passed to DBI->connect() is same as the one passed to new()'
    );
    is(
        $dbh->{Username}, $Username,
        'username passed to DBI->connect() is same as the one passed to new()'
    );
    is(
        $post_connect, $dbh,
        'post_connect sub was called with DBI handle as argument'
    );

    check_attributes($dbh);
}

sub check_attributes {
    my $dbh = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my %expect = (
        AutoCommit         => 1,
        RaiseError         => 1,
        PrintError         => 0,
        PrintWarn          => 1,
        ShowErrorStatement => 1,
    );
    for my $k ( sort keys %expect ) {
        ok(
            ( $expect{$k} ? $dbh->{$k} : !$dbh->{$k} ),
            "$k should be " . ( $expect{$k} ? 'true' : 'false' )
        );
    }
}

done_testing();
