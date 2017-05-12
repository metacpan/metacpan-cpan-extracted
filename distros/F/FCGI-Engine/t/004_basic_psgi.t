#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Moose;

BEGIN {
    {
        local $@;
        eval "use Plack;";
        plan skip_all => "Plack is required for this test" if $@;
    }
    {
        local $@;
        eval "use IO::String;";
        plan skip_all => "IO::String is required for this test" if $@;
    }
    plan tests => 13;
    use_ok('FCGI::Engine::PSGI');
}

my $app = sub {
    [ 200, [ 'Content-type' => 'text/html' ], [ 'Hello World' ] ];
};

@ARGV = ();

my $e = FCGI::Engine::PSGI->new_with_options( app => $app );
isa_ok($e, 'FCGI::Engine::PSGI');
isa_ok($e, 'FCGI::Engine::Core');
does_ok($e, 'MooseX::Getopt');

ok(!$e->is_listening, '... we are not listening');
is($e->nproc, 1, '... we have the default 1 proc (but we are not using it)');
ok(!$e->has_pidfile, '... we have no pidfile');
ok(!$e->should_detach, '... we shouldnt daemonize');
is($e->manager, 'FCGI::Engine::ProcManager', '... we have the default manager (FCGI::Engine::ProcManager)');

ok(!$e->has_pre_fork_init, '... we dont have any pre-fork-init');

is($e->app, $app, '... and it is our app');

my $var;
eval {
    tie *STDOUT, 'IO::String' => $var;
    $e->run;
    untie( *STDOUT );
};
ok(!$@, '... we ran the handler okay') || warn $@;

is($var, "Status: 200\r\nContent-type: text/html\r\n\r\nHello World", '... got the expect output too');

