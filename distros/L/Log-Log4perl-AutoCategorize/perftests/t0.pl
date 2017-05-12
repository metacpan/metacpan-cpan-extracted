#!/usr/local/bin/perl -w

use Log::Log4perl;
use Log::Log4perl::Appender;
use Log::Dispatch::Screen;
use Log::Dispatch::File;

Log::Log4perl->init(\q{
	  log4perl.rootLogger=INFO, A1
	  # log4perl.appender.A1=Log::Dispatch::Screen
	  log4perl.appender.A1 = Log::Dispatch::File
	  log4perl.appender.A1.filename = ./mylog.t0
	  log4perl.appender.A1.mode = write
	  log4perl.appender.A1.layout = PatternLayout
	  log4perl.appender.A1.layout.ConversionPattern=%c %m%n
	  });

use Data::Dumper;
use Getopt::Std;
$Data::Dumper::Indent=1;
$Data::Dumper::Terse=1;

getopts('o') or die "$0 [-o] : suppresses debug for closer match to t1,t2 \n";

foreach (1..500) {
    my $log = Log::Log4perl->get_logger('main.main.26');
    $log->warn($_, ' ');
    $log = Log::Log4perl->get_logger('main.main.27');
    $log->info($_, ' ');
    foo();
    A->bar();
    A::bar();
}

sub foo {
    my $log = Log::Log4perl->get_logger('main.foo.35');
    foreach (1..20) {
	$log->warn($_, ' ');
    }
}

package A;
use Data::Dumper;

sub bar {
    my @d;
    foreach (1..20) {
	push @d, $_;
	my $log = Log::Log4perl->get_logger('A.bar.45');
	$log->warn("$_, ", Dumper \@d);

	$log = Log::Log4perl->get_logger('A.bar.50');
	$log->debug("this should be suppressed $_", Dumper \@d)
	    unless $main::opt_o;
    }
}

__END__

    'A.bar.49' => 20000,
    'A.bar.50' => 20000,
    'Logger1.AUTOLOAD.30' => 500,
    'Logger1.AUTOLOAD.31' => 500,
    'Logger1.END.162' => 1,
    'main.foo.39' => 10000

