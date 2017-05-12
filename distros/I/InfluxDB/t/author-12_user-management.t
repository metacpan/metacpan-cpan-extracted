
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

subtest 'dataabse user' => sub {
    my $name = 'scott';
    my $password = 'tiger';

    subtest 'create' => sub {
        $r = $ix->list_database_users;
        is(scalar(@$r), 0);

        ok($ix->create_database_user(name => $name, password => $password));

        $r = $ix->list_database_users;
        is(scalar(@$r), 1);
    };

    subtest 'update' => sub {
        ok($r = $ix->show_database_user(name => $name));
        is($r->{name}, $name);
        is($r->{isAdmin}, 0);

        $r = $ix->update_database_user(name => $name, admin => 1);

        ok($r = $ix->show_database_user(name => $name));
        is($r->{name}, $name);
        is($r->{isAdmin}, 1);
    };

    subtest 'delete' => sub {
        $r = $ix->list_database_users;
        is(scalar(@$r), 1);

        ok($ix->delete_database_user(name => $name));

        $r = $ix->list_database_users;
        is(scalar(@$r), 0);
    };
};

subtest 'cluster admin' => sub {
    my $name = 'cadmin';
    my $password = 'pa55w0rd';

    my $n_cluster_admins;

    subtest 'create' => sub {
        $r = $ix->list_cluster_admins;
        $n_cluster_admins = scalar(@$r);

        ok($ix->create_cluster_admin(name => $name, password => $password));

        $r = $ix->list_cluster_admins;
        is(scalar(@$r), $n_cluster_admins+1);
    };

    subtest 'update' => sub {
        # ok($r = $ix->show_cluster_admin(name => $name));
        # is($r->{name}, $name);

        ok($ix->update_cluster_admin(name => $name, password => "blah"));
    };

    subtest 'delete' => sub {
        $r = $ix->list_cluster_admins;
        is(scalar(@$r), $n_cluster_admins+1);

        ok($ix->delete_cluster_admin(name => $name));

        $r = $ix->list_cluster_admins;
        is(scalar(@$r), $n_cluster_admins);
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

