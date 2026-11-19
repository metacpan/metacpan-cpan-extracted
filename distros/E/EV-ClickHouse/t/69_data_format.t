use strict;
use warnings;
use Test::More;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;
my $hport = $ENV{TEST_CLICKHOUSE_PORT} || 8123;

require IO::Socket::INET;
my @protos = grep { IO::Socket::INET->new(PeerAddr => $host, PeerPort => $_->[1], Timeout => 2) }
    ([native => $nport], [http => $hport]);
plan skip_all => 'ClickHouse not reachable' unless @protos;

sub vu { my ($v) = @_; my $b = ''; do { my $c = $v & 127; $v >>= 7; $b .= chr($c | ($v ? 128 : 0)) } while $v; $b }
sub vstr { vu(length $_[0]) . $_[0] }

# Native format block: id UInt32, n Nullable(UInt8); NULL n takes the column DEFAULT.
my @ids = (1, 2, 3);
my @ns  = (undef, 5, undef);
my $native = vu(2) . vu(scalar @ids)
    . vstr('id') . vstr('UInt32') . pack('V*', @ids)
    . vstr('n') . vstr('Nullable(UInt8)')
    . join('', map { defined $_ ? "\0" : "\1" } @ns) . pack('C*', map { $_ // 0 } @ns);

sub wait_for {
    my ($start) = @_;
    my ($res, $err, $done);
    $start->(sub { ($res, $err) = @_; $done = 1; EV::break });
    EV::now_update;
    my $guard = EV::timer(15, 0, sub { $err //= 'timed out'; EV::break });
    EV::run until $done || $err;
    return ($res, $err);
}

for my $p (@protos) {
    my ($proto, $port) = @$p;
    for my $compress (0, 1) {
        my $tag = "$proto compress=$compress";
        my $ch = EV::ClickHouse->new(host => $host, port => $port, protocol => $proto,
                                     compress => $compress, on_error => sub { diag("error: $_[0]") });
        my $run = sub {
            my ($sql, @opt) = @_;
            my ($res, $err) = wait_for(sub { $ch->query($sql, @opt, $_[0]) });
            die "$sql: $err" if $err;
            $res;
        };
        my $ins = sub {
            my ($table, $data, $opt) = @_;
            my (undef, $err) = wait_for(sub { $ch->insert($table, $data, $opt, $_[0]) });
            $err;
        };
        $run->('drop table if exists me_fmt');
        $run->('create table me_fmt (id UInt32, n UInt8 default 9, d UInt32 default id + 100) engine = Memory');

        is($ins->('me_fmt (id, n)', $native,
                  { data_format => 'Native', input_format_null_as_default => 1 }),
           undef, "$tag: Native block");
        is($ins->('me_fmt (id, n)', qq{{"id":4,"n":null}\n{"id":5,"n":6}\n},
                  { data_format => 'JSONEachRow' }),
           undef, "$tag: JSONEachRow");
        is($ins->('me_fmt (id, n)', "6,\n", { data_format => 'CSV', input_format_csv_empty_as_default => 1 }),
           undef, "$tag: CSV with empty cell");
        is_deeply($run->('select id, n, d from me_fmt order by id'),
                  [[1, 9, 101], [2, 5, 102], [3, 9, 103], [4, 9, 104], [5, 6, 105], [6, 9, 106]],
                  "$tag: rows and column defaults");

        like($ins->('me_fmt (id, n)', "garbage", { data_format => 'Native' }) // '',
             qr/\S/, "$tag: malformed data is a server error");
        is_deeply($run->('select count() from me_fmt'), [[6]], "$tag: connection still usable");

        ok(!eval { $ch->insert('me_fmt', [[1, 2]], { data_format => 'Native' }, sub {}); 1 }
           && $@ =~ /pre-formatted string/, "$tag: arrayref data croaks");
        ok(!eval { $ch->insert('me_fmt', 'x', { data_format => 'Native; drop' }, sub {}); 1 }
           && $@ =~ /format name/, "$tag: bad format name croaks");

        $run->('drop table me_fmt');
        $ch->finish;
    }
}

done_testing;
