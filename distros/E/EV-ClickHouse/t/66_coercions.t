use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

# EVCH-4 (Enum labels), EVCH-5 (Decimal exponent forms), EVCH-12
# (IPv4 dotted string into an IPv6 column): native INSERT value coercions.
# Covers arrayref rows and TabSeparated string inserts, Nullable/Array
# variants and the reject cases. Stored values are read back via toString.

my $host = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $port = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

require IO::Socket::INET;
plan skip_all => "ClickHouse native port not reachable at $host:$port"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port, Timeout => 2);

my $ch;
my @steps;
my $step_no = 0;

sub step {
    my ($name, $code) = @_;
    push @steps, sub {
        my ($done) = @_;
        $step_no++;
        $code->($done);
    };
}

sub ddl {
    my ($table, $cols, $done, $next) = @_;
    $ch->query("drop table if exists $table", sub {
        $ch->query("create table $table ($cols) engine = Memory", sub {
            my (undef, $err) = @_;
            ok(!$err, "$table: create") or diag($err);
            $next->();
        });
    });
}

sub drop_table {
    my ($table, $done) = @_;
    $ch->query("drop table $table", sub { $done->() });
}

sub check_rows {
    my ($name, $sql, $expected, $done) = @_;
    $ch->query($sql, sub {
        my ($rows, $err) = @_;
        ok(!$err, "$name: select no error") or diag($err);
        is_deeply($rows, $expected, "$name: stored values") or diag explain($rows);
        $done->();
    });
}

sub insert_av_ok {
    my ($name, $table, $rows, $done) = @_;
    $ch->insert($table, $rows, sub {
        my (undef, $err) = @_;
        ok(!$err, "$name: insert no error") or diag($err);
        $done->();
    });
}

sub insert_tsv_ok {
    my ($name, $table, $tsv, $done) = @_;
    $ch->insert($table, $tsv, sub {
        my (undef, $err) = @_;
        ok(!$err, "$name: insert no error") or diag($err);
        $done->();
    });
}

sub insert_av_err {
    my ($name, $table, $rows, $done) = @_;
    $ch->insert($table, $rows, sub {
        my (undef, $err) = @_;
        ok($err, "$name: insert rejected") or diag("unexpectedly accepted");
        $done->();
    });
}

sub insert_tsv_err {
    my ($name, $table, $tsv, $done) = @_;
    $ch->insert($table, $tsv, sub {
        my (undef, $err) = @_;
        ok($err, "$name: insert rejected") or diag("unexpectedly accepted");
        $done->();
    });
}

# --- EVCH-4: Enum labels ---

for my $case (['arrayref', [[5]]], ['arrayref string', [['5']]], ['tsv', "5\n"]) {
    my ($how, $data) = @$case;
    step("enum8 undeclared code $how", sub {
        my ($done) = @_;
        ddl('co_enumu', "e Enum8('undef' = 0, 'ok' = 1)", $done, sub {
            my $err_sub = ref $data ? \&insert_av_err : \&insert_tsv_err;
            $err_sub->("enum8 undeclared code $how", 'co_enumu (e)', $data, sub {
                drop_table('co_enumu', $done);
            });
        });
    });
}

step('enum8 labels arrayref', sub {
    my ($done) = @_;
    ddl('co_enum8', "e Enum8('undef' = 0, 'ok' = 1)", $done, sub {
        insert_av_ok('enum8 labels arrayref', 'co_enum8 (e)',
            [['ok'], ['undef'], [1], [0]], sub {
            check_rows('enum8 labels arrayref', 'select toString(e) from co_enum8 order by toString(e)',
                [['ok'], ['ok'], ['undef'], ['undef']], sub {
                drop_table('co_enum8', $done);
            });
        });
    });
});

