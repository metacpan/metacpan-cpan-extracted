#!/usr/local/bin/perl -w

use Getopt::Std;

use Log::Log4perl::AutoCategorize
    (
     # debug => $opt_d,
     alias => 'Logger',
     initstr => q{
	 log4perl.rootLogger=INFO, A1
	 # log4perl.appender.A1=Log::Dispatch::Screen
	 log4perl.appender.A1 = Log::Dispatch::File
	 log4perl.appender.A1.filename = sub { $0=~s/\.pl//; "./$0.log" }
	 log4perl.appender.A1.mode = write
	 log4perl.appender.A1.layout = PatternLayout
	 log4perl.appender.A1.layout.ConversionPattern=%d %c %m%n
	 # create COVERAGE log
	 # log4perl.Log.Log4perl.END = INFO, COVERAGE
	 log4perl.Log.Log4perl.AutoCategorize.END = INFO, COVERAGE
	 log4perl.appender.COVERAGE = Log::Dispatch::File
	 log4perl.appender.COVERAGE.filename = sub { $0=~s/\.pl//; "./$0.coverage" }
         log4perl.appender.COVERAGE.mode = write
	 log4perl.appender.COVERAGE.layout = org.apache.log4j.PatternLayout
	 log4perl.appender.COVERAGE.layout.ConversionPattern = (%d{HH:mm:ss.SSS}) %c: %m%n
	 }
     );

getopts('d:') or die 'bad opts';
Log::Log4perl::AutoCategorize::set_debug($opt_d) if $opt_d;

foreach (1..5) {
    Logger->warn($_);
    Logger->info($_);
    foo();
    A->bar();
    A::bar();
}

sub foo {
    foreach (1..5) {
	Logger->warn($_);
    }
}

package A;

sub bar {
    my @d;
    foreach (1..5) {
	push @d, $_;
	Logger->warn($_,\@d);
	Logger->debug("this should be suppressed $_", \@d);
    }
}

__END__
