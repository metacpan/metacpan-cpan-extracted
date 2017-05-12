#!/usr/local/bin/perl -w

use Log::Log4perl::AutoCategorize
    ( alias => 'Logger',
      # debug => '', #preserve line numbers
      initstr => q{
	  log4perl.rootLogger=INFO, A1
	  # log4perl.appender.A1=Log::Dispatch::Screen
	  log4perl.appender.A1 = Log::Dispatch::File
	  log4perl.appender.A1.filename = ./mylog.t2
	  log4perl.appender.A1.mode = write
	  log4perl.appender.A1.layout = PatternLayout
	  log4perl.appender.A1.layout.ConversionPattern=%c %m%n
	 # create COVERAGE log
	 # alias doesnt work on this.     
	 # log4perl.logger.Logger.END = INFO, COVERAGE
	 log4perl.logger.Log.Log4perl.AutoCategorize.END = INFO, COVERAGE
	 log4perl.appender.COVERAGE = Log::Dispatch::File
	 log4perl.appender.COVERAGE.filename = ./test-coverage.t2
         log4perl.appender.COVERAGE.mode = write
	 log4perl.appender.COVERAGE.layout = org.apache.log4j.PatternLayout
	 log4perl.appender.COVERAGE.layout.ConversionPattern = (%d{HH:mm:ss.SSS}) %c: %m%n
	  });

foreach (1..500) {
    Logger->warn($_);
    Logger->info($_);
    foo();
    A->bar();
    A::bar();
}

sub foo {
    foreach (1..20) {
	Logger->warn($_);
    }
}

package A;

sub bar {
    my @d;
    foreach (1..20) {
	push @d, $_;
	Logger->warn($_,\@d);
	Logger->debug("this should be suppressed $_", \@d);
    }
}

__END__
