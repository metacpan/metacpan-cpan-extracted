
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

subtest 'continuous queries' => sub {
    subtest 'list continuous queries' => sub {
        ok($r = $ix->list_continuous_queries);
        ok(scalar(@{ $r->[0]{points} }) == 0);
    };

    subtest 'create continuous query' => sub {
        ok($ix->create_continuous_query(
            q    => 'select max(foo) from s1 group by time(1m)',
            name => 's1.1m',
        ));

        ok($r = $ix->list_continuous_queries);
        ok(scalar(@{ $r->[0]{points} }) == 1);
    };

    subtest 'drop continuous query' => sub {
        $r = $ix->as_hash($r);
        my $cq_id = $r->{"continuous queries"}[0]{id};
        ok($ix->drop_continuous_query(id => $cq_id));

        ok($r = $ix->list_continuous_queries);
        ok(scalar(@{ $r->[0]{points} }) == 0);
    };
};

subtest 'database delete' => sub {
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

