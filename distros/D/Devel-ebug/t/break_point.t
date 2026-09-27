#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 34;
use Devel::ebug;

my $ebug = Devel::ebug->new;
$ebug->program("corpus/calc.pl");
$ebug->load;

# set break points at line numbers
is( $ebug->break_point(6), 6 );
is( $ebug->break_point(12), 12 );
$ebug->break_point(9);
is( $ebug->break_point(17), 18 ); # break on next breakable line
is( $ebug->break_point(19), undef ); # no more breakable lines
is_deeply([$ebug->break_points], [6, 9, 12, 18]);
$ebug->run;
is($ebug->line, 12);
$ebug->run;
is($ebug->line, 6);
$ebug->run;
is($ebug->line, 9);
is($ebug->pad->{'$e'}, 5);
$ebug->step;

# set break point at add()
$ebug = Devel::ebug->new;
$ebug->program("corpus/calc.pl");
$ebug->load;
is( $ebug->break_point_subroutine("main::add"), 12 );
$ebug->run;
is($ebug->line, 12);

# set break point at fib2()
$ebug = Devel::ebug->new;
$ebug->program("corpus/calc_oo.pl");
$ebug->load;
$ebug->break_point("corpus/lib/Calc.pm", 29);
is_deeply([$ebug->break_points], []);
is_deeply([$ebug->break_points("corpus/lib/Calc.pm")], [29]);
$ebug->run;
is($ebug->line, 29);
is($ebug->eval('$i'), 1);

# set break point at add()
$ebug = Devel::ebug->new;
$ebug->program("corpus/calc.pl");
$ebug->load;
$ebug->break_point(6, '$e == 4');
$ebug->break_point(7, '$e == 4');
$ebug->run;
is($ebug->line, 7);
is($ebug->eval('$e'), 4);

# set break point at fib2()
$ebug = Devel::ebug->new;
$ebug->program("corpus/calc_oo.pl");
$ebug->load;
$ebug->break_point("corpus/lib/Calc.pm", 29, '$i == 2');
is_deeply([$ebug->break_points_with_condition], []);
$ebug->break_point(11);
is_deeply([$ebug->break_points_with_condition("corpus/lib/Calc.pm")],
          [{filename => "corpus/lib/Calc.pm", line => 29, condition => '$i == 2'}]);
is_deeply([$ebug->all_break_points_with_condition],
          [
           {filename => "corpus/calc_oo.pl", line => 11},
          {filename => "corpus/lib/Calc.pm", line => 29, condition => '$i == 2'},
           ]) or diag explain [$ebug->all_break_points_with_condition];;
$ebug->run;
is($ebug->line, 29);
is($ebug->eval('$i'), 2);
is($ebug->eval('$x1'), 1);
is($ebug->eval('$x2'), 2);

# set break points at line numbers and delete one
$ebug = Devel::ebug->new;
$ebug->program("corpus/calc.pl");
$ebug->load;
$ebug->break_point(6);
$ebug->break_point(12);
$ebug->break_point(9);
$ebug->break_point_delete(6);
$ebug->break_point_delete("corpus/calc.pl", 12);
is_deeply([$ebug->break_points], [9]);
$ebug->run;
is($ebug->line, 9);
is($ebug->pad->{'$e'}, 5);
$ebug->step;


# a subroutine break point with a condition only stops when it is true;
# @_ holds the subroutine's arguments as it is entered
$ebug = Devel::ebug->new;
$ebug->program("corpus/calc_oo.pl");
$ebug->load;
is( $ebug->break_point_subroutine("Calc::fib1", '$_[1] == 3'), 15 );
is_deeply([$ebug->break_points_with_condition("corpus/lib/Calc.pm")],
          [{filename => "corpus/lib/Calc.pm", line => 15, condition => '$_[1] == 3'}]);
my @n;
for (1 .. 5) {
  $ebug->run;
  my($frame) = $ebug->stack_trace;
  push @n, ($frame->args)[1];
}
is_deeply(\@n, [3, 3, 3, 3, 3], 'stops only when the condition is true');
is($ebug->line, 15, 'at the start of the subroutine');

# a condition that is never true never stops
$ebug = Devel::ebug->new;
$ebug->program("corpus/calc.pl");
$ebug->load;
is( $ebug->break_point_subroutine("main::add", '$_[0] > 100'), 12 );
$ebug->run;
ok($ebug->finished, 'a subroutine break point whose condition is false is passed');

# and without a condition it still always stops
$ebug = Devel::ebug->new;
$ebug->program("corpus/calc.pl");
$ebug->load;
$ebug->break_point_subroutine("main::add");
$ebug->run;
is($ebug->line, 12, 'without a condition it always stops');