step('enum8 labels tsv', sub {
    my ($done) = @_;
    ddl('co_enum8', "e Enum8('undef' = 0, 'ok' = 1)", $done, sub {
        insert_tsv_ok('enum8 labels tsv', 'co_enum8 (e)', "ok\n1\nundef\n0\n", sub {
            check_rows('enum8 labels tsv', 'select toString(e) from co_enum8 order by toString(e)',
                [['ok'], ['ok'], ['undef'], ['undef']], sub {
                drop_table('co_enum8', $done);
            });
        });
    });
});

step('enum8 numeric label wins arrayref', sub {
    my ($done) = @_;
    ddl('co_enum8n', "e Enum8('a' = 1, '1' = 2)", $done, sub {
        insert_av_ok('enum8 numeric label wins arrayref', 'co_enum8n (e)',
            [['1'], [1], ['a']], sub {
            check_rows('enum8 numeric label wins arrayref', 'select toString(e) from co_enum8n',
                [['1'], ['1'], ['a']], sub {
                drop_table('co_enum8n', $done);
            });
        });
    });
});

step('enum8 numeric label wins tsv', sub {
    my ($done) = @_;
    ddl('co_enum8n', "e Enum8('a' = 1, '1' = 2)", $done, sub {
        insert_tsv_ok('enum8 numeric label wins tsv', 'co_enum8n (e)', "1\n", sub {
            check_rows('enum8 numeric label wins tsv', 'select toString(e) from co_enum8n',
                [['1']], sub {
                drop_table('co_enum8n', $done);
            });
        });
    });
});

step('enum8 escaped labels arrayref', sub {
    my ($done) = @_;
    ddl('co_enum8e', "e Enum8('a''b' = 1, 'q\\\\z' = 2)", $done, sub {
        insert_av_ok('enum8 escaped labels arrayref', 'co_enum8e (e)',
            [["a'b"], ["q\\z"]], sub {
            check_rows('enum8 escaped labels arrayref', 'select toString(e) from co_enum8e order by e',
                [["a'b"], ["q\\z"]], sub {
                drop_table('co_enum8e', $done);
            });
        });
    });
});

step('enum8 escaped labels tsv', sub {
    my ($done) = @_;
    ddl('co_enum8e', "e Enum8('a''b' = 1, 'q\\\\z' = 2)", $done, sub {
        insert_tsv_ok('enum8 escaped labels tsv', 'co_enum8e (e)', "a'b\nq\\\\z\n", sub {
            check_rows('enum8 escaped labels tsv', 'select toString(e) from co_enum8e order by e',
                [["a'b"], ["q\\z"]], sub {
                drop_table('co_enum8e', $done);
            });
        });
    });
});

step('enum16 labels arrayref', sub {
    my ($done) = @_;
    ddl('co_enum16', "e Enum16('alpha' = 1000, 'beta' = -5)", $done, sub {
        insert_av_ok('enum16 labels arrayref', 'co_enum16 (e)',
            [['beta'], [-5], [1000]], sub {
            check_rows('enum16 labels arrayref', 'select toString(e) from co_enum16 order by toString(e)',
                [['alpha'], ['beta'], ['beta']], sub {
                drop_table('co_enum16', $done);
            });
        });
    });
});

step('enum16 labels tsv', sub {
    my ($done) = @_;
    ddl('co_enum16', "e Enum16('alpha' = 1000, 'beta' = -5)", $done, sub {
        insert_tsv_ok('enum16 labels tsv', 'co_enum16 (e)', "alpha\nbeta\n", sub {
            check_rows('enum16 labels tsv', 'select toString(e) from co_enum16 order by toString(e)',
                [['alpha'], ['beta']], sub {
                drop_table('co_enum16', $done);
            });
        });
    });
});

step('nullable enum arrayref', sub {
    my ($done) = @_;
    ddl('co_enumn', "e Nullable(Enum8('undef' = 0, 'ok' = 1))", $done, sub {
        insert_av_ok('nullable enum arrayref', 'co_enumn (e)', [['ok'], [undef]], sub {
            check_rows('nullable enum arrayref', 'select toString(e) from co_enumn',
                [['ok'], [undef]], sub {
                drop_table('co_enumn', $done);
            });
        });
    });
});

