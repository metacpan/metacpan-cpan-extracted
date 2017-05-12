#!/usr/local/bin/perl -w

use Getopt::Std;
use lib '..';
use Log::Log4perl::AutoCategorize
    (
     # debug => $opt_d,
     alias => 'Logger',
     initfile => 'log-conf',
     initstrNOT => q{
	 log4perl.appender.A1.filename = ./mylog.ti
	 log4perl.appender.COVERAGE.filename = ./test-coverage.ti
	 }
     );

getopts('d:m:f:b:c:') or die <<OPTS;
  d: single letter options to control debug in  Log::Log4perl::AutoCategorize
  m: main loop count (default 500)
  f: foo() loop count (default 20)
  b: A::bar() loop count (default 20)
OPTS

$opt_m ||= 500;
$opt_f ||= 20;
$opt_b ||= 20;
$opt_c ||= 20;

Log::Log4perl::AutoCategorize::set_debug($opt_d) if $opt_d;

foreach (1..$opt_m) {
    Logger->warn('something',$_);
    Logger->info('411',$_);
    car();
    suv();
    A->truck();
    A::truck();
    if (0) {
	# optimized out by perl itself. never seen by AutoCategorize's optimizer
	Logger->info('not even seen', $_);
    }
    if ($false) {
	Logger->info('unreachable', $_);
    }
}

sub car {
    foreach (1..$opt_f) {
	Logger->warn("2 people", $_,{driver=>'bonnie',shotgun=>'clyde'});
    }
}
sub suv {
    foreach (1..$opt_f) {
	Logger->warn("gas guzzler", $_);
	Logger->warn("pacs vs cafe", $_);
    }
}

package A;

sub truck {
    my @d;
    foreach (1..$main::opt_b) {
	push @d, $_;
	Logger->warn($_,\@d);
	Logger->debug("trucks are noisy $_", \@d);
	# subtle prob here - only 1st debug is seen by AUTOLOAD
	Logger->debug("bug here $_", \@d);
	Logger->debug_1("diesel is polluting $_", \@d);
    }
}

package B::C;

sub train {
    my @d;
    foreach (1..$main::opt_c) {
	push @d, $_;
	Logger->warn($_,\@d);
    }
}

__END__
