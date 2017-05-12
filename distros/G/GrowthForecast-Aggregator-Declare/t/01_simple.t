use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'LWP::UserAgent', 'DBI', 'HTTP::Response';
use Test::Requires {
    'DBD::SQLite' => 1.37,
};

use GrowthForecast::Aggregator::Declare;

diag "DBD::SQLite: $DBD::SQLite::VERSION\n";

subtest 'Callback' => sub {
    my @queries = gf {
        section member => sub {
            callback(
                name => 'count',
                description => 'member count',
                code => sub { 4649 },
            );
        };
    };
    my $ua = LWP::UserAgent->new();
    no warnings 'redefine';
    my @REQ;
    local *LWP::UserAgent::request = sub {
        push @REQ, $_[1];
        return HTTP::Response->new;
    };
    for (@queries) {
        $_->run(
            service => 'test',
            endpoint => 'http://gf/api/',
            ua => $ua,
        );
    }
    is(0+@REQ, 1);
    is($REQ[0]->uri, 'http://gf/api/test/member/count');
    like($REQ[0]->content, qr/description=member\+count/);
    like($REQ[0]->content, qr/number=4649/);
    note $REQ[0]->content;
};

subtest 'DB' => sub {
    my @queries = gf {
        section member => sub {
            db(
                name => 'count',
                description => 'member count',
                query => q{SELECT COUNT(*) FROM member},
            );
        };
    };
    my $ua = LWP::UserAgent->new();
    no warnings 'redefine';
    my @REQ;
    local *LWP::UserAgent::request = sub {
        push @REQ, $_[1];
        return HTTP::Response->new;
    };
    my $dbh = setup_db();
    for (@queries) {
        $_->run(
            dbh => $dbh,
            service => 'test',
            endpoint => 'http://gf/api/',
            ua => $ua,
        );
    }
    is(0+@REQ, 1);
    is($REQ[0]->uri, 'http://gf/api/test/member/count');
    like($REQ[0]->content, qr/description=member\+count/);
    like($REQ[0]->content, qr/number=4/);
    note $REQ[0]->content;
};

subtest 'DBMulti' => sub {
    my @queries = gf {
        section entry => sub {
            db_multi(
                names => ['count', 'unique'],
                descriptions => ['entry count', 'unique'],
                query => q{SELECT COUNT(*), COUNT(DISTINCT member_id) FROM entry},
            );
        };
    };
    my $ua = LWP::UserAgent->new();
    no warnings 'redefine';
    my @REQ;
    local *LWP::UserAgent::request = sub {
        push @REQ, $_[1];
        return HTTP::Response->new;
    };
    my $dbh = setup_db();
    for (@queries) {
        $_->run(
            dbh => $dbh,
            service => 'test',
            endpoint => 'http://gf/api/',
            ua => $ua,
        );
    }
    is(0+@REQ, 2);
    is($REQ[0]->uri, 'http://gf/api/test/entry/count');
    like($REQ[0]->content, qr/description=entry\+count/);
    like($REQ[0]->content, qr/number=4/);
    note $REQ[0]->content;

    is($REQ[1]->uri, 'http://gf/api/test/entry/unique');
    like($REQ[1]->content, qr/description=unique/);
    like($REQ[1]->content, qr/number=2/);
    note $REQ[1]->content;
};

done_testing;

sub setup_db {
    my $dbh = DBI->connect(
        'dbi:SQLite::memory:',
        '', '',
        {
            AutoCommit          => 1,
            PrintError          => 0,
            RaiseError          => 1,
            ShowErrorStatement  => 1,
            AutoInactiveDestroy => 1
        }
    ) or die $DBI::errstr;
    $dbh->do(q{CREATE TABLE member (id)});
    $dbh->do(q{INSERT INTO member (id) VALUES (1), (2), (3), (4)});

    $dbh->do(q{CREATE TABLE entry (id, member_id)});
    $dbh->do(q{INSERT INTO entry (id, member_id) VALUES (1,1), (2,1), (3,1), (4,2)});

    return $dbh;
}