step('nullable enum tsv', sub {
    my ($done) = @_;
    ddl('co_enumn', "e Nullable(Enum8('undef' = 0, 'ok' = 1))", $done, sub {
        insert_tsv_ok('nullable enum tsv', 'co_enumn (e)', "ok\n\\N\n", sub {
            check_rows('nullable enum tsv', 'select toString(e) from co_enumn',
                [['ok'], [undef]], sub {
                drop_table('co_enumn', $done);
            });
        });
    });
});

step('array enum arrayref', sub {
    my ($done) = @_;
    ddl('co_enuma', "e Array(Enum8('undef' = 0, 'ok' = 1))", $done, sub {
        insert_av_ok('array enum arrayref', 'co_enuma (e)', [[['ok', 'undef']], [[]]], sub {
            check_rows('array enum arrayref', 'select toString(e) from co_enuma',
                [["['ok','undef']"], ['[]']], sub {
                drop_table('co_enuma', $done);
            });
        });
    });
});

step('enum rejects', sub {
    my ($done) = @_;
    ddl('co_enumr', "e Enum8('undef' = 0, 'ok' = 1)", $done, sub {
        insert_av_err('enum unknown label arrayref', 'co_enumr (e)', [['nope']], sub {
            insert_tsv_err('enum unknown label tsv', 'co_enumr (e)', "nope\n", sub {
                insert_av_err('enum8 code out of range', 'co_enumr (e)', [[200]], sub {
                    insert_tsv_err('enum trailing space tsv', 'co_enumr (e)', "ok \n", sub {
                        drop_table('co_enumr', $done);
                    });
                });
            });
        });
    });
});

# --- EVCH-5: Decimal exponent forms ---

step('decimal76 nv arrayref', sub {
    my ($done) = @_;
    ddl('co_dec76', 'd Decimal(7, 6)', $done, sub {
        insert_av_ok('decimal76 nv arrayref', 'co_dec76 (d)', [[0.000012]], sub {
            check_rows('decimal76 nv arrayref', 'select toString(d) from co_dec76',
                [['0.000012']], sub {
                drop_table('co_dec76', $done);
            });
        });
    });
});

step('decimal76 exponent strings arrayref', sub {
    my ($done) = @_;
    ddl('co_dec76', 'd Decimal(7, 6)', $done, sub {
        insert_av_ok('decimal76 exponent strings arrayref', 'co_dec76 (d)',
            [['1.2e-05'], ['+1e-3'], ['-.5e-1'], ['-1e-7']], sub {
            check_rows('decimal76 exponent strings arrayref', 'select toString(d) from co_dec76',
                [['0.000012'], ['0.001'], ['-0.05'], ['0']], sub {
                drop_table('co_dec76', $done);
            });
        });
    });
});

step('decimal76 exponent strings tsv', sub {
    my ($done) = @_;
    ddl('co_dec76', 'd Decimal(7, 6)', $done, sub {
        insert_tsv_ok('decimal76 exponent strings tsv', 'co_dec76 (d)',
            "1.2e-05\n.5e1\n", sub {
            check_rows('decimal76 exponent strings tsv', 'select toString(d) from co_dec76',
                [['0.000012'], ['5']], sub {
                drop_table('co_dec76', $done);
            });
        });
    });
});

step('decimal102 exponent forms arrayref', sub {
    my ($done) = @_;
    ddl('co_dec102', 'd Decimal(10, 2)', $done, sub {
        insert_av_ok('decimal102 exponent forms arrayref', 'co_dec102 (d)',
            [['1E+2'], ['1e2'], ['12e-2'], ['1.23456789e-2'], ['1.e2'], ['00.5e1']], sub {
            check_rows('decimal102 exponent forms arrayref', 'select toString(d) from co_dec102',
                [['100'], ['100'], ['0.12'], ['0.01'], ['100'], ['5']], sub {
                drop_table('co_dec102', $done);
            });
        });
    });
});

