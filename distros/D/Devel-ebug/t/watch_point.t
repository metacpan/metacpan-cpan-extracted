#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 8;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("t/calc.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;

# just one watch point
$ebug->watch_point('$e == 4');
$ebug->run;
is($ebug->line, 7);
is($ebug->pad->{'$e'}, 4);

$ebug = Devel::ebug->new;
$ebug->program("t/calc.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;

# multiple watch points - they disappear
$ebug->watch_point('$e == 4');
$ebug->watch_point('$w > 0');
$ebug->watch_point('defined $c');
$ebug->run;
is($ebug->line, 5);
is($ebug->pad->{'$w'}, 2);
$ebug->run;
is($ebug->line, 14);
is($ebug->pad->{'$c'}, 3);
$ebug->run;
is($ebug->line, 7);
is($ebug->pad->{'$e'}, 4);
