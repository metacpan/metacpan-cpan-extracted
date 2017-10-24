#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;
use Sub::Name;

run_in_debugger();

Devel::Chitin::TestDB->attach();
Devel::Chitin::TestDB->trace(1);

my $main_serial = $Devel::Chitin::stack_serial[0]->[-1];
my($in_sub, @serials);
my $anon = Sub::Name::subname 'foo' => sub {
    push @serials, $Devel::Chitin::stack_serial[-1]->[-1];
    $in_sub = 1;  # start testing here
    my @a = (1, 2, 3);
    (4, 5, 6);
    undef $in_sub;  # stop testing after this...
};
$anon->(7, 8, 9);
*anon = $anon;
anon('a', 'b', 'c');

package Devel::Chitin::TestDB;
use base 'Devel::Chitin';

BEGIN {
    if (Devel::Chitin::TestRunner::is_in_test_program) {
        eval "use Test::More tests => 9";
    }
}

sub notify_trace {
    return unless $in_sub;

    my($class, $loc) = @_;

    my $stackframe = $class->stack->frame(0);
    is($stackframe->serial, $serials[-1], 'serial matches');

    if (@serials == 2) {
        # We're in the second call
        isnt($stackframe->serial, $serials[0], 'second serial is different than first');
    }
}
