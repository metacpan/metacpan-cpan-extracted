
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;
use Test::More;
use t::Util;
use InfluxDB;

my $ix;
my $database = 'ix-test-' . $$;
my $r;

subtest 'new' => sub {
    $ix = InfluxDB->new(
        %t::Util::InfluxDB_Server,
        %t::Util::DB_User,
        database => $database,
    );
    ok($ix);
};

subtest 'database create' => sub {
    # no privileges
    ok(!$ix->create_database(database => $database));
    is($ix->status->{status_line}, '401 Unauthorized');

    # has admin privileges
    ok($ix->switch_user(%t::Util::Admin_User));
    ok($ix->create_database(database => $database));
    is($ix->status->{status_line}, '201 Created');

    $r = $ix->list_database;
    my $found = 0;
    for my $db (@$r) {
        if ($db->{name} eq $database) {
            $found = 1;
            last;
        }
    }
    ok($found);
};

subtest 'points write, query, delete' => sub {
    ok($ix->delete_points(name => "s1"));

    my $data = {
        name    => "s1",
        columns => [qw(foo bar baz)],
        points  => [
            [10, 20, 30],
            [11, 21, 31],
        ],
    };
    ok($ix->write_points(data => [ $data ])); # ArrayRef[HashRef]

    ok($r = $ix->query(q => 'select * from s1'));

    my $points_got = reorder_points($r, order => $data->{columns});
    is_deeply($points_got, $data->{points});
};

subtest 'points write, query, delete; HashRef' => sub {
    ok($ix->delete_points(name => "s1"));

    my $data = {
        name    => "s1",
        columns => [qw(foo bar baz)],
        points  => [
            [10, 20, 30],
            [11, 21, 31],
        ],
    };
    ok($ix->write_points(data =>   $data  )); # HashRef

    ok($r = $ix->query(q => 'select * from s1'));

    my $points_got = reorder_points($r, order => $data->{columns});
    is_deeply($points_got, $data->{points});
};

subtest 'points write, query, delete; chunked' => sub {
    ok($ix->delete_points(name => "s1"));

    my $data = {
        name    => "s1",
        columns => [qw(foo bar baz)],
        points  => [
            [10, 20, 30],
            [11, 21, 31],
        ],
    };
    ok($ix->write_points(data => [ $data ])); # ArrayRef[HashRef]

    ok($r = $ix->query(q => 'select * from s1', chunked => 1));

    my $points_got = reorder_points($r, order => $data->{columns});
    is_deeply($points_got, $data->{points});
};

subtest 'database delete' => sub {
    ok($ix->switch_user(%t::Util::DB_User));
    # no privileges
    ok(!$ix->delete_database(database => $database));
    is($ix->status->{status_line}, '401 Unauthorized');

    # has admin privileges
    ok($ix->switch_user(%t::Util::Admin_User));
    ok($ix->delete_database(database => $database));
    is($ix->status->{status_line}, '204 No Content');

    $r = $ix->list_database;
    my $found = 0;
    for my $db (@$r) {
        if ($db->{name} eq $database) {
            $found = 1;
            last;
        }
    }
    ok(!$found);
};

done_testing;

