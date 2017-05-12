#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 13;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("t/calc_oo.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;

$ebug->break_point_subroutine("Calc::add");
$ebug->run;
is($ebug->line, 9);
is($ebug->subroutine, 'Calc::add');
is($ebug->filename, 't/Calc.pm');
$ebug->return();

is($ebug->pad->{'$r'}, 15);
is($ebug->line, 9);
is($ebug->subroutine, 'main');
is($ebug->filename, 't/calc_oo.pl');

$ebug = Devel::ebug->new;
$ebug->program("t/calc_oo.pl");
$ebug->backend("$^X bin/ebug_backend_perl");
$ebug->load;

$ebug->break_point_subroutine("Calc::add");
$ebug->run;
is($ebug->line, 9);
is($ebug->subroutine, 'Calc::add');
$ebug->return(3.141);
TODO: {
  local $TODO = 'Hmm... I broke the return...';
  is($ebug->pad->{'$r'}, 3.141);
}
is($ebug->line, 9);
is($ebug->subroutine, 'main');
is($ebug->filename, 't/calc_oo.pl');

