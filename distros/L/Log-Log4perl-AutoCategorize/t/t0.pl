#!/usr/local/bin/perl -w

use Log::Log4perl;
use Log::Log4perl::Appender;
use Log::Dispatch::Screen;
use Log::Dispatch::File;

Log::Log4perl->init('log-conf');

use Data::Dumper;
use Getopt::Std;
$Data::Dumper::Indent=1;
$Data::Dumper::Sortkeys=1;
$Data::Dumper::Terse=1;

getopts('m:f:b:c:o') or die <<OPTS;
  m <#>    : main loop count (default 50)
  f <#>    : foo() loop count (default 20)
  b <#>    : A::bar() loop count (default 20)
  o        : optimizes for speed (defeats apples-apples compare)
OPTS

$opt_m ||= 50;
$opt_f ||= 20;
$opt_b ||= 20;
$opt_c ||= 20;

foreach (1..$opt_m) {
    my $logger;
    $logger = Log::Log4perl->get_logger('main.main.warn.34');
    $logger->warn('something, ',$_);

    $logger = Log::Log4perl->get_logger('main.main.info.35') unless $opt_o;
    $logger->warn('something, ',$_);

    $logger = Log::Log4perl->get_logger('main.main.info.36') unless $opt_o;
    $logger->warn('something, ',$_);

    $logger = Log::Log4perl->get_logger('main.main.warn.37') unless $opt_o;
    $logger->warn('something, ',$_);

    $logger = Log::Log4perl->get_logger('main.main.warn.38') unless $opt_o;
    $logger->warn('something, ',$_);

    $logger = Log::Log4perl->get_logger('Logger1.AUTOLOAD.31');
    $logger->info('411, ',$_);
    car();
    suv();
    A->truck();
    A::truck();

    if ($false) {
	# never executed, but reported as such in coverage log
	$logger = Log::Log4perl->get_logger('main.main.fatal');
	$logger->info('UnSeen', $_);
    }
    if (0) {
	# optimized out by perl itself. never seen by AutoCategorize's optimizer
	$logger = Log::Log4perl->get_logger('whocares');
	$logger->info('not even seen by optimizer', $_);
    }
}

sub car {
    my $logger;
    foreach (1..$opt_f) {
	$logger = Log::Log4perl->get_logger('main.car.warn.57');
	$logger->warn("2 people, $_, ", Dumper [{driver=>'bonnie',shotgun=>'clyde'}]);
    }
}
sub suv {
    my $logger;
    foreach (1..$opt_f) {
	$logger = Log::Log4perl->get_logger('main.suv.39');
	$logger->warn("gas guzzler, ", $_);

	$logger = Log::Log4perl->get_logger('main.suv.39') unless $opt_o;
	$logger->warn("pacs vs cafe, ", $_);
    }
}

package A;
use Data::Dumper;

sub truck {
    my ($logger,@d);
    foreach (1..$main::opt_b) {
	push @d, $_;
	$logger = Log::Log4perl->get_logger('A.truck.warn.73');
	$logger->warn($_, Dumper \@d);

	$logger = Log::Log4perl->get_logger('A.truck.debug.74');
	$logger->debug("trucks are noisy $_, ", Dumper \@d);

	# subtle prob here - only 1st debug is seen by AUTOLOAD
	$logger = Log::Log4perl->get_logger('A.truck.debug.76') unless $opt_o;
	$logger->debug("bug here $_, ", Dumper \@d);

	$logger = Log::Log4perl->get_logger('A.truck.debug.77') unless $opt_o;
	$logger->debug("diesel is polluting $_, ", Dumper \@d);
    }
}

package B::C;
use Data::Dumper;

sub train {
    my (@d,$logger);
    foreach (1..$main::opt_c) {
	push @d, $_;
	$logger = Log::Log4perl->get_logger('B.C.train.warn.87');
	$logger->warn($_, Dumper \@d);
    }
}

__END__

