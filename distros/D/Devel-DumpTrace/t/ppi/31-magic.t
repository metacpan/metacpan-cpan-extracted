package main;

use Test::More;
BEGIN {
  if (eval "use PPI;1") {
    plan tests => 8;
  } else {
    plan skip_all => "PPI not available\n";
  }
}
use strict;
use warnings;
use Devel::DumpTrace::PPI ':test';
use POSIX ();

system($^X, "-e", "exit 4");

my $status;
my $x = eval_and_display('$status = $?;', __LINE__, '__top__');
ok($x =~ m/\$\?:1024/, '$? value captured');
ok($x =~ m/status:1024/, '$? value assigned');

my @a = reverse(9 .. 11);
my $j;
my $x1 = eval_and_display('$, = ":";', __LINE__, '__top__');
my $x2 = eval_and_display('$j = join $,, @a;', __LINE__, '__top__');
ok($x1 =~ /\$,:['"]:['"]/, '$, value assigned');
ok($x2 =~ /\$,:['"]:['"]/, '$, value retrieved');
ok($x2 =~ /\$j:['"]11:10:9['"]/, '$, value employed');

my $t1 = $^T + 10;
my $t2;
my $x3 = eval_and_display('$t2 = $t1 - $^T ;', __LINE__, '__top__');
my ($t3) = $x3 =~ /\$t1:(\S+)/;
my ($t4) = $x3 =~ /\$\^T:(\S+)/;
my ($dt) = $x3 =~ /\$t2:(\S+)/;
ok($t3 == $t4 + 10, '$^T line evaluated correctly') or diag $x3;
ok($t4 == $^T, '$^T value accessed');
ok($t2 == $dt && $dt == 10, 'eval with $^T');

# evaluate a Perl statement
# returns the full output of Devel::DumpTrace::PPI
# for that statement's evaluation
#
# any lexical variables in $expr must be in scope
# inside this sub
sub eval_and_display {
    my ($expr, $line, $sub) = @_;
    save_pads(0);
    my $scalar = '';
    open my $fh, '>', \$scalar;
    local $Devel::DumpTrace::DUMPTRACE_FH = *$fh;

    evaluate_and_display_line($expr, __PACKAGE__, __FILE__, $line, $sub);
    eval $expr;
    diag $@ if $@;
    Devel::DumpTrace::handle_deferred_output($sub, __FILE__);
    close $fh;

    return $scalar;
}
