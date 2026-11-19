use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

my $host      = $ENV{TEST_CLICKHOUSE_HOST}         || '127.0.0.1';
my $http_port = $ENV{TEST_CLICKHOUSE_PORT}          || 8123;
my $nat_port  = $ENV{TEST_CLICKHOUSE_NATIVE_PORT}   || 9000;

require IO::Socket::INET;
my $http_ok = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $http_port, Timeout => 2) ? 1 : 0;
my $nat_ok  = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nat_port,  Timeout => 2) ? 1 : 0;
plan skip_all => "ClickHouse native port not reachable" unless $nat_ok;

plan tests => 37;

my $t1 = "df_d70";
my $t2 = "df_d70b";

my $ddl_tmpl = <<'DDL';
create table %s (
  u8 UInt8,
  i16 Int16 DEFAULT -3,
  s String,
  s2 String DEFAULT 'hi',
  fs FixedString(3),
  f64 Float64,
  f2 Float64 DEFAULT 1.5,
  dec Decimal(7, 6) DEFAULT 1.2,
  d Date,
  d32 Date32,
  dt DateTime,
  dt64 DateTime64(3),
  dd Date DEFAULT '2021-01-02',
  dtd DateTime DEFAULT '2021-01-02 03:04:05',
  e0 Enum8('zz' = 0, 'aa' = 1),
  e1 Enum8('a' = 1, 'b' = 2),
  e16 Enum16('a' = 1, 'b' = 2),
  ed Enum8('a' = 1, 'b' = 2) DEFAULT 'b',
  u UUID,
  ip4 IPv4,
  ip6 IPv6,
  arr Array(UInt8),
  arrd Array(UInt8) DEFAULT [1, 2],
  tup Tuple(UInt8, String),
  tupd Tuple(UInt8, String) DEFAULT (5, 'x'),
  mp Map(String, UInt8),
  n Nullable(Int32),
  nd Nullable(Int32) DEFAULT 42,
  lc LowCardinality(String),
  lcd LowCardinality(String) DEFAULT 'dflt',
  b Bool,
  bt Bool DEFAULT true,
  se String DEFAULT 'x''y'
) engine = Memory
DDL

my @cols = qw(u8 i16 s s2 fs f64 f2 dec d d32 dt dt64 dd dtd e0
  e1 e16 ed u ip4 ip6 arr arrd tup tupd mp n nd lc lcd b bt se);
my $ncols   = scalar @cols;
my $collist = join(", ", @cols);
# Enums without code 0 get the type default (the smallest declared code),
# checked directly: the CSV oracle stores an undeclared 0 there.
my $sellist = join(", ", grep { $_ ne 'e1' && $_ ne 'e16' } @cols);
my $enum_sel = "select cast(e1 as Int8), cast(e16 as Int16) from %s";

# Scalar-only subset: the TSV string path cannot carry nested types.
my @scols = grep { my $c = $_; !grep { $_ eq $c } qw(arr arrd tup tupd mp) } @cols;
my $scollist = join(", ", @scols);
my $ssellist = join(", ", grep { $_ ne 'e1' && $_ ne 'e16' } @scols);

# One CSV row per arrayref row: empty cells everywhere, then one row
# with \N cells (tuples have no \N form: an empty cell reads the same).
sub csv_rows {
    my @r1;
    my @r2;
    for my $c (@cols) {
        if ($c eq 'tup' || $c eq 'tupd') {
            push @r1, "";
            push @r2, "";
        } else {
            push @r1, "";
            push @r2, "\\N";
        }
    }
    return join(",", @r1) . "\n" . join(",", @r2) . "\n";
}

sub canon {
    my ($rows) = @_;
    return [ sort map {
        join("\0", map { defined $_ ? (ref $_ ? _flat($_) : $_) : "<NULL>" } @$_)
    } @$rows ];
}

sub _flat {
    my ($v) = @_;
    return join(",", map { defined $_ ? (ref $_ ? _flat($_) : $_) : "<NULL>" }
        (ref $v eq 'HASH' ? %$v : @$v));
}

my $ch;
my @steps;
my $step = 0;
my $t2_rows;

sub next_step {
    if ($step >= @steps) { EV::break; return; }
    my $s = $steps[$step++];
    $s->();
}

$ch = EV::ClickHouse->new(
    host       => $host,
    port       => $nat_port,
    protocol   => 'native',
    on_connect => sub { next_step() },
    on_error   => sub { diag("Native error: $_[0]"); EV::break },
);

