use Test::More tests => 3;
use strict;
use warnings;

# check output of Devel::DumpTrace module, compare with reference output.
# run code that uses a core module, and see if we are doing what
# we are supposed to about tracing through that core module

my $dmodule = "-d:DumpTrace::noPPI";

open T, '>', "$0.pl";
print T <<'EO_T;';

# test program for t/84-smoke.t, t/ppi/84-smoke.t

$rin = '';
$fileno = fileno(STDERR);
vec($rin, $fileno, 1) = 1;
my ($d, $e, $f) = (7, 8, $fileno);
1;

EO_T;

my $level = 3;
my $file = "$0.out.$level";
$ENV{DUMPTRACE_FH} = $file;
my $c1 = system($^X, $dmodule, "-Iblib/lib", "-Ilib", "$0.pl");

my $keep = $ENV{KEEP} || 0;

ok($c1 == 0, "ran level $level") or $keep++;

open XH, '<', $file;
my @xh = <XH>;
close XH;

ok($xh[2] =~ /\$rin:/ && $xh[2] =~ /\$fileno:/,
   "complex lvalue is evaluated") or $keep++;

ok($xh[3] =~ /\$d:/ && $xh[3] =~ /\$e:/ && $xh[3] =~ /\$f:/,
   "list lvalue is evaluated") or $keep++;

unlink $file unless $keep;
unlink "$0.pl";
