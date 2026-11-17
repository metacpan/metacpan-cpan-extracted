use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMySQL;
use EV;
use EV::mysql;

plan skip_all => 'No MySQL/MySQL server' unless TestMySQL::server_available();

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

my $m = EV::mysql->new(on_error => sub { die "connection: $_[0]\n" });
await_op(sub {
    $m->on_connect($_[0]);
    my %a = TestMySQL::connect_args();
    $m->connect(@a{qw(host user password database port)}, $a{unix_socket});
});

my $name = "ev_release_call_$$";
my (undef, $create_error) = await_op(sub {
    $m->query("create procedure $name(fail_later int) begin select 'first' as value; select sleep(0.2); if fail_later then signal sqlstate '45000' set message_text = 'secondary result failed'; end if; end", $_[0]);
});
if ($create_error) {
    $m->finish;
    plan skip_all => "cannot create test procedure: $create_error";
}

my $test_error;
eval {
    my ($stmt, $err) = await_op(sub { $m->prepare("call $name(?)", $_[0]) });
    die $err if $err;
    for my $failed (0, 0, 1, 0) {
        my ($rows, $fields, $exec_error);
        my ($ok, $ping_error) = await_op(sub {
            my $done = $_[0];
            $m->execute($stmt, [$failed], sub {
                ($rows, $exec_error, $fields) = @_;
                $m->ping($done);
            });
        });
        if ($failed) {
            like($exec_error, qr/secondary result failed/, 'secondary error reaches execute callback');
            is($rows, undef, 'failed CALL supplies no rows');
        } else {
            is($exec_error, undef, 'prepared CALL succeeds');
            is_deeply($rows, [['first']], 'first result is preserved');
            is_deeply($fields, ['value'], 'first result metadata is preserved');
        }
        ok($ok && !$ping_error, 'ping chained from CALL callback succeeds') or diag($ping_error // '');
    }
    await_op(sub { $m->close_stmt($stmt, $_[0]) });

    my $c = EV::mysql->new(on_error => sub { die "connection: $_[0]\n" });
    await_op(sub {
        $c->on_connect($_[0]);
        my %a = TestMySQL::connect_args();
        $c->connect(@a{qw(host user password database port)}, $a{unix_socket});
    });
    my ($cancel_stmt, $prepare_error) = await_op(sub { $c->prepare("call $name(?)", $_[0]) });
    die $prepare_error if $prepare_error;
    my $calls = 0;
    my ($cancel_rows, $cancel_error) = await_op(sub {
        my $done = $_[0];
        $c->query("select 1", sub { $c->finish });
        $c->execute($cancel_stmt, [0], sub { $calls++; $done->(@_) });
    });
    is($calls, 1, 'cancelled CALL fires once');
    is($cancel_rows, undef, 'cancelled CALL supplies no rows');
    like($cancel_error, qr/connection finished/, 'cancelled CALL delivers teardown error');
    is($c->pending_count, 0, 'cancelled CALL leaves no pending callback');
    ok(!$c->is_connected, 'cancelled CALL releases the connection');
    1;
} or $test_error = $@;

my (undef, $drop_error) = await_op(sub { $m->query("drop procedure $name", $_[0]) });
ok(!$drop_error, 'test procedure removed');
$m->finish;
die $test_error if $test_error;

done_testing;
