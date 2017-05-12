#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 9;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("t/calc.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;
$ebug->break_point(6);
$ebug->run;
is($ebug->line, 6);
is($ebug->eval('$e'), 3);
is_deeply([$ebug->eval('$e')], [3, 0]);
my $exception = $ebug->eval('die 123');
like($exception, qr/^123 at \(eval \d+\)/);
my @exception = $ebug->eval('die 123');
is($exception[1], 1); # no like_deeply
like($exception[0], qr/^123 at \(eval \d+\)/);
$ebug->step;
is($ebug->eval('$e'), 4);
$ebug->step;
is($ebug->eval('$e'), 5);
is($ebug->yaml('$e'), "--- 5\n");
