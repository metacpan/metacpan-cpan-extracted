#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 29;
use Devel::ebug;
use File::Spec;

my $ebug = Devel::ebug->new;
$ebug->program("corpus/calc.pl");
$ebug->load;

my @trace = $ebug->stack_trace;
is(scalar(@trace), 0);
$ebug->break_point(12);

$ebug->run;
@trace = $ebug->stack_trace;
is(scalar(@trace), 1);

# use YAML; warn Dump \@trace;

my $trace = $trace[0];
is($trace->package   , "main");
is($trace->filename , File::Spec->catfile('corpus','calc.pl'), "trace is on correct file name");
is($trace->subroutine, "main::add");
ok(! $trace->wantarray ); # Forced boolean context
is($trace->line      , 5);
is_deeply([$trace->args], [1, 2]);

@trace = $ebug->stack_trace_human;
is(scalar(@trace), 1);
is($trace[0], 'add(1, 2)');

$ebug = Devel::ebug->new;
$ebug->program("corpus/calc_oo.pl");
$ebug->load;
$ebug->break_point("corpus/lib/Calc.pm", 19);

$ebug->run;
@trace = $ebug->stack_trace_human;
is(scalar(@trace), 1);
like($trace[0], qr{^Calc::fib1\("Calc=HASH\(.*\)", 15\)});

$ebug->run;
@trace = $ebug->stack_trace_human;
is(scalar(@trace), 2);
like($trace[1], qr{^Calc::fib1\("Calc=HASH\(.*\)", 15\)$});
like($trace[0], qr{^fib1\("Calc=HASH\(.*\)", 14\)$});

$ebug = Devel::ebug->new;
$ebug->program("corpus/koremutake.pl");
$ebug->load;

$ebug->step;
@trace = $ebug->stack_trace_human;
is(scalar(@trace), 1);
is($trace[0], 'String::Koremutake->new()');

$ebug = Devel::ebug->new;
$ebug->program("corpus/koremutake.pl");
$ebug->load;
$ebug->break_point_subroutine("String::Koremutake::integer_to_koremutake");

$ebug->run;
@trace = $ebug->stack_trace_human;
is(scalar(@trace), 1);
like($trace[0], qr{^String::Koremutake::integer_to_koremutake\("String::Koremutake=HASH\(.*\)", 65535\)$});

$ebug = Devel::ebug->new;
$ebug->program("corpus/stack.pl");
$ebug->load;
$ebug->break_point_subroutine("main::show");

$ebug->run;
@trace = $ebug->stack_trace_human;
is(scalar(@trace), 1);
is($trace[0], 'show()');

$ebug->run;
@trace = $ebug->stack_trace_human;
is($trace[0], 'show(1, undef, 2)');

$ebug->run;
@trace = $ebug->stack_trace_human;
is($trace[0], 'show(123)');

$ebug->run;
@trace = $ebug->stack_trace_human;
is($trace[0], 'show(-0.3)');

$ebug->run;
@trace = $ebug->stack_trace_human;
is($trace[0], "show('a')");

$ebug->run;
@trace = $ebug->stack_trace_human;
is($trace[0], 'show("orange o rama")');

$ebug->run;
@trace = $ebug->stack_trace_human;
like($trace[0], qr{^show\("ARRAY\(.*\)"\)$});

$ebug->run;
@trace = $ebug->stack_trace_human;
like($trace[0], qr{^show\("HASH\(.*\)"\)$});

$ebug->run;
@trace = $ebug->stack_trace_human;
like($trace[0], qr{^show\("String::Koremutake=HASH\(.*\)"\)});

# use YAML; warn Dump \@trace;


