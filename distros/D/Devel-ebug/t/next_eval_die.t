#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 9;
use Devel::ebug;

# regression test for gh#26: 'next' losing control of the debuggee
# after stepping over a sub whose call chain dies internally and
# catches it with its own eval {} (as eg. Tk widgets routinely do for
# feature detection). Before the fix, DB::sub's cleanup was skipped
# for the frame that actually died, corrupting the internal call
# stack and leaving the debugger unable to stop again - so the script
# would run to completion (or hang, in Tk's case) instead of stopping
# on each subsequent line.

my $ebug = Devel::ebug->new;
$ebug->program("corpus/eval_die.pl");
$ebug->load;

is($ebug->finished, 0);
is($ebug->line, 3);
$ebug->next;

is($ebug->finished, 0);
is($ebug->line, 4);
$ebug->next; # steps over outer(), whose call chain dies and catches it internally

is($ebug->finished, 0);
is($ebug->line, 5);
$ebug->next;

is($ebug->finished, 0);
is($ebug->line, 6);
$ebug->next;

is($ebug->finished, 1);
