use strict;
use warnings;
use utf8;
use Test::More;
use lib 't/lib';
use TestMySQL;
use EV;
use EV::mysql;

eval "use Devel::Leak; 1"
    or plan skip_all => 'Devel::Leak required for SV leak stress test';
plan skip_all => 'No MySQL server' unless TestMySQL::server_available();

my %A = TestMySQL::connect_args();

my $loop = EV::Loop->new;
my $m = EV::mysql->new(
    loop       => $loop,
    %A,
    utf8       => 1,
    on_connect => sub { $loop->break },
    on_error   => sub { die "connect failed: $_[0]\n" },
);
$loop->run;

my $stmt_id;
$m->prepare('select ?, ?, ?, ?, ?', sub {
    my ($st, $err) = @_;
    die "prepare failed: $err\n" if $err;
    $stmt_id = $st;
    $loop->break;
});
$loop->run;

sub run_cycle {
    my ($n_q, $n_exec, $n_stream) = @_;

    my $q_done = 0;
    for my $i (1 .. $n_q) {
        $m->q("select $i as id, 'привет' as msg, null as nil union all select " . ($i + 1) . ", 'world', 'x'", sub {
            die "query failed: $_[1]" if $_[1];
            $loop->break if ++$q_done >= $n_q;
        });
    }
    $loop->run;

    my $e_done = 0;
    for my $i (1 .. $n_exec) {
        my $str = ($i % 2) ? 'short' : ('x' x 160);
        $m->execute($stmt_id, [$i, $str, undef, 3.25, 'юникод'], sub {
            die "execute failed: $_[1]" if $_[1];
            $loop->break if ++$e_done >= $n_exec;
        });
    }
    $loop->run;

    my $s_done = 0;
    my $next_stream;
    $next_stream = sub {
        $m->query_stream("select 1 as a, 'тест' as b union all select 2, null", sub {
            my ($row, $err) = @_;
            die "stream failed: $err" if $err;
            return if $row;
            if (++$s_done >= $n_stream) {
                $loop->break;
                return;
            }
            $next_stream->();
        });
    };
    $next_stream->();
    $loop->run;
}

# Warm up SV caches before measuring
run_cycle(20, 20, 10);

my $handle;
my $sv_before = Devel::Leak::NoteSV($handle);
run_cycle(300, 300, 100);
my $sv_after = Devel::Leak::NoteSV($handle);

my $delta = $sv_after - $sv_before;
note("Devel::Leak SV delta across 700 ops: $delta ($sv_before -> $sv_after)");
cmp_ok($delta, '<=', 20, 'no significant SV leak under query/execute/stream load');

$m->close_stmt($stmt_id, sub { $loop->break });
$loop->run;
$m->finish;

done_testing;
