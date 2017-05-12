#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;
run_in_debugger();

Devel::Chitin::TestDB->attach();

$DB::single=1;
13;
14;
15;

BEGIN{ if (is_in_test_program) {
    eval "use Test::More tests => 5";
}}

package Devel::Chitin::TestDB;
use base 'Devel::Chitin';

my $already_stopped = 0;
sub notify_stopped {
    my($db, $loc) = @_;
    if ($already_stopped++) {
        Test::More::ok(0, 'should not stop');
        exit;
    }
    Test::More::ok($db->trace(1), 'Turn on trace mode');
    Test::More::ok($db->step(), 'Turn on step mode');
    Test::More::ok(Devel::Chitin::Breakpoint->new(
        file => __FILE__,
        line => 14,
        code => 1),
        'Set unconditional breakpoint on line 14');

    Test::More::ok($db->disable_debugger, 'Disable debugger');
}

sub notify_trace {
    Test::More::ok(0, 'should not trace');
    exit;
}

sub notify_program_exit {
    Test::More::ok(0,' should not notify exit');
}

END {
    Test::More::ok(1,'Ran to the end') if (Devel::Chitin::TestRunner::is_in_test_program);
}