step('decimal102 exponent forms tsv', sub {
    my ($done) = @_;
    ddl('co_dec102', 'd Decimal(10, 2)', $done, sub {
        insert_tsv_ok('decimal102 exponent forms tsv', 'co_dec102 (d)',
            "1E+2\n12e-2\n.5e1\n", sub {
            check_rows('decimal102 exponent forms tsv', 'select toString(d) from co_dec102',
                [['100'], ['0.12'], ['5']], sub {
                drop_table('co_dec102', $done);
            });
        });
    });
});

step('decimal widths arrayref', sub {
    my ($done) = @_;
    ddl('co_decw', 'a Decimal(9, 2), b Decimal(18, 4), c Decimal(30, 10), d Decimal(50, 10)',
        $done, sub {
        insert_av_ok('decimal widths arrayref', 'co_decw (a, b, c, d)',
            [['1.5e1', '1E+2', '1.234567890123456789e5', '1.5e3']], sub {
            check_rows('decimal widths arrayref',
                'select toString(a), toString(b), toString(c), toString(d) from co_decw',
                [['15', '100', '123456.7890123456', '1500']], sub {
                drop_table('co_decw', $done);
            });
        });
    });
});

step('decimal widths tsv', sub {
    my ($done) = @_;
    ddl('co_decw', 'a Decimal(9, 2), b Decimal(18, 4), c Decimal(30, 10), d Decimal(50, 10)',
        $done, sub {
        insert_tsv_ok('decimal widths tsv', 'co_decw (a, b, c, d)',
            "1.5e1\t1E+2\t1.5e3\t1.5e-3\n", sub {
            check_rows('decimal widths tsv',
                'select toString(a), toString(b), toString(c), toString(d) from co_decw',
                [['15', '100', '1500', '0.0015']], sub {
                drop_table('co_decw', $done);
            });
        });
    });
});

step('nullable decimal arrayref', sub {
    my ($done) = @_;
    ddl('co_decn', 'd Nullable(Decimal(7, 6))', $done, sub {
        insert_av_ok('nullable decimal arrayref', 'co_decn (d)', [['1.2e-05'], [undef]], sub {
            check_rows('nullable decimal arrayref', 'select toString(d) from co_decn',
                [['0.000012'], [undef]], sub {
                drop_table('co_decn', $done);
            });
        });
    });
});

step('nullable decimal tsv', sub {
    my ($done) = @_;
    ddl('co_decn', 'd Nullable(Decimal(7, 6))', $done, sub {
        insert_tsv_ok('nullable decimal tsv', 'co_decn (d)', "1.2e-05\n\\N\n", sub {
            check_rows('nullable decimal tsv', 'select toString(d) from co_decn',
                [['0.000012'], [undef]], sub {
                drop_table('co_decn', $done);
            });
        });
    });
});

step('array decimal arrayref', sub {
    my ($done) = @_;
    ddl('co_deca', 'd Array(Decimal(9, 2))', $done, sub {
        insert_av_ok('array decimal arrayref', 'co_deca (d)', [[['1.5e1', '2.5']]], sub {
            check_rows('array decimal arrayref', 'select toString(d) from co_deca',
                [['[15,2.5]']], sub {
                drop_table('co_deca', $done);
            });
        });
    });
});

step('decimal rejects', sub {
    my ($done) = @_;
    ddl('co_decr', 'd Decimal(7, 6)', $done, sub {
        insert_av_err('decimal 0e999 arrayref', 'co_decr (d)', [['0e999']], sub {
            insert_av_err('decimal 1e400 arrayref', 'co_decr (d)', [['1e400']], sub {
                insert_av_err('decimal overflow arrayref', 'co_decr (d)', [['1e2']], sub {
                    insert_tsv_err('decimal 0e999 tsv', 'co_decr (d)', "0e999\n", sub {
                        insert_av_err('decimal garbage arrayref', 'co_decr (d)', [['abc']],
                            sub {
                            drop_table('co_decr', $done);
                        });
                    });
                });
            });
        });
    });
});

