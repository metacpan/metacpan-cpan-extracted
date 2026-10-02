#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More 0.94 tests => 30;
use Devel::ebug;

# Detect the line number reporting behaviour of this version of perl
our $use_block_end;
BEGIN {
    sub X { my (undef, undef, $line) = caller;
                $use_block_end++ if ($line != shift); }
    X __LINE__, # $use_block_end = 0
    sub { }     # $use_block_end = 1
};

note "First we'll step over the subref";
my $ebug = Devel::ebug->new;
$ebug->program("corpus/calc_subref.pl");
$ebug->load;

# Let's step through the program, and check that we step through the
# lines in the right order
if ($use_block_end) {
    is($ebug->line, 7, "Next line is 7");
} else {
    is($ebug->line, 3, "Next line is 3");
}
is($ebug->filename, 'corpus/calc_subref.pl', 'Still in corpus/calc_subref.pl');
$ebug->next;
is($ebug->line, 9, "Next line is 9");
is($ebug->filename, 'corpus/calc_subref.pl', 'Still in corpus/calc_subref.pl');
$ebug->next;
is($ebug->line, 10, "Next line is 10");
is($ebug->filename, 'corpus/calc_subref.pl', 'Still in corpus/calc_subref.pl');
$ebug->next;
is($ebug->line, 11, "Next line is 11");
is($ebug->filename, 'corpus/calc_subref.pl', 'Still in corpus/calc_subref.pl');
$ebug->next;
is($ebug->line, 12, "Next line is 12");
is($ebug->filename, 'corpus/calc_subref.pl', 'Still in corpus/calc_subref.pl');
$ebug->next;
is($ebug->line, 13, "Next line is 13");
is($ebug->filename, 'corpus/calc_subref.pl', 'Still in corpus/calc_subref.pl');
$ebug->next;
is($ebug->line, 15, "Next line is 15");
is($ebug->filename, 'corpus/calc_subref.pl', 'Still in corpus/calc_subref.pl');
$ebug->next;

note "Now testing stepping into the subref";
$ebug = Devel::ebug->new;
$ebug->program("corpus/calc_subref.pl");
$ebug->load;

if ($use_block_end) {
    is($ebug->line, 7, "Next line is 7");
} else {
    is($ebug->line, 3, "Next line is 3");
}
is($ebug->filename, 'corpus/calc_subref.pl', 'Still in corpus/calc_subref.pl');
$ebug->step;
is($ebug->line, 9, "Next line is 9");
is($ebug->filename, 'corpus/calc_subref.pl', 'Still in corpus/calc_subref.pl');
$ebug->step;
is($ebug->line, 10, "Next line is 10");
is($ebug->filename, 'corpus/calc_subref.pl', 'Still in corpus/calc_subref.pl');
$ebug->step;
is($ebug->line, 11, "Next line is 11");
is($ebug->filename, 'corpus/calc_subref.pl', 'Still in corpus/calc_subref.pl');
$ebug->step;
is($ebug->line, 4, 'Inside of subref');
is($ebug->package, 'main', 'Still package main');
is($ebug->subroutine, 'main::__ANON__[corpus/calc_subref.pl:7]', 'ANON subref');
is($ebug->filename, 'corpus/calc_subref.pl', 'Still in corpus/calc_subref.pl');

note "Try a breakpoint in the subref";
$ebug = Devel::ebug->new;
$ebug->program("corpus/calc_subref.pl");
$ebug->load;
$ebug->break_point("corpus/calc_subref.pl", 4);
$ebug->run;
is($ebug->line, 4, 'Inside of subref');
is($ebug->package, 'main', 'Still package main');
is($ebug->subroutine, 'main::__ANON__[corpus/calc_subref.pl:7]', 'ANON subref');
is($ebug->filename, 'corpus/calc_subref.pl', 'Still in corpus/calc_subref.pl');

