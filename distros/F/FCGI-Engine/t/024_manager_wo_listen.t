#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::Moose;

BEGIN {
    use_ok('FCGI::Engine');
}

{

    package Foo;
    sub handler { ::pass("... handler was called") }
}

{

    package Foo::Manager;
    use Moose;
    extends qw(FCGI::Engine::ProcManager);

    our @CALLSTACK = ();

    sub manage { push @CALLSTACK, 'manage'; }
}

{
    @Foo::Manager::CALLSTACK = ();
    my $e = FCGI::Engine->new_with_options(
        handler_class => 'Foo',
        manager       => 'Foo::Manager',
    );
    is( $e->nproc,       1,              '... we have the default 1 proc' );
    is( $e->manager,     'Foo::Manager', '... we have the custom manager (Foo::Manager)' );
    is( $e->use_manager, 0,              '... we have the default value 0 for use_manager attribute' );

    eval { $e->run };
    ok( !$@, '... we ran the handler okay' );

    is( scalar(@Foo::Manager::CALLSTACK), 0, '... having 1 proc does not use the Manager' );
}

{
    @Foo::Manager::CALLSTACK = ();
    my $e = FCGI::Engine->new_with_options(
        handler_class => 'Foo',
        manager       => 'Foo::Manager',
        nproc         => 2,
        pidfile       => '/tmp/024_manager_wo_listen.pid',
        use_manager   => 1
    );
    is( $e->nproc,       2,              '... we have the custom 2 proc' );
    is( $e->manager,     'Foo::Manager', '... we have the custom manager (Foo::Manager)' );
    is( $e->use_manager, 1,              '... we have the custom value 1 for use_manager attribute' );

    eval { $e->run };
    ok( !$@, '... we ran the handler okay' );

    is_deeply( \@Foo::Manager::CALLSTACK, [qw(manage)], '... having more than 2 procs uses the Manager' );
}
