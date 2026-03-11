use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
plan skip_all => 'No MariaDB/MySQL server' unless TestMariaDB::server_available();
plan tests => 9;
use EV;
use EV::MariaDB;

my $m;

sub with_mariadb {
    my ($cb) = @_;
    $m = EV::MariaDB->new(
        TestMariaDB::connect_args(),
        on_connect => sub { $cb->() },
        on_error   => sub {
            diag("Error: $_[0]");
            EV::break;
        },
    );
    my $timeout = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $m->finish if $m->is_connected;
}

# escape
with_mariadb(sub {
    my $escaped = $m->escape("it's a test");
    like($escaped, qr/it\\'s a test|it''s a test/, 'escape: quote escaped');
    is($m->escape("hello"), 'hello', 'escape: no special chars');

    # accessors
    ok($m->server_version > 0, 'server_version is positive');
    ok(defined $m->host_info, 'host_info returns a value');
    ok(defined $m->character_set_name, 'character_set_name returns a value');
    ok($m->socket >= 0, 'socket returns valid fd');

    EV::break;
});

# error on invalid query
with_mariadb(sub {
    $m->query("invalid sql gibberish", sub {
        my ($rows, $err) = @_;
        ok($err, 'invalid query: got error');
        ok(!defined $rows || !ref $rows, 'invalid query: no rows');
        EV::break;
    });
});

# reset
with_mariadb(sub {
    $m->on_connect(sub {
        ok($m->is_connected, 'reset: reconnected');
        EV::break;
    });
    $m->reset;
});
