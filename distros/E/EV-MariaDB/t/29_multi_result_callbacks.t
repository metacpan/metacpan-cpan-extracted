use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
use EV;
use EV::MariaDB;

plan skip_all => 'No MariaDB/MySQL server' unless TestMariaDB::server_available();

sub await_op {
    my ($start) = @_;
    my ($done, @result);
    $start->(sub { @result = @_; $done = 1; EV::break });
    unless ($done) {
        my $guard = EV::timer(10, 0, sub { EV::break });
        EV::run;
    }
    die "operation timed out\n" unless $done;
    return @result;
}

my @errors;
my $m = EV::MariaDB->new(multi_statements => 1,
    on_error => sub { push @errors, $_[0] });
await_op(sub {
    $m->on_connect($_[0]);
    my %a = TestMariaDB::connect_args();
    $m->connect(@a{qw(host user password database port)}, $a{unix_socket});
});

for my $method (qw(query query_stream)) {
    for my $case (
        ['SELECT 1 AS value; SELECT SLEEP(0.05)', 0],
        ['DO 1; SELECT SLEEP(0.05)', 0],
        ['SELECT 1 AS value; DO 1', 0],
        ['SELECT 1 AS value; SELECT missing_release_column', 1],
    ) {
        @errors = ();
        my ($calls, $first, $query_error, $fields, @stream_rows);
        my ($ok, $ping_error) = await_op(sub {
            my $done = $_[0];
            $m->$method($case->[0], sub {
                ($first, $query_error, $fields) = @_;
                if ($method eq 'query_stream' && defined $first) {
                    push @stream_rows, $first;
                    return;
                }
                $calls++;
                $m->ping($done);
            });
        });
        is($query_error, undef, "$method preserves first-result success");
        if ($case->[0] =~ /^SELECT/) {
            is_deeply($method eq 'query' ? $first : \@stream_rows,
                [[1]], "$method preserves the first rows");
            is_deeply($fields, ['value'], 'query preserves first-result fields')
                if $method eq 'query';
        }
        is($calls, 1, "$method completes once");
        ok($ok && !$ping_error, "$method allows ping from completion callback")
            or diag($ping_error // '');
        is(scalar @errors, $case->[1], "$method reports secondary errors through on_error");
        my ($rows, $err) = await_op(sub { $m->q('SELECT 99', $_[0]) });
        ok(!$err && $rows->[0][0] == 99, "$method keeps the connection usable");
        is($m->pending_count, 0, "$method clears pending callbacks");
    }

    my ($cancel_timer, $calls);
    my ($rows, $err) = await_op(sub {
        my $done = $_[0];
        $m->$method('SELECT 1; SELECT SLEEP(0.2)', sub {
            return if $method eq 'query_stream' && defined $_[0];
            $calls++;
            $done->(@_);
        });
        $cancel_timer = EV::timer(0.05, 0, sub { $m->finish });
    });
    undef $cancel_timer;
    is($calls, 1, "$method cancellation fires once");
    is($rows, undef, "$method cancellation supplies no rows");
    like($err, qr/connection finished/, "$method cancels during result drain");
    is($m->pending_count, 0, "$method cancellation clears pending callbacks");
    await_op(sub { $m->on_connect($_[0]); $m->reset });
}

my $control = EV::MariaDB->new(on_error => sub { die "connection: $_[0]\n" });
await_op(sub {
    $control->on_connect($_[0]);
    my %a = TestMariaDB::connect_args();
    $control->connect(@a{qw(host user password database port)}, $a{unix_socket});
});
my ($id) = await_op(sub { $m->q('SELECT CONNECTION_ID()', $_[0]) });
@errors = ();
my ($killer, $kill_error);
my ($rows, $err) = await_op(sub {
    my $done = $_[0];
    my ($primary_done, $kill_done, @result);
    $m->q("SELECT 1; SELECT SLEEP(0.3), REPEAT('x', 524288)", sub {
        @result = @_; $primary_done = 1;
        $done->(@result) if $kill_done;
    });
    $killer = EV::timer(0.1, 0, sub {
        $control->q('KILL ' . $id->[0][0], sub {
            $kill_error = $_[1]; $kill_done = 1;
            $done->(@result) if $primary_done;
        });
    });
});
undef $killer;
is_deeply($rows, [[1]], 'first result survives loss during a secondary result');
is($err, undef, 'primary callback stays successful');
is($kill_error, undef, 'test connection was killed');
is(scalar @errors, 1, 'secondary connection loss reaches on_error once');
like($errors[0], qr/connection|server|killed/i, 'secondary error preserves the connection loss');
ok(!$m->is_connected, 'connection loss reflected by accessor');
is($m->pending_count, 0, 'connection loss leaves no pending callbacks');
$control->finish;
$m->finish;
done_testing;
