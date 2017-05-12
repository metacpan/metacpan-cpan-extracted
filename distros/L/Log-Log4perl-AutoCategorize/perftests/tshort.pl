#!/usr/local/bin/perl -w

use Getopt::Std;

BEGIN { getopts('d:') or die 'bad opts' }

use Log::Log4perl::AutoCategorize
    (
     debug => $opt_d,
     alias => 'Logger',
     initstr => q{
	 log4perl.rootLogger=INFO, A1
	 # log4perl.appender.A1=Log::Dispatch::Screen
	 log4perl.appender.A1 = Log::Dispatch::File
	 log4perl.appender.A1.filename = ./mylog
	 log4perl.appender.A1.mode = write
	 log4perl.appender.A1.layout = PatternLayout
	 # dont need %p in conversion, its already in category    
	 log4perl.appender.A1.layout.ConversionPattern=%d %p @ %c: %m%n

	 # by commenting one or both of these lines, you can play with overrides
	 log4perl.category.main.nope.warn = ERROR
	 log4perl.category.main.nope.warn.50 = WARN

	 # create COVERAGE log
	 log4perl.Log.Log4perl.AutoCategorize.END = INFO, COVERAGE
	 log4perl.appender.COVERAGE = Log::Dispatch::File
	 log4perl.appender.COVERAGE.filename = ./test-coverage.t2
         log4perl.appender.COVERAGE.mode = write
	 log4perl.appender.COVERAGE.layout = org.apache.log4j.PatternLayout
	 log4perl.appender.COVERAGE.layout.ConversionPattern = (%d{HH:mm:ss.SSS}) %c: %m%n
	 }
     );


foreach (1..10) {
    Logger->warn($_);
    Logger->info($_);
    foo();
    nope();
    A->bar();
    A::bar();
    if ($false) {
	# this should show up in coverage log
	Logger->info($_);
    }
}

sub foo  { Logger->warn($_) foreach (1..20) }
sub nope { Logger->warn($_) foreach (1..20) }

package A;

sub bar {
    my @d;
    foreach (1..20) {
	push @d, $_;
	Logger->warn($_,\@d);
	Logger->debug("this should be suppressed, due to level", \@d);
    }
}

__END__
