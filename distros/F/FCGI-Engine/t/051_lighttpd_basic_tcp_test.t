#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize;
use Test::Moose;

use t::lib::utils;

my $lighttpd;
BEGIN {
    $lighttpd = utils::find_lighttpd();
    plan skip_all => "A lighttpd binary must be available for this test" unless $lighttpd;
    plan tests => 27;
    use_ok('FCGI::Engine');
}

use Cwd;
use File::Spec::Functions;

my $CWD                = Cwd::cwd;
$ENV{MX_DAEMON_STDOUT} = catfile($CWD, 'Out.txt');
$ENV{MX_DAEMON_STDERR} = catfile($CWD, 'Err.txt');

{
    package Counter;
    use Moose;

    my $count = 0;

    sub handler {
        print("Content-type: text/html\r\n\r\n");
        print(++$count);
    }
}

my $SOCKET  = ':10001';
my $PIDFILE = '/tmp/051_lighttpd_basic_tcp_test.pid';

@ARGV = (
    '--listen'  => $SOCKET,
    '--pidfile' => $PIDFILE,
    '--daemon'
);

my $e = FCGI::Engine->new_with_options(handler_class => 'Counter');
isa_ok($e, 'FCGI::Engine');
does_ok($e, 'MooseX::Getopt');

ok($e->is_listening, '... we are listening');
is($e->listen, $SOCKET, '... we have the right socket location');
ok(!Scalar::Util::blessed($e->listen), '... this is a socket, not a Path::Class::File');

is($e->nproc, 1, '... we have the default 1 proc');

ok($e->has_pidfile, '... we have a pidfile');
isa_ok($e->pidfile, 'MooseX::Daemonize::Pid::File');
is($e->pidfile->file, $PIDFILE, '... we have the right pidfile');

ok($e->should_detach, '... we should daemonize');

is($e->manager, 'FCGI::Engine::ProcManager', '... we have the default manager (FCGI::ProcManager)');
ok(!$e->has_pre_fork_init, '... we dont have any pre-fork-init');

unless ( fork ) {
    $e->run;
    exit;
}
else {
    sleep(1);    # 1 seconds should be enough for everything to happen

    ok(-f $PIDFILE, '... our pidfile was created');

    my $pid = $e->pidfile;
    isa_ok($pid, 'MooseX::Daemonize::Pid::File');

    ok($pid->is_running, '... our daemon is running (pid: ' . $pid->pid . ')');

    utils::start_lighttpd('t/lighttpd_confs/051_lighttpd_basic_tcp_test.conf');

    my $mech = Test::WWW::Mechanize->new;
    for (1 .. 5) {
        $mech->get_ok('http://localhost:3333/count', '... got the page okay');
        $mech->content_is($_, '... got the content we expected');
    }

    utils::stop_lighttpd();

    kill TERM => $pid->pid;

    sleep(1); # give is a moment to die ...

    ok(!$pid->is_running, '... our daemon is no longer running (pid: ' . $pid->pid . ')');

    unlink $SOCKET;
}

unlink $ENV{MX_DAEMON_STDOUT};
unlink $ENV{MX_DAEMON_STDERR};
