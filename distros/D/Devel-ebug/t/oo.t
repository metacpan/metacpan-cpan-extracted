#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 12;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("t/calc_oo.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;

# Let's step through the program, and check that we step through the
# lines in the right order

is($ebug->line, 7);
is($ebug->filename, 't/calc_oo.pl');
$ebug->next;
is($ebug->line, 8);
is($ebug->filename, 't/calc_oo.pl');
$ebug->next;
is($ebug->line, 9);
is($ebug->filename, 't/calc_oo.pl');
$ebug->next;
is($ebug->line, 10);
is($ebug->filename, 't/calc_oo.pl');
$ebug->next;

$ebug = Devel::ebug->new;
$ebug->program("t/calc_oo.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;
$ebug->break_point_subroutine("Calc::add");
$ebug->run;
is($ebug->line, 9);
is($ebug->package, 'Calc');
is($ebug->subroutine, 'Calc::add');
is($ebug->filename, 't/Calc.pm');

