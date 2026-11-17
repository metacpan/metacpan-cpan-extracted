use strict;
use warnings;
use POSIX ();
use Test::More;
use Scalar::Util qw(weaken);
use EV;
use EV::mysql;

# 1. Deferred destruction inside on_error callback must not crash / leak
{
    my $weak_conn;
    my $err_seen;
    {
        my $m;
        $m = EV::mysql->new(
            host       => '127.0.0.1',
            port       => 1,
            user       => 'nouser',
            on_connect => sub { EV::break },
            on_error   => sub {
                $err_seen = $_[0];
                undef $m;
                EV::break;
            },
        );
        $weak_conn = $m;
        weaken($weak_conn);
        my $guard = EV::timer(5, 0, sub { EV::break });
        EV::run;
    }
    ok($err_seen, 'on_error fired when connecting to closed port');
    ok(!defined $weak_conn, 'connection freed cleanly after callback-triggered DESTROY');
}

# 2. Custom loop refcount kept alive until connection destroyed
{
    my $weak_loop;
    my $weak_conn;
    {
        my $loop = EV::Loop->new;
        $weak_loop = $loop;
        weaken($weak_loop);

        my $m = EV::mysql->new(loop => $loop, on_error => sub {});
        $weak_conn = $m;
        weaken($weak_conn);

        undef $loop;
        ok(defined $weak_loop, 'custom EV::Loop kept alive while EV::mysql holds reference');

        undef $m;
    }
    ok(!defined $weak_conn, 'EV::mysql destroyed');
    ok(!defined $weak_loop, 'custom EV::Loop released after EV::mysql DESTROY');
}

# 3. Socket fd state before connect and after finish
{
    my $m = EV::mysql->new(on_error => sub {});
    is($m->socket, -1, 'socket is -1 before connect');
    is($m->is_connected, 0, 'not connected before connect');
    is($m->is_connecting, 0, 'not connecting before connect');
    $m->finish;
    is($m->socket, -1, 'socket stays -1 after finish');
}

# 4. Fork safety in child process
{
    my $m = EV::mysql->new(on_error => sub {});
    my $pid = fork();
    SKIP: {
        skip 'fork unsupported', 1 unless defined $pid;
        if ($pid == 0) {
            eval { $m->skip_pending };
            $m->finish;
            POSIX::_exit($@ ? 1 : 0);
        }
        waitpid($pid, 0);
        is($? >> 8, 0, 'child exited cleanly after skip_pending/finish');
    }
}

done_testing;
