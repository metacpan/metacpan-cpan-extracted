use strict;
use warnings;

use List::Util qw/ sum /;
use Storable qw/
    freeze
    thaw
    /;
use Test::More;

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
    $skip && plan skip_all => sprintf 'without $ENV{%s}', $skip;
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
    my $client = _client();
    ok(my $sock = $client->_get_random_js_sock(), "get socket");
    _echo($sock);
};

subtest "worker echo request", sub {
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

    _echo($sock);
};

subtest "sum", sub {
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

done_testing();

sub _echo {
    my ($sock) = @_;
    ok(my $req = Gearman::Util::pack_req_command("echo_req"),
        "prepare echo req");
    my $len = length($req);
    ok(my $rv = $sock->write($req, $len), "write to socket");
    my $err;
    ok(my $res = Gearman::Util::read_res_packet($sock, \$err), "read respose");
    is(ref($res),    "HASH",     "respose is a hash");
    is($res->{type}, "echo_res", "response type");
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
