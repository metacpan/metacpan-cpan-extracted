use Test::More tests => 14;
# use Carp::Always;
use strict;
use warnings;

unlink "t/01-testprog.pl", "t/01-testprog.out";

open(TESTPROG, ">", "t/01-testprog.pl");
print TESTPROG <<'_END_TEST_';
# a test program
#
# this is line 3. The first line of code is line 5.

my $code_from_parent = 4;
print "Hello\n";
&a_function(3,6);
my $pid = fork();
if ($pid == 0) {
    my $code_from_child = 7;
    &a_function(17,5);
    # no exit statement, so code after this block
    # is executed in both parent and child
} else {
    sleep 1;
}
my $code_in_both_programs = 9;

sub a_function {
  my ($x,$y) = @_;
  return $x + $y;
}
_END_TEST_

close TESTPROG;

$ENV{DTRACE_FILE} = "t/01-testprog.trace";
system("$^X -Ilib -MCarp::Always -d:Trace::Fork t/01-testprog.pl > t/01-testprog.out 2> /dev/null")
	&& system("$^X -Ilib -d:Trace::Fork t/01-testprog.pl > t/01-testprog.out");
# > t/01-testprog.out 2>&1");

# now examine the output .

open(TESTOUT, "<", "t/01-testprog.out");
my @TESTOUT = <TESTOUT>;
close TESTOUT;
open TRACEOUT, "<", "t/01-testprog.trace";
my @TRACEOUT = <TRACEOUT>;
close TRACEOUT;

# our expectations about the output:
#   "Hello\n" is printed exactly once.
#   a_function is called twice by two different pids, first in parent
#   code_from_parent is associated with parent pid
#   code_from_child is associated with child pid
#   code_from_both is associated with both pids.

sub extract_pid {
  # extract process id from line of Devel::Trace::Fork output
  my ($line) = @_;
  my ($time,$pid,$status,$file,$lineno,$code) = split /:/, $line, 6;
  return $pid;
}

my @hello = grep { $_ eq "Hello\n" } @TESTOUT;
ok(@hello == 1);
ok(not defined extract_pid($hello[0]));

my $parent_pid = extract_pid($TRACEOUT[2]);

my @a_function = grep { /return \$x \+ \$y/ } @TRACEOUT;
ok(@a_function == 2);
if (@a_function != 2) {
   print STDERR "output is:\n--------------\n@TRACEOUT\n-----------------\n";
}
ok(extract_pid($a_function[0]) == $parent_pid);
ok(defined $a_function[1] && extract_pid($a_function[1]) != $parent_pid);

my @from_parent = grep { /from_parent/ } @TRACEOUT;
ok(@from_parent == 1);
ok(extract_pid($from_parent[0]) == $parent_pid);

my @from_child = grep { /from_child/ } @TRACEOUT;
ok(@from_child == 1);
ok(defined $from_child[0] && extract_pid($from_child[0]) != $parent_pid);

my @from_both = grep { /_in_both_/ } @TRACEOUT;
ok(@from_both == 2);
ok(extract_pid($from_both[0]) != extract_pid($from_both[1]));

my %pids_seen = ();
foreach my $line (grep { /^\>\>/ } @TRACEOUT) {
  $pids_seen{ extract_pid($line) }++;
}

ok(2 == scalar keys %pids_seen, 
   "should be 2 pids in output, were " . scalar keys %pids_seen);
delete $pids_seen{$parent_pid};
ok(1 == scalar keys %pids_seen);

# output is sorted.
my $i = 0;
for ($i=3; $i<@TRACEOUT; $i++) {
  my ($t0) = $TRACEOUT[$i-1] =~ /^>>\s*(\d+\.\d+):/; 
  my ($t1) = $TRACEOUT[$i] =~ /^>>\s*(\d+\.\d+):/;
  if ($t1 < $t0) {
    ok(0, "timestamp " . ($i+1) . " $t1 < timestamp $i $t0");
    last;
  }
}
if ($i >= @TRACEOUT) {
  ok(1, "timestamps are sorted");
}