# --- EVCH-12: IPv4 dotted string into an IPv6 column ---

step('ipv6 mapped arrayref', sub {
    my ($done) = @_;
    ddl('co_ip', 'ip IPv6', $done, sub {
        insert_av_ok('ipv6 mapped arrayref', 'co_ip (ip)',
            [['1.2.3.4'], ['::1'], ['0.0.0.0'], ['::ffff:1.2.3.4']], sub {
            check_rows('ipv6 mapped arrayref', 'select toString(ip) from co_ip',
                [['::ffff:1.2.3.4'], ['::1'], ['::ffff:0.0.0.0'], ['::ffff:1.2.3.4']],
                sub {
                drop_table('co_ip', $done);
            });
        });
    });
});

step('ipv6 mapped tsv', sub {
    my ($done) = @_;
    ddl('co_ip', 'ip IPv6', $done, sub {
        insert_tsv_ok('ipv6 mapped tsv', 'co_ip (ip)', "1.2.3.4\n::1\n", sub {
            check_rows('ipv6 mapped tsv', 'select toString(ip) from co_ip',
                [['::ffff:1.2.3.4'], ['::1']], sub {
                drop_table('co_ip', $done);
            });
        });
    });
});

step('nullable ipv6 arrayref', sub {
    my ($done) = @_;
    ddl('co_ipn', 'ip Nullable(IPv6)', $done, sub {
        insert_av_ok('nullable ipv6 arrayref', 'co_ipn (ip)', [['1.2.3.4'], [undef]], sub {
            check_rows('nullable ipv6 arrayref', 'select toString(ip) from co_ipn',
                [['::ffff:1.2.3.4'], [undef]], sub {
                drop_table('co_ipn', $done);
            });
        });
    });
});

step('nullable ipv6 tsv', sub {
    my ($done) = @_;
    ddl('co_ipn', 'ip Nullable(IPv6)', $done, sub {
        insert_tsv_ok('nullable ipv6 tsv', 'co_ipn (ip)', "1.2.3.4\n\\N\n", sub {
            check_rows('nullable ipv6 tsv', 'select toString(ip) from co_ipn',
                [['::ffff:1.2.3.4'], [undef]], sub {
                drop_table('co_ipn', $done);
            });
        });
    });
});

step('array ipv6 arrayref', sub {
    my ($done) = @_;
    ddl('co_ipa', 'ip Array(IPv6)', $done, sub {
        insert_av_ok('array ipv6 arrayref', 'co_ipa (ip)', [[['1.2.3.4', '::1']]], sub {
            check_rows('array ipv6 arrayref', 'select toString(ip) from co_ipa',
                [["['::ffff:1.2.3.4','::1']"]], sub {
                drop_table('co_ipa', $done);
            });
        });
    });
});

step('ipv6 rejects', sub {
    my ($done) = @_;
    ddl('co_ipr', 'ip IPv6', $done, sub {
        insert_av_err('ipv6 short quad arrayref', 'co_ipr (ip)', [['1.2.3']], sub {
            insert_av_err('ipv6 octet overflow arrayref', 'co_ipr (ip)', [['256.1.1.1']],
                sub {
                insert_tsv_err('ipv6 short quad tsv', 'co_ipr (ip)', "1.2.3\n", sub {
                    drop_table('co_ipr', $done);
                });
            });
        });
    });
});

$ch = EV::ClickHouse->new(
    host       => $host,
    port       => $port,
    protocol   => 'native',
    on_connect => sub {
        my $run;
        $run = sub {
            my $s = shift @steps;
            unless ($s) {
                $ch->finish if $ch && $ch->is_connected;
                EV::break;
                return;
            }
            $s->($run);
        };
        $run->();
    },
    on_error => sub { diag("Error: $_[0]"); EV::break },
);
my $timeout = EV::timer(120, 0, sub { diag("timeout"); EV::break });
EV::run;

done_testing();
