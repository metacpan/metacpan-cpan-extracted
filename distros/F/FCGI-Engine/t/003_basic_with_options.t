#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Test::Moose;

BEGIN {
    use_ok('FCGI::Engine');
}

{
    package Foo;
    sub dispatcher {
        if (@_ == 3 && $_[0] eq 'Foo' && $_[1] eq 'q') {
            ::pass("... dispatcher was called");
        }
        else {
            ::fail("... dispatcher was called with wrong args");
        }
    }
}

@ARGV = ();

my $e = FCGI::Engine->new_with_options(
    handler_class        => 'Foo',
    handler_method       => 'dispatcher',
    handler_args_builder => sub { (q => CGI::Simple->new) },
    nproc                => 10,
);
isa_ok($e, 'FCGI::Engine');
does_ok($e, 'MooseX::Getopt');

ok(!$e->is_listening, '... we are not listening');
is($e->nproc, 10, '... we have the default 1 proc (but we are not using it)');
ok(!$e->has_pidfile, '... we have no pidfile');
ok(!$e->should_detach, '... we shouldnt daemonize');
is($e->manager, 'FCGI::Engine::ProcManager', '... we have the default manager (FCGI::Engine::ProcManager)');

ok(!$e->has_pre_fork_init, '... we dont have any pre-fork-init');

is($e->handler_class, 'Foo', '... we have a handler class');
is($e->handler_method, 'dispatcher', '... we have our default handler method');

my $handler_args_builder = $e->handler_args_builder;
is(ref $handler_args_builder, 'CODE', '... default handler args is an CODE ref');

my $handler_args = [ $handler_args_builder->() ]; 
is($handler_args->[0], 'q', '... got our right default arg');
isa_ok($handler_args->[1], 'CGI::Simple', '... default arg isa CGI::Simple');


eval { $e->run }; 
ok(!$@, '... we ran the handler okay');


