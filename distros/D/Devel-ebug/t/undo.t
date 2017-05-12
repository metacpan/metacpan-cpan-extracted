#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 21;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("t/calc.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;

is($ebug->line, 3);
is($ebug->subroutine, "main");
is($ebug->package, "main");
is($ebug->filename, "t/calc.pl");
$ebug->step;
is($ebug->line, 4);
$ebug->step;
is($ebug->line, 5);
$ebug->undo;
is($ebug->line, 4);
$ebug->undo;
is($ebug->line, 3);

$ebug->break_point(6);
$ebug->break_point(12);
$ebug->break_point(9);

$ebug->undo;
is_deeply([$ebug->break_points], [6, 12]);
is($ebug->line, 3);
is($ebug->subroutine, "main");
is($ebug->package, "main");
is($ebug->filename, "t/calc.pl");
$ebug->run;
is($ebug->line, 12);
$ebug->run;
is($ebug->line, 6);
$ebug->step;
$ebug->step;
is($ebug->pad->{'$e'}, 5);

$ebug->undo;
is($ebug->line, 7);
is($ebug->subroutine, "main");
is($ebug->package, "main");
is($ebug->filename, "t/calc.pl");
is($ebug->pad->{'$e'}, 4);
