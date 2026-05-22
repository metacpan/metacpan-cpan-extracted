use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

my $host     = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $nat_port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
my $nat_ok = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nat_port, Timeout => 2) ? 1 : 0;
plan skip_all => "Native ClickHouse not reachable" unless $nat_ok;

# Probe whether the server understands JSON columns.
my $json_ok = 0;
{
    my $ch;
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        on_connect => sub {
            $ch->query("create temporary table _ch_json_probe (j JSON) ENGINE = Memory",
                { allow_experimental_json_type => 1 },
                sub { my (undef, $err) = @_; $json_ok = !$err; EV::break });
        },
        on_error => sub { EV::break },
    );
    my $t = EV::timer(5, 0, sub { EV::break });
    EV::run;
    $ch->finish if $ch->is_connected;
}
plan skip_all => "JSON column type not available on this server" unless $json_ok;

plan tests => 9;

sub run_with_timeout { my $t = EV::timer($_[0], 0, sub { EV::break }); EV::run }

# 1-2: encode + roundtrip a flat JSON hashref.
{
    my ($ch, $rows, $err);
    my $table = '_ev_ch_json_' . $$;
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        settings => { allow_experimental_json_type => 1 },
        on_connect => sub {
            $ch->query("create temporary table $table (j JSON) ENGINE = Memory", sub {
                $ch->insert($table, [
                    [{ name => 'alice', age => 30 }],
                    [{ name => 'bob',   age => 25 }],
                ], sub {
                    (undef, $err) = @_;
                    return EV::break if $err;
                    $ch->query("select j from $table order by j.name::String", sub {
                        ($rows, $err) = @_; EV::break;
                    });
                });
            });
        },
    );
    run_with_timeout(15);
    ok(!$err, "JSON insert + select: no error") or diag "err=$err";
    is_deeply(
        [ map $_->[0], @{$rows // []} ],
        [ { name => 'alice', age => 30 }, { name => 'bob', age => 25 } ],
        "JSON column roundtrips with hashref leaves",
    );
    $ch->finish if $ch->is_connected;
}

# 3-4: nested hashref auto-flattened to dotted paths, restored on read.
{
    my ($ch, $rows, $err);
    my $table = '_ev_ch_json2_' . $$;
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        settings => { allow_experimental_json_type => 1 },
        on_connect => sub {
            $ch->query("create temporary table $table (j JSON) ENGINE = Memory", sub {
                $ch->insert($table, [
                    [{ user => { id => 7, tags => ['a','b'] } }],
                ], sub {
                    (undef, $err) = @_;
                    return EV::break if $err;
                    $ch->query("select j from $table", sub {
                        ($rows, $err) = @_; EV::break;
                    });
                });
            });
        },
    );
    run_with_timeout(15);
    ok(!$err, "JSON nested + array: no error") or diag "err=$err";
    is_deeply(
        $rows && @$rows ? $rows->[0][0] : undef,
        { user => { id => 7, tags => ['a','b'] } },
        "JSON nested hash + Array(String) leaf roundtrips",
    );
    $ch->finish if $ch->is_connected;
}

# 5-6: blessed Bool + Float64 + sparse paths.
{
    require JSON::PP;
    my ($ch, $rows, $err);
    my $table = '_ev_ch_json3_' . $$;
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        settings => { allow_experimental_json_type => 1 },
        on_connect => sub {
            $ch->query("create temporary table $table (j JSON) ENGINE = Memory", sub {
                $ch->insert($table, [
                    [{ active => JSON::PP::true(),  ratio => 1.5  }],
                    [{ active => JSON::PP::false(), ratio => 0.25, label => 'x' }],
                ], sub {
                    (undef, $err) = @_;
                    return EV::break if $err;
                    $ch->query("select count() from $table", sub {
                        ($rows, $err) = @_; EV::break;
                    });
                });
            });
        },
    );
    run_with_timeout(15);
    ok(!$err, "JSON Bool + Float64 + sparse paths: no error") or diag "err=$err";
    is($rows && @$rows ? $rows->[0][0] : undef, 2,
       "JSON sparse rows: count() returns 2");
    $ch->finish if $ch->is_connected;
}

# 7-9: typed-path JSON column round-trip — JSON(name String, age UInt32)
# pins schema; encoder writes typed paths as regular columns, decoder reads
# them back into the per-row hash under the declared names.
{
    my ($ch, $rows, $err);
    my $table = '_ev_ch_jsont_' . $$;
    $ch = EV::ClickHouse->new(
        host => $host, port => $nat_port, protocol => 'native',
        settings => { allow_experimental_json_type => 1 },
        on_connect => sub {
            $ch->query("create temporary table $table "
                     . "(j JSON(name String, age UInt32)) "
                     . "ENGINE = Memory", sub {
                $ch->insert($table, [
                    [{ name => 'alice', age => 30, extra => 'dyn1' }],
                    [{ name => 'bob',   age => 25 }],
                ], sub {
                    (undef, $err) = @_;
                    return EV::break if $err;
                    $ch->query("select j.name, j.age, j FROM $table order by j.name", sub {
                        ($rows, $err) = @_; EV::break;
                    });
                });
            });
        },
    );
    run_with_timeout(15);
    ok(!$err, "typed-path JSON: no error") or diag "err=$err";
    is($rows && @$rows ? $rows->[0][0] : undef, 'alice',
       "typed path j.name decoded as String column");
    is($rows && @$rows ? $rows->[0][1] : undef, 30,
       "typed path j.age decoded as UInt32 column");
    $ch->finish if $ch->is_connected;
}
