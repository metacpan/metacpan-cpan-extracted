use Forks::Super ':test';
use Test::More tests => 14;
use strict;
use warnings;

$Forks::Super::EMULATION_MODE = 1;

my $untaint = 0;
if (${^TAINT}) {
    $untaint = 1;
}
my ($a,@a,%a);

if (!Forks::Super::Config::CONFIG('filehandles')) {
  SKIP: {
      skip "share feature requires file-based IPC", 18;
    }
    exit;
}

my $pid = fork {
    sub => sub {
	$a = 5;
	sleep 2;
    },
    share => [ \$a ],
    untaint => $untaint
};
waitpid $pid, 0;
ok($a == 5, 'scalar value shared from child to parent');

$pid = fork {
    sub => sub { @a = (5..10) ; sleep 2 },
    share => [ \@a ],
    untaint => $untaint
};
ok("@a" eq "5 6 7 8 9 10", 'in emulation mode, @a is already shared') or diag @a;
@a = (11..14);
waitpid $pid, 0;
ok("@a" eq "11 12 13 14",
   'array value overwritten in parent')
    or diag("\@a was: \"@a\", expected \"11 12 13 14\"");


my $len = scalar @a;
%a = (abc => 'def', ghi => 'jkl');
$pid = fork {
    sub => sub { sleep 2; %a = (abc => 'xyz', mno => 'pqr'); @a = ('foo') },
    share => [ \%a , \@a ],
    untaint => $untaint
};
waitpid $pid, 0;
ok($a{mno} eq 'pqr', "hash value passed from child to parent");
ok(!defined($a{ghi}), "parent hash value cleared in \"child\"");
ok($a{abc} eq 'xyz', "... unless overwritten by child");
ok(2 == keys(%a), "all keys in shared hash accounted for");
ok(@a < $len, "parent array values overwritten in child");
ok($a[-1] eq 'foo',
   "array value from child shared to parent");   ### 9 ###


# does sharing happen when child process fails ?
$a = '';
@a = ();
%a = ();
$pid = fork {
    sub => sub { 
	@a = reverse (1..10);
	$a = @a;
	$a{"Forks"} = "Super";
	sleep 6;
	$a{"Super"} = "Forks";
    },
    timeout => 3,   
    share => [ \$a, \%a, \@a ],
    untaint => $untaint
};
waitpid $pid, 0;

# sharing is not guaranteed to work if the child fails,
# but it often does.

ok($pid->{status} != 0, "testing unsuccessful job");
if ($a eq '') {
    ok(1, "share scalar not updated on failed job");
} else {
    ok($a == 10, "share scalar ok even on job failure");
}
if ("@a" eq '') {
    ok(1, "share array not updated on failed job");
} else {
    ok("@a" eq "10 9 8 7 6 5 4 3 2 1", "share array ok even on job failure");
}
if (keys %a == 0) {
    ok(1, "share hash not updated in failed job");
} else {
    ok($a{"Forks"} eq "Super", "share hash ok even on job failure");
}
ok(!defined $a{"Super"}, "job failed before second child hash assignment");

# can't test emulation mode with a natural fork

