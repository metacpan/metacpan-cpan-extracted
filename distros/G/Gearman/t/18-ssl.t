use strict;
use warnings;

use List::Util qw/ sum /;
use Storable qw/
    freeze
    thaw
    /;
use Test::More;
use Test::Timer;

use lib '.';
use t::Worker qw/ new_worker /;

BEGIN {
    use IO::Socket::SSL ();
    if (defined($ENV{SSL_DEBUG})) {
        $IO::Socket::SSL::DEBUG = $ENV{SSL_DEBUG};
    }
} ## end BEGIN

{
    my @env = qw/
        AUTHOR_TESTING
        SSL_GEARMAND_HOST
        SSL_GEARMAND_PORT
        SSL_CERT_FILE
        SSL_KEY_FILE
        /;
    my $skip;

    while (my $e = shift @env) {
        defined($ENV{$e}) && next;
        $skip = $e;
        last;
    }

    if ($skip) {
        plan skip_all => sprintf 'without $ENV{%s}', $skip;
    }
    else {
        plan tests => 7;
    }
}

my $debug = defined($ENV{SSL_DEBUG}) && $ENV{SSL_DEBUG};

my $job_server = {
    use_ssl   => 1,
    host      => $ENV{SSL_GEARMAND_HOST},
    port      => $ENV{SSL_GEARMAND_PORT},
    ca_file   => $ENV{SSL_CA_FILE},
    cert_file => $ENV{SSL_CERT_FILE},
    key_file  => $ENV{SSL_KEY_FILE},
    socket_cb => sub {
        my ($hr) = @_;

        # $hr->{SSL_cipher_list} = 'DEFAULT:!DH'; # 'ALL:!LOW:!EXP:!aNULL';
        if (defined($ENV{SSL_VERIFY_MODE})) {
            $hr->{SSL_verify_mode} = eval "$ENV{SSL_VERIFY_MODE}";
        }

        return $hr;
        }
};

use_ok("Gearman::Client");
use_ok("Gearman::Worker");

subtest "client echo request", sub {
    plan tests => 8;

    my $client = _client();
    ok(my $sock = $client->_get_random_js_sock(), "get socket");
    my $msg = "$$ client echo request";
    _echo($sock, $msg);
};

subtest "worker echo request", sub {
    plan tests => 8;

    my $worker = new_ok(
        "Gearman::Worker",
        [
            job_servers => [$job_server],
            debug       => $debug,
        ]
    );

    ok(
        my $sock = $worker->_get_js_sock(
            $worker->job_servers()->[0],
            on_connect => sub { return 1; }
        ),
        "get socket"
    ) || return;

    my $msg = "$$ worker echo request";
    _echo($sock, $msg);
};

subtest "sum", sub {
    plan tests => 2;

    my $func = "sum";
    my $cb   = sub {
        my $sum = 0;
        $sum += $_ for @{ thaw($_[0]->arg) };
        return $sum;
    };

    my $worker = new_worker(
        debug       => $debug,
        func        => { $func, $cb },
        job_servers => [$job_server],
    );

    my $client = _client();
    my @a      = map { int(rand(100)) } (0 .. int(rand(10) + 1));
    my $sum    = sum(@a);
    my $out    = $client->do_task(
        sum => freeze([@a]),
        {
            on_fail => sub { fail(explain(@_)) },
        }
    );
    is($$out, $sum, "do_task returned $sum for sum");
};

subtest "large work result", sub {
    plan tests => 3;

    # work result > 16k
    my $length = 1024 * int(rand(5) + 17);
    my $func   = "doit";
    my $worker = new_worker(
        job_servers => [$job_server],
        debug       => $ENV{DEBUG} || 0,
        func        => {
            $func,
            sub { return 'x' x $length }
        }
    );

    my $client = _client();
    ok(
        my $v = $client->do_task(
            $func => undef,
            {
                on_fail => sub { fail(explain(@_)) },
            }
        ),
        "$func"
    );
    is length(${$v}), $length;
};

subtest "large task data", sub {
    plan tests => 3;

    # task data > 16k
    my $length = 1024 * int(rand(5) + 17);
    my $func   = "doit";
    my $worker = new_worker(
        job_servers => [$job_server],
        debug       => $ENV{DEBUG} || 0,
        func        => {
            $func,
            sub { return length(shift->arg) }
        }
    );

    my $v      = 'x' x $length;
    my $client = _client();
    ok(
        my $r = $client->do_task(
            $func => $v,
            {
                on_fail => sub { fail(explain(@_)) },
            }
        ),
        "$func"
    );
    is ${$r}, length($v);
};

done_testing();

sub _echo {
    my ($sock, $msg) = @_;
    ok(my $req = Gearman::Util::pack_req_command("echo_req", $msg),
        "prepare echo req");
    my $len = length($req);
    ok(my $rv = $sock->write($req, $len), "write to socket");
    my $err;
    ok(my $res = Gearman::Util::read_res_packet($sock, \$err), "read respose");
    is(ref($res),            "HASH",     "respose is a hash");
    is($res->{type},         "echo_res", "response type");
    is(${ $res->{blobref} }, $msg,       "response blobref");
} ## end sub _echo

sub _client {
    return new_ok(
        "Gearman::Client",
        [
            debug       => $debug,
            exceptions  => 0,
            job_servers => [$job_server],
        ]
    );
} ## end sub _client
