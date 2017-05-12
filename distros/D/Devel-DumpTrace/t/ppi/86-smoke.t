use Test::More;
BEGIN {
    if (eval "use PPI;1") {
	plan tests => 27;
    } else {
	plan skip_all => "PPI not available";
    }
}
use strict;
use warnings;

# check output of Devel::DumpTrace module, compare with reference output.
# run code that uses a core module, and see if we are doing what
# we are supposed to about tracing through that core module

my $dmodule = "-d:DumpTrace::PPI";

open T, '>', "$0.pl";
print T <<'EO_T;';

# test program for t/86-smoke.t, t/ppi/86-smoke.t
use Time::Local;
$n = timelocal(0,0,12, 6,1,1980);  # noon on July 1, 1980

EO_T;





# levels 1,2,3 can be distinguished by which lines are abbreviated.
# level 1: two lines should have abbrev
# level 2: one line
# level 3: no lines

for my $pkg (0,1,2) {

    my $level = 3;
    my $file = "$0.out.$pkg$level";
    $ENV{DUMPTRACE_FH} = $file;
    if ($pkg > 1) {
	$ENV{DUMPTRACE_LEVEL} = 100 + $level;
    } else {
	$ENV{DUMPTRACE_LEVEL} = "$level,$pkg";
    }
    my $c1 = system($^X, $dmodule, "-Iblib/lib", "-Ilib", "$0.pl");

    my $keep = $ENV{KEEP} || 0;

    ok($c1 == 0, "ran level $level,$pkg") or $keep++, diag "exit code=$c1";
    sleep 10 if $c1!=0;
    
    open XH, '<', $file;
    my @xh = <XH>;
    close XH;

    if ($pkg) {
	ok(@xh > 2, "smoke output has more than 2 lines pkg on") or $keep++;
	ok(0 < (grep { /Time.Local.pm:\d+:/ } @xh),
	   "smoke output traces into core package") or $keep++;
    } else {
	ok(@xh <= 2, "smoke output has <3 lines pkg off") or $keep++;
	ok(0 == (grep { /Time.Local.pm:\d+:/ } @xh),
	   "smoke output doesn't trace into core package") or $keep++;
    }

    unlink $file unless $keep;
}


for my $pkg (0,1,2) {

    my $level = 5;
    my $file = "$0.out.$pkg$level";
    $ENV{DUMPTRACE_FH} = $file;
    if ($pkg > 1) {
	$ENV{DUMPTRACE_LEVEL} = 100 + $level;
    } else {
	$ENV{DUMPTRACE_LEVEL} = "$level,$pkg";
    }
    my $c1 = system($^X, $dmodule, "-Iblib/lib", "-Ilib", "$0.pl");
    my $keep = $ENV{KEEP} || 0;

    # failure point on Linux v5.8.6 - seg fault?
    ok($c1 == 0, "ran level $level") or $keep++, diag "exit code=$c1";

    open XH, '<', $file;
    my @xh = <XH>;
    close XH;

    if ($pkg) {
	ok(@xh > 6, "smoke output has more than 6 lines pkg on") or $keep++;
	ok(0 < (grep { /Time.Local.pm:\d+:/ } @xh),
	   "smoke output traces into core package") or $keep++;
    } else {
	ok(@xh <= 6, "smoke output has <7 lines pkg off") or $keep++;
	ok(0 == (grep { /Time.Local.pm:\d+:/ } @xh),
	   "smoke output doesn't trace into core package") or $keep++;
    }

    my $separate_line_for_line_and_file = qr{^>>\s+$0.pl:\d+:};
    my $uneval_lhs = qr#^>{3,4}\s+[\$\@]\w+.*=#;
    my $uneval_rhs = qr{=.*[\$\@]};

    ok($xh[0] =~ $separate_line_for_line_and_file,
       "level $level separate line for line & file") or $keep++;

    ok($xh[2] !~ $uneval_lhs,
       "level $level seperate line for evaluate lhs") or $keep++;

    my @sep = grep { /----------/ } @xh;
    ok(@sep > 0 && $sep[0] eq $sep[-1],
# ok($xh[3] eq $xh[-1] && substr($xh[3],0,10) eq '-' x 10,
       "level $level output has separator lines") or $keep++;

    unlink $file unless $keep;
}

unlink "$0.pl";
