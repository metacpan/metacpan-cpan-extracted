#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    if ($^O eq 'MSWin32') {
        plan skip_all => "Win32 can't run POE::Wheel::ReadLine";
    }
    else {
        eval q<
            use POE;
            use Term::Cap 1.10;
            use Term::ReadKey 2.21;
        >;
        plan skip_all => 'POE, Term::Cap, and Term::ReadKey required' if $@;
    }
}

plan tests => 4;

use IO::WrapOutput;
use POE;
use POE::Wheel::ReadLine;
use POE::Wheel::Run;
use POE::Wheel::ReadWrite;
use Symbol 'gensym';

POE::Session->create(
    package_states => [
        (__PACKAGE__) => [
            qw(
                _start
                run_child
                got_output
                got_child_output
                got_child_signal
                setup_readline
                got_user_input
                )
        ],
    ],
);

$poe_kernel->run;

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    diag('Testing CODE before wrapping output');
    $kernel->yield('run_child', sub { sleep 1; print "foo\n" });
}

sub run_child {
    my ($kernel, $heap, $program) = @_[KERNEL, HEAP, ARG0];

    my $child = POE::Wheel::Run->new(
        Program     => $program,
        StdoutEvent => 'got_child_output',
    );
    $kernel->sig_child($child->PID(), 'got_child_signal');
    $heap->{child} = $child;
}

sub got_child_output {
    my ($heap, $line) = @_[HEAP, ARG0];
    $heap->{got_foo} = 1 if $line =~ /foo/;
}

sub got_child_signal {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    TODO: {
        local $TODO = "A Term::ReadKey issue (#56486) might derail this test";
        ok($heap->{got_foo}, "Got output from child before it died");
    };

    delete $heap->{child};
    delete $heap->{got_foo};
    $heap->{children_done}++;

    if ($heap->{children_done} == 1) {
        diag('Testing program before wrapping output');
        $kernel->yield('run_child', [$^X, '-e', 'sleep 1; print "foo\n"']);
    }
    elsif ($heap->{children_done} == 2) {
        $kernel->yield('setup_readline');
        diag('Testing CODE after wrapping output');
        $kernel->yield('run_child', sub { sleep 1; print "foo\n" });
    }
    elsif ($heap->{children_done} == 3) {
        $kernel->yield('setup_readline');
        diag('Testing program after wrapping output');
        $kernel->yield('run_child', [$^X, '-e', 'sleep 1; print "foo\n"']);
    }
    elsif ($heap->{children_done} == 4) {
        unwrap_output();
        delete $heap->{console};
        delete $heap->{stderr_reader};
        delete $heap->{stdout_reader};
    }
}

sub setup_readline {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    $heap->{console} = POE::Wheel::ReadLine->new(
        InputEvent => 'got_user_input',
        PutMode    => 'immediate',
    );

    my ($stdout, $stderr) = wrap_output();

    $heap->{stderr_reader} = POE::Wheel::ReadWrite->new(
        Handle     => $stderr,
        InputEvent => 'got_output',
    );
    $heap->{stdout_reader} = POE::Wheel::ReadWrite->new(
        Handle     => $stdout,
        InputEvent => 'got_output',
    );

    $heap->{console}->get('');
    return;
}

sub got_output {
    my ($heap, $line) = @_[OBJECT, ARG0];
    $heap->{console}->put($line);
}

sub got_user_input {
    my ($heap, $line, $ex) = @_[HEAP, ARG0, ARG1];
    die if defined $ex && $ex eq 'interrupt';
}
