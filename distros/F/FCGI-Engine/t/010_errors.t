#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;
use Test::Moose;

BEGIN {
    use_ok('FCGI::Engine');
}

{
    package Foo;
    sub handler { ::pass("... handler was called") }
}

@ARGV = ();

dies_ok {
    FCGI::Engine->new_with_options;
} '... cant build class with out handler_class';

# dies_ok {
#     FCGI::Engine->new_with_options(
#         handler_class => 'Foo', 
#         handler_method => 'run'
#     );
# } '... cant have a handler method which is not supported by the handler class';

{
    my $e = FCGI::Engine->new_with_options(handler_class => 'Foo');
    isa_ok($e, 'FCGI::Engine');
    
    dies_ok {
        $e->pid_obj
    } '... cannot get a pid object if there is no pidfile specified';
}

@ARGV = ('--listen', '/tmp/foo.socket');

dies_ok {
    FCGI::Engine->new_with_options(handler_class => 'Foo');
} '... cant have socket but not pidfile';

push @ARGV => ('--pidfile', '/tmp/foo.pid');

{
    my $e = FCGI::Engine->new_with_options(handler_class => 'Foo');
    isa_ok($e, 'FCGI::Engine');
    
    ok($e->has_pidfile, '... we have a pidfile specified');
}