push @steps, sub { $ch->query("drop table if exists $t1", sub { next_step() }) };
push @steps, sub {
    $ch->query(sprintf($ddl_tmpl, $t1), sub {
        my (undef, $e) = @_;
        ok(!$e, "create $t1") or diag($e);
        next_step();
    });
};
push @steps, sub { $ch->query("drop table if exists $t2", sub { next_step() }) };
push @steps, sub {
    $ch->query(sprintf($ddl_tmpl, $t2), sub {
        my (undef, $e) = @_;
        ok(!$e, "create $t2") or diag($e);
        next_step();
    });
};
push @steps, sub {
    my @empty = (("") x $ncols);
    my @nulls = ((undef) x $ncols);
    $ch->insert("$t1 ($collist)", [[@empty], [@nulls]],
        { empty_as_default => 1 }, sub {
        my (undef, $e) = @_;
        ok(!$e, "arrayref insert with empty_as_default") or diag($e);
        next_step();
    });
};
push @steps, sub {
    $ch->insert("$t2 ($collist)", csv_rows(), { data_format => "CSV" }, sub {
        my (undef, $e) = @_;
        ok(!$e, "CSV oracle insert") or diag($e);
        next_step();
    });
};
push @steps, sub {
    $ch->query("select $sellist from $t1", sub {
        my ($r1, $e1) = @_;
        ok(!$e1, "select $t1") or diag($e1 // "");
        $ch->query("select $sellist from $t2", sub {
            my ($r2, $e2) = @_;
            ok(!$e2, "select $t2") or diag($e2 // "");
            $t2_rows = $r2;
            is_deeply(canon($r1), canon($r2),
                "arrayref defaults match CSV oracle");
            next_step();
        });
    });
};
push @steps, sub {
    $ch->query(sprintf($enum_sel, $t1), sub {
        my ($r, $e) = @_;
        is_deeply($r, [[1, 1], [1, 1]], "arrayref: enum without 0 takes its smallest code")
            or diag($e // "");
        next_step();
    });
};
push @steps, sub { $ch->query("truncate table $t1", sub { next_step() }) };
push @steps, sub { $ch->query("truncate table $t2", sub { next_step() }) };
push @steps, sub {
    my $ns = scalar @scols;
    my $tsv = join("\t", ("") x $ns) . "\n"
            . join("\t", (("\\N") x $ns)) . "\n";
    $ch->insert("$t1 ($scollist)", $tsv, { empty_as_default => 1 }, sub {
        my (undef, $e) = @_;
        ok(!$e, "TSV string insert with empty_as_default") or diag($e);
        next_step();
    });
};
push @steps, sub {
    my $ns = scalar @scols;
    my $csv = join(",", ("") x $ns) . "\n"
            . join(",", (("\\N") x $ns)) . "\n";
    $ch->insert("$t2 ($scollist)", $csv, { data_format => "CSV" }, sub {
        my (undef, $e) = @_;
        ok(!$e, "CSV oracle insert for scalar subset") or diag($e);
        next_step();
    });
};
push @steps, sub {
    $ch->query("select $ssellist from $t1", sub {
        my ($r1, $e1) = @_;
        ok(!$e1, "select $t1 after TSV") or diag($e1 // "");
        $ch->query("select $ssellist from $t2", sub {
            my ($r2, $e2) = @_;
            ok(!$e2, "select $t2 scalar subset") or diag($e2 // "");
            is_deeply(canon($r1), canon($r2),
                "TSV defaults match CSV oracle");
            next_step();
        });
    });
};
push @steps, sub {
    $ch->query(sprintf($enum_sel, $t1), sub {
        my ($r, $e) = @_;
        is_deeply($r, [[1, 1], [1, 1]], "TSV: enum without 0 takes its smallest code")
            or diag($e // "");
        next_step();
    });
};
push @steps, sub { $ch->query("drop table if exists df_d70e", sub { next_step() }) };
push @steps, sub {
    $ch->query("create table df_d70e (a UInt8, d DateTime DEFAULT now()) engine = Memory",
        sub { next_step() });
};
push @steps, sub {
    $ch->insert("df_d70e (a, d)", [[1, undef]], { empty_as_default => 1 }, sub {
        my (undef, $e) = @_;
        like($e // "", qr/non-literal DEFAULT.*now\(\).*data_format.*Native/s,
            "now() default fails with Native pointer");
        next_step();
    });
};
push @steps, sub { $ch->query("drop table if exists df_d70x", sub { next_step() }) };
push @steps, sub {
    $ch->query("create table df_d70x (a UInt8, e UInt8 DEFAULT a + 1) engine = Memory",
        sub { next_step() });
};
push @steps, sub {
    $ch->insert("df_d70x (a, e)", [[1, undef]], { empty_as_default => 1 }, sub {
        my (undef, $e) = @_;
        like($e // "", qr/non-literal DEFAULT.*a \+ 1.*data_format.*Native/s,
            "expression default fails with Native pointer");
        next_step();
    });
};
push @steps, sub { $ch->query("drop table if exists df_d70p", sub { next_step() }) };
push @steps, sub {
    $ch->query("create table df_d70p (a UInt8, v UInt8 EPHEMERAL 5) engine = Memory",
        sub { next_step() });
};
push @steps, sub {
    $ch->insert("df_d70p (a, v)", [[1, undef]], { empty_as_default => 1 }, sub {
        my (undef, $e) = @_;
        like($e // "", qr/EPHEMERAL.*data_format.*Native/s,
            "EPHEMERAL column fails with Native pointer");
        next_step();
    });
};
push @steps, sub { $ch->query("drop table if exists df_d70m", sub { next_step() }) };
push @steps, sub {
    $ch->query("create table df_d70m (a UInt8, m UInt8 MATERIALIZED a + 1) engine = Memory",
        sub { next_step() });
};
push @steps, sub {
    $ch->insert("df_d70m (a, m)", [[1, 2]], { empty_as_default => 1 }, sub {
        my (undef, $e) = @_;
        ok($e, "MATERIALIZED column insert fails");
        next_step();
    });
};
push @steps, sub { $ch->query("truncate table $t1", sub { next_step() }) };
push @steps, sub {
    $ch->insert("$t1 ($collist)",
        [[undef, 2, "s", undef, "ab", 0.5, 1.5, 1.25, "2020-01-01",
          "2020-01-02", "2020-01-03 04:05:06", "2020-01-03 04:05:06.789",
          "2020-01-04", "2020-01-05 06:07:08", "aa", 1, 1, "b",
          "00000000-0000-0000-0000-000000000000", "1.2.3.4", "::1",
          [7], [8], [9, "z"], [10, "y"], { k => 1 }, 5, 6,
          "lc", "lcd", 1, 1, undef]],
        { defaults => { u8 => 99, s2 => "zz", se => "qq" } }, sub {
        my (undef, $e) = @_;
        ok(!$e, "defaults override without global flag") or diag($e);
        next_step();
    });
};
push @steps, sub {
    $ch->query("select u8, s2, se, i16, f2 from $t1", sub {
        my ($r, $e) = @_;
        ok(!$e, "select after defaults") or diag($e // "");
        is_deeply($r, [[99, "zz", "qq", 2, 1.5]],
            "caller values win over table DEFAULTs");
        next_step();
    });
};
push @steps, sub {
    $ch->insert("$t1 ($collist)",
        [[undef, 2, "s", "t", "ab", 0.5, 1.5, 1.25, "2020-01-01",
          "2020-01-02", "2020-01-03 04:05:06", "2020-01-03 04:05:06.789",
          "2020-01-04", "2020-01-05 06:07:08", "aa", 1, 1, "b",
          "00000000-0000-0000-0000-000000000000", "1.2.3.4", "::1",
          [7], [8], [9, "z"], [10, "y"], { k => 1 }, 5, 6,
          "lc", "lcd", 1, 0, "dflt"]],
        { defaults => { u8 => 100 } }, sub {
        my (undef, $e) = @_;
        ok(!$e, "defaults for one column, rest filled") or diag($e);
        next_step();
    });
};
push @steps, sub {
    $ch->query("select u8 from $t1 order by u8 desc limit 1", sub {
        my ($r, $e) = @_;
        is_deeply($r, [[100]], "named column takes caller value");
        next_step();
    });
};
push @steps, sub {
    $ch->insert("$t1 ($collist)",
        [[undef, undef, "s", "t", "ab", 0.5, 1.5, 1.25, "2020-01-01",
          "2020-01-02", "2020-01-03 04:05:06", "2020-01-03 04:05:06.789",
          "2020-01-04", "2020-01-05 06:07:08", "aa", 1, 1, "b",
          "00000000-0000-0000-0000-000000000000", "1.2.3.4", "::1",
          [7], [8], [9, "z"], [10, "y"], { k => 1 }, 5, 6,
          "lc", "lcd", 1, 0, "dflt"]],
        { defaults => { u8 => 101 } }, sub {
        my (undef, $e) = @_;
        like($e // "", qr/column 'i16' \(Int16\), row 0: invalid value undef/,
            "unnamed empty column still fails without global flag");
        next_step();
    });
};
push @steps, sub {
    $ch->insert("$t1 (u8)", [[undef]], sub {
        my (undef, $e) = @_;
        like($e // "", qr/column 'u8' \(UInt8\), row 0: invalid value undef/,
            "option off keeps old behaviour");
        next_step();
    });
};
push @steps, sub {
    $ch->insert("$t1 (u8)", [[undef]], { defaults => { zz => 1 } }, sub {
        my (undef, $e) = @_;
        like($e // "", qr/matches no insert column/,
            "unmatched defaults key fails");
        next_step();
    });
};
push @steps, sub { $ch->query("truncate table $t1", sub { next_step() }) };
push @steps, sub {
    $ch->insert("$t1 ($collist)",
        [[1, 2, "s", "t", "ab", 0.5, 1.5, 1.25, "2020-01-01",
          "2020-01-02", "2020-01-03 04:05:06", "2020-01-03 04:05:06.789",
          "2020-01-04", "2020-01-05 06:07:08", "aa", 1, 1, "b",
          "00000000-0000-0000-0000-000000000000", "1.2.3.4", "::1",
          [7], [8], [9, "z"], [10, "y"], { k => 1 }, undef, undef,
          "lc", "lcd", 1, 0, "dflt"]],
        { defaults => { n => undef, nd => undef } }, sub {
        my (undef, $e) = @_;
        ok(!$e, "defaults undef into Nullable") or diag($e);
        next_step();
    });
};
push @steps, sub {
    $ch->query("select n, nd from $t1", sub {
        my ($r, $e) = @_;
        is_deeply($r, [[undef, undef]], "Nullable gets NULL");
        next_step();
    });
};
push @steps, sub {
    $ch->insert("$t1 (u8)", [[undef]], { defaults => { u8 => undef } }, sub {
        my (undef, $e) = @_;
        like($e // "", qr/column 'u8' \(UInt8\), row 0: invalid value undef/,
            "defaults undef into non-nullable fails");
        next_step();
    });
};
push @steps, sub {
    eval {
        $ch->insert("$t1 (u8)", "1\n",
            { data_format => "TabSeparated", empty_as_default => 1 }, sub {});
    };
    like($@, qr/cannot be combined with data_format/,
        "data_format + empty_as_default croaks");
    next_step();
};
push @steps, sub {
    eval { $ch->insert("$t1 (u8)", [[1]], { defaults => "x" }, sub {}); };
    like($@, qr/defaults must be a HASH reference/,
        "non-hash defaults croaks");
    next_step();
};
push @steps, sub {
    $ch->insert("$t1 (u8)", [[5]], { defaults => {} }, sub {
        my (undef, $e) = @_;
        ok(!$e, "empty defaults hash is a no-op") or diag($e);
        next_step();
    });
};
push @steps, sub { $ch->query("drop table if exists df_d70j", sub { next_step() }) };
my $json_ok;
push @steps, sub {
    $ch->query("create table df_d70j (j JSON) engine = Memory",
               sub { $json_ok = !$_[1]; next_step() });
};
push @steps, sub {
    SKIP: {
        skip "server has no JSON type", 4 unless $json_ok;
        $ch->insert("df_d70j (j)", [[undef]], { empty_as_default => 1 }, sub {
            my (undef, $e) = @_;
            ok(!$e, "JSON empty with flag") or diag($e);
            $ch->insert("df_d70j (j)", [[{}]], sub {
                my (undef, $e2) = @_;
                ok(!$e2, "JSON empty hash without flag") or diag($e2);
                $ch->query("select toString(j) from df_d70j", sub {
                    my ($r, $e3) = @_;
                    ok(!$e3, "select JSON") or diag($e3 // "");
                    is_deeply($r, [["{}"], ["{}"]], "JSON empty default is {}");
                    next_step();
                });
            });
        });
        return;
    }
    next_step();
};
push @steps, sub {
    SKIP: {
        skip "HTTP port not reachable", 1 unless $http_ok;
        my $hh = EV::ClickHouse->new(
            host     => $host,
            port     => $http_port,
            protocol => 'http',
        );
        eval { $hh->insert("t (a)", [[1]], { empty_as_default => 1 }, sub {}); };
        like($@, qr/require the native protocol/,
            "HTTP + empty_as_default croaks");
    }
    next_step();
};
for my $t ($t1, $t2, "df_d70e", "df_d70x", "df_d70p", "df_d70m", "df_d70j") {
    push @steps, sub { $ch->query("drop table if exists $t", sub { next_step() }) };
}

my $timeout = EV::timer(120, 0, sub { diag("TIMEOUT"); EV::break });
EV::run;
$ch->finish if $ch && $ch->is_connected;
