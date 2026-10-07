use strict;
use warnings;

use Test::More;
use IO::Socket::INET;

use EV;
use EV::Redis;

$SIG{PIPE} = 'IGNORE';

# per accepted connection, in order: 'close' drops it once a command arrives,
# 'silent' never answers, 'pong' answers each PING, 'sub' confirms a SUBSCRIBE
# to ch and publishes hello, 'subclose' confirms it and then drops the connection
sub fake_server {
    my @modes = @_;
    my $l = IO::Socket::INET->new(
        Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0, ReuseAddr => 1,
    ) or die "listen: $!";
    my %conns;
    my $accept = EV::io $l, EV::READ, sub {
        my $c = $l->accept or return;
        my $mode = shift(@modes) // 'silent';
        my $id = fileno $c;
        my $buf = '';
        $conns{$id} = [$c, EV::io $c, EV::READ, sub {
            my $n = sysread $c, $buf, 65536, length $buf;
            if (!$n || $mode eq 'close') { delete $conns{$id}; close $c; return }
            if ($mode eq 'pong') {
                my $k = () = $buf =~ /ping\r\n/gi;
                $buf = '';
                syswrite $c, "+PONG\r\n" x $k;
            }
            elsif ($mode =~ /^sub/ && $buf =~ /subscribe\r\n/i) {
                $buf = '';
                syswrite $c, "*3\r\n\$9\r\nsubscribe\r\n\$2\r\nch\r\n:1\r\n";
                if ($mode eq 'sub') {
                    syswrite $c, "*3\r\n\$7\r\nmessage\r\n\$2\r\nch\r\n\$5\r\nhello\r\n";
                }
                else {
                    $conns{"t$id"} = EV::timer 0.05, 0, sub { delete $conns{$id}; delete $conns{"t$id"}; close $c };
                }
            }
        }];
    };
    return { port => $l->sockport, keep => [$l, $accept, \%conns] };
}

# a callback that re-issues its command on every error, up to $cap times
sub run_retry {
    my (%a) = @_;
    my $srv = fake_server(@{ $a{modes} });
    my (@errors, @warnings, $result);
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $r;
    $r = EV::Redis->new(
        host => '127.0.0.1', port => $srv->{port}, on_error => sub {},
        %{ $a{opts} || {} },
    );
    my $cb; $cb = sub {
        my ($v, $e) = @_;
        if (defined $e) {
            push @errors, $e;
            $r->ping($cb) if @errors < 50;
            return;
        }
        $result = $v;
        EV::break;
    };
    $r->ping($cb);
    EV::now_update;
    my $guard = EV::timer $a{wait}, 0, sub { EV::break };
    EV::run;
    my $waiting = $r->waiting_count;
    $r->disconnect if $r->is_connected;
    undef $cb;
    return { errors => \@errors, warnings => \@warnings, result => $result, waiting => $waiting };
}

{
    my $o = run_retry(modes => ['close'], wait => 1);
    cmp_ok scalar @{ $o->{errors} }, '<=', 2, 'lost connection: a retry from the failing callback fails once more, not again and again';
    is $o->{errors}[0], 'Server closed the connection', 'lost connection: the first error';
    like "@{ $o->{warnings} }", qr/connection required/, 'lost connection: the next retry croaks';
}

{
    my $o = run_retry(modes => ['silent'], wait => 1, opts => { command_timeout => 200 });
    cmp_ok scalar @{ $o->{errors} }, '<=', 2, 'timeout: a retry from the failing callback fails once more, not again and again';
    is $o->{errors}[0], 'Timeout', 'timeout: the first error';
}

for my $first (qw(close silent)) {
    my $o = run_retry(modes => [$first, 'pong'], wait => 3, opts => {
        command_timeout => 200, reconnect => 1, reconnect_delay => 50,
        resume_waiting_on_reconnect => 1,
    });
    is scalar @{ $o->{errors} }, 1, "$first, reconnect+resume: one error";
    is $o->{result}, 'PONG', "$first, reconnect+resume: the retry waits for the next connection";
}

# a subscribe callback that subscribes again when the connection is lost
{
    my $srv = fake_server('subclose', 'sub');
    my (@errors, @msgs, $done);
    my $r;
    $r = EV::Redis->new(
        host => '127.0.0.1', port => $srv->{port}, on_error => sub {},
        reconnect => 1, reconnect_delay => 50, resume_waiting_on_reconnect => 1,
    );
    my $cb; $cb = sub {
        my ($m, $e) = @_;
        if (defined $e) {
            return if $done;
            push @errors, $e;
            $r->subscribe('ch', $cb) if @errors < 50;
            return;
        }
        push @msgs, $m->[2] if $m->[0] eq 'message';
        EV::break if @msgs;
    };
    $r->subscribe('ch', $cb);
    EV::now_update;
    my $guard = EV::timer 3, 0, sub { EV::break };
    EV::run;
    is scalar @errors, 1, 'resubscribe from the failing callback: one error';
    is_deeply \@msgs, ['hello'], 'resubscribe from the failing callback: subscribed on the next connection';
    $done = 1;
    $r->disconnect;
    undef $cb;
}

done_testing;
