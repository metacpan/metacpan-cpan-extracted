use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use IO::Select;
use POSIX qw(_exit);
use Scalar::Util qw(weaken);
use EV;
use EV::ClickHouse;

my @children;
END { kill 'TERM', @children if @children; waitpid($_, 0) for @children }
sub listener {
    IO::Socket::INET->new(LocalAddr => '127.0.0.1', Listen => 1, ReuseAddr => 1)
        or die $!;
}
sub child {
    my ($code) = @_;
    my $pid = fork // die $!;
    if (!$pid) { $SIG{PIPE} = 'IGNORE'; alarm 5; $code->(); _exit(0) }
    push @children, $pid;
}
sub reap {
    my $pid = pop @children;
    kill 'TERM', $pid;
    waitpid($pid, 0);
}
sub run_guarded {
    EV::now_update;
    my $guard = EV::timer(3, 0, sub { EV::break });
    EV::run;
}
sub drain_idle {
    my ($socket) = @_;
    my $select = IO::Select->new($socket);
    my $bytes = '';
    while ($select->can_read(.03)) {
        my $n = sysread($socket, my $part, 65536);
        last unless $n;
        $bytes .= $part;
    }
    return $bytes;
}
sub vu {
    my ($v) = @_;
    my $bytes = '';
    do { my $b = $v & 127; $v >>= 7; $bytes .= chr($b | ($v ? 128 : 0)) } while $v;
    return $bytes;
}
sub vstr { vu(length($_[0])) . $_[0] }
sub hello { "\x00" . vstr('mock') . vu(1) . vu(1) . vu(54492) . vstr('UTC') . vstr('mock') . vu(0) }

for my $finish (0, 1) {
    my $listener = listener();
    my $port = $listener->sockport;
    child(sub {
        my $socket = $listener->accept or return;
        drain_idle($socket);
        syswrite($socket, hello());
        select undef, undef, undef, .05;
        close $socket;
    });
    close $listener;
    my ($ch, @errors);
    $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $port, protocol => 'native', compress => 0,
        auto_reconnect => $finish,
        on_connect => sub { $ch->finish if $finish },
        on_disconnect => sub {
            my $cb = sub { push @errors, $_[1]; EV::break if @errors == 3 };
            $ch->query('select 1', $cb);
            $ch->insert('table', "1\n", $cb);
            $ch->ping($cb);
        },
        on_error => sub {},
    );
    run_guarded();
    is scalar(@errors), 3, $finish ? 'finish fails work queued by on_disconnect'
                                         : 'idle disconnect fails queued work without reconnect';
    ok !grep({ !defined($_) || !/closed|finished/ } @errors), 'every queued callback receives an error';
    is $ch->pending_count, 0, 'disconnect leaves no stranded query';
    $ch->finish;
    reap();
}

for my $len (11 .. 18, 10, 19) {
    my $input = substr('2024-05-01 12:30:45', 0, $len);
    my $listener = listener();
    my $port = $listener->sockport;
    child(sub {
        my $socket = $listener->accept or return;
        drain_idle($socket);
        syswrite($socket, hello());
        drain_idle($socket);
        my $sample = "\x01" . vstr('') . "\x00" . vu(1) . vu(0)
            . vstr('x') . vstr('DateTime64(3)') . "\x00";
        syswrite($socket, $sample);
        drain_idle($socket);
        syswrite($socket, "\x05");
        select undef, undef, undef, .1;
    });
    close $listener;
    my ($ch, $done, $error);
    $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $port, protocol => 'native', compress => 0,
        on_connect => sub {
            $ch->insert('table', [[$input]], sub { $done = 1; $error = $_[1]; EV::break });
        },
        on_error => sub {},
    );
    run_guarded();
    ok $done, "DateTime64 length $len completes";
    if ($len == 10 || $len == 19) {
        ok !defined($error), 'complete date or timestamp remains accepted';
    } else {
        like $error // '', qr/encoding failed/, 'partial timestamp is rejected';
    }
    $ch->finish;
    reap();
}

{
    package CancelValue;
    our $encodes = 0;
    use overload '""' => sub { $encodes++; '7' }, fallback => 1;
    package main;

    my $listener = listener();
    my $port = $listener->sockport;
    pipe(my $read, my $write) or die $!;
    child(sub {
        close $read;
        my $socket = $listener->accept or return;
        drain_idle($socket);
        syswrite($socket, hello());
        drain_idle($socket);
        select undef, undef, undef, .05;
        syswrite($socket, "\x01" . vstr('') . "\x00" . vu(1) . vu(0)
            . vstr('x') . vstr('UInt8') . "\x00");
        print {$write} unpack('H*', drain_idle($socket)), "\n";
        close $write;
        syswrite($socket, "\x05");
        select undef, undef, undef, .1;
    });
    close $listener;
    close $write;
    my ($ch, $done, $error, $cancel);
    $ch = EV::ClickHouse->new(
        host => '127.0.0.1', port => $port, protocol => 'native', compress => 0,
        on_connect => sub {
            $ch->insert('table', [[bless {}, 'CancelValue']], sub {
                $done = 1; $error = $_[1]; EV::break;
            });
            $cancel = EV::timer(.005, 0, sub { undef $cancel; $ch->cancel });
        },
        on_error => sub {},
    );
    run_guarded();
    ok $done, 'cancelled INSERT completes';
    like $error // '', qr/cancel/, 'cancelled INSERT reports an error';
    is scalar(<$read>), "03\n", 'sample block receives only CLIENT_CANCEL';
    is $CancelValue::encodes, 0, 'cancellation skips encoding stored values';
    close $read;
    $ch->finish;
    reap();
}

{
    my $weak;
    {
        my $loop = EV::Loop->new;
        $weak = $loop;
        weaken $weak;
        my $ch = EV::ClickHouse->new(loop => $loop);
        undef $loop;
        ok defined($weak), 'connection retains the only strong custom-loop reference';
    }
    ok !defined($weak), 'destroyed connection releases its custom loop';
}
done_testing;
