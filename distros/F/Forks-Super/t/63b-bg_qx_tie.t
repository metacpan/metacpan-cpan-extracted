use Forks::Super ':test';
use Test::More tests => 46;
use strict;
use warnings;

sub hex_enc{join'', map {sprintf"%02x",ord} split//,shift} # for debug
$ENV{TEST_LENIENT} = 1 if $^O =~ /freebsd|midnightbsd/;

if (${^TAINT}) {
    $ENV{PATH} = "";
    ($^X) = $^X =~ /(.*)/;
}

### list context ###

my $t = Time::HiRes::time();
tie my @x, &BG_QX,
    "$^X t/external-command.pl -e=Hello -n -s=2 -e=World -n -s=2 "
    . "-e=\"it is a\" -n -e=beautiful -n -e=day";
my @tests = @x;
$t = Time::HiRes::time() - $t;
ok($tests[0] eq "Hello \n" && $tests[1] eq "World \n", "list bg_qx");
ok(@tests == 5, "list bg_qx");
ok($t >= 3.25, "list bg_qx took ${t}s expected ~4s"); ### 3 ### obs 3.27

# exercise array operations on the tie'd @x variable to make sure
# we implemented everything correctly 

my $n = @x;
my $u = shift @x;
ok($u eq "Hello \n" && @x == $n - 1, "list bg_qx shift");
$u = pop @x;
ok(@x == $n - 2 && $u =~ /day/, "list bg_qx pop");
unshift @x, "asdf";
ok(@x == $n - 1, "list bg_qx unshift");
push @x, "qwer", "tyuiop";
ok(@x == $n + 1, "list bg_qx push");
splice @x, 3, 3, "pq";
ok(@x == $n - 1 && $x[3] eq "pq", "list bg_qx splice");
$x[3] = "rst";
ok(@x == $n - 1 && $x[3] eq "rst", "list bg_qx store");
ok($x[2] =~ /it is a/, "list bg_qx fetch");
delete $x[4];
ok(!defined $x[4], "list bg_qx delete");
@x = ();
ok(@x == 0, "list bg_qx clear");

### partial output ###

$t = Time::HiRes::time();
tie @x, &BG_QX, 
    "$^X t/external-command.pl -e=Hello -n -s=1 -e=World -s=12 -n "
    . "-e=\"it is a\" -n -e=beautiful -n -e=day", 
    { timeout => 6 };
@tests = @x;
$t = Time::HiRes::time() - $t;
ok($tests[0] eq "Hello \n", "list bg_qx first line ok");
ok($tests[1] eq "World \n" || $tests[1] eq "World ",
    "list bg_qx second line ok");                            ### 14 ###
ok(@tests == 2, "list bg_qx interrupted output had " 
	        . scalar @tests . "==2 lines");              ### 15 ###
if (@tests>2) {
  print STDERR "output was:\n", @tests, "\n";
}
ok($t >= 4.9 && $t < 11.9,
	"list bg_qx took ${t}s expected ~6-8s");             ### 16 ### obs 4.92

my $t2 = Time::HiRes::time();
my $z = sprintf "%05d", 100000 * rand();
tie my $x, &BG_QX, "$^X t/external-command.pl -e=$z -s=3";
$t = Time::HiRes::time();
ok(defined $Forks::Super::LAST_JOB, "\$Forks::Super::LAST_JOB set");
ok(defined $Forks::Super::LAST_JOB_ID, "\$Forks::Super::LAST_JOB_ID set");
ok(Forks::Super::isValidPid($Forks::Super::LAST_JOB_ID), 
	"\$Forks::Super::LAST_JOB_ID set");
ok($Forks::Super::LAST_JOB->{_is_bg} > 0, 
	"\$Forks::Super::LAST_JOB marked bg");
my $p = waitpid -1, 0;
my $t3 = Time::HiRes::time() - $t;
ok($p == -1 && $t3 <= 1.5,
	"waitpid doesn't catch bg_qx job, fast fail ${t3}s expect <=1s");
ok($x eq "$z \n", "scalar bg_qx $x");
my $h = Time::HiRes::time();
($t,$t2) = ($h-$t,$h-$t2);
my $y = $x;
ok($y == $z, "scalar bg_qx");
ok($t2 >= 2.6 && $t <= 6.5,           ### 24 ### was 5.1 obs 5.23,5.57,6.31,2.67
   "scalar bg_qx took ${t}s ${t2}s expected ~3s");
$x = 19;
ok($x == 19, "result is not read only");

### interrupted bg_qx, scalar context ###

my $j = $Forks::Super::LAST_JOB;
$y = "";
$z = sprintf "B%05d", 100000 * rand();
tie my $x2, &BG_QX, "$^X t/external-command.pl -s=10 -e=$z", timeout => 2;
$t = Time::HiRes::time();
$y = "$x2";

ok((!defined $y) || $y eq "" || $y eq "\n", "scalar bg_qx empty on failure");
ok($j ne $Forks::Super::LAST_JOB, "\$Forks::Super::LAST_JOB updated");
$t = Time::HiRes::time() - $t;
ok($t <= 5.95,                       ### 14 ### was 4 obs 4.92
   "scalar bg_qx respected timeout, took ${t}s expected ~2s");

### interrupted bg_qx, capture existing output ###

$z = sprintf "C%05d", 100000 * rand();
tie $x, &BG_QX, "$^X t/external-command.pl -e=$z -s=10", 
    timeout => 4;
$t = Time::HiRes::time();
ok($x eq "$z \n" || $x eq "$z ",   ### 15 ###
   "scalar bg_qx failed but retrieved output"); 
if (!defined $x) {
  print STDERR "(output was: <undef>;target was \"$z \")\n";
} elsif ($x ne "$z \n" && $x ne "$z ") {
  print STDERR "(output was: $x; target was \"$z \")\n";
}
$t = Time::HiRes::time() - $t;
ok($t <= 7.0,                            ### 16 ### was 3 obs 3.62,5.88
   "scalar bg_qx respected timeout, took ${t}s expected ~4s");

### list context ###

$t = Time::HiRes::time();
tie @x, &BG_QX,
    "$^X t/external-command.pl -e=Hello -n -s=2 -e=World -n -s=2 "
    . "-e=\"it is a\" -n -e=beautiful -n -e=day";
@tests = @x;
$t = Time::HiRes::time() - $t;
ok($tests[0] eq "Hello \n" && $tests[1] eq "World \n", "list bg_qx");
ok(@tests == 5, "list bg_qx");
ok($t >= 3.95, "list bg_qx took ${t}s expected ~4s");

# exercise array operations on the tie'd @x variable to make sure
# we implemented everything correctly 

$n = @x;
$u = shift @x;
ok($u eq "Hello \n" && @x == $n - 1, "list bg_qx shift");
$u = pop @x;
ok(@x == $n - 2 && $u =~ /day/, "list bg_qx pop");
unshift @x, "asdf";
ok(@x == $n - 1, "list bg_qx unshift");
push @x, "qwer", "tyuiop";
ok(@x == $n + 1, "list bg_qx push");
splice @x, 3, 3, "pq";
ok(@x == $n - 1 && $x[3] eq "pq", "list bg_qx splice");
$x[3] = "rst";
ok(@x == $n - 1 && $x[3] eq "rst", "list bg_qx store");
ok($x[2] =~ /it is a/, "list bg_qx fetch");
delete $x[4];
ok(!defined $x[4], "list bg_qx delete");
@x = ();
ok(@x == 0, "list bg_qx clear");

### partial output ###

$t = Time::HiRes::time();
tie @x, &BG_QX, 
    "$^X t/external-command.pl -e=Hello -n -s=1 -e=World -s=12 -n "
    . "-e=\"it is a\" -n -e=beautiful -n -e=day", { timeout => 6 };
@tests = @x;
$t = Time::HiRes::time() - $t;
ok($tests[0] eq "Hello \n", "list bg_qx first line ok");
ok($tests[1] eq "World \n" || $tests[1] eq "World ",
   "list bg_qx second line ok");                             ### 30 ###
ok(@tests == 2, "list bg_qx interrupted output had " 
	        . scalar @tests . "==2 lines");              ### 31 ###
if (@tests>2) {
  print STDERR "output was:\n", @tests, "\n";
}
ok($t >= 5.15 && $t < 10.05,
	"list bg_qx took ${t}s expected ~6-7s");             ### 32 ###

