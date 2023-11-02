#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use Test::More 'no_plan';

sub run_test {
    my(undef, $a, $b) = @_;
    $a + $b;
}

sub forked_pid {
    $$;
}

return 1 if caller;

use Doit;

my $d = Doit->init;
my $fork = $d->do_fork;
isa_ok $fork, 'Doit::Fork';
is $fork->qx($^X, "-e", 'print 1+1, "\n"'), "2\n", "run external command in fork";
is $fork->call_with_runner('run_test', 2, 2), 4, "run function in fork";
isnt $fork->call_with_runner('forked_pid'), $$, 'forked process is really another process';
is $fork->{pid}, $fork->call_with_runner('forked_pid'), '$fork->{pid} with expected value';

__END__
