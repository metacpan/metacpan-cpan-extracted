#!/usr/local/bin/perl -w

use Getopt::Std;

use Log::Log4perl::AutoCategorize
    (
     # debug => $opt_d,
     alias => 'Logger',
     initstr => q{
	 log4perl.rootLogger=INFO, A1
	 log4perl.appender.A1 = Log::Dispatch::File
	 log4perl.appender.A1.filename = sub { $0=~ s&\.(?:t|pl)$|\.|/&&g; "./out.$0" }
	 log4perl.appender.A1.mode = write
	 log4perl.appender.A1.layout = PatternLayout
	 log4perl.appender.A1.layout.ConversionPattern=%d %c: %m%n
	 # create COVERAGE log
	 log4perl.appender.COVERAGE = Log::Dispatch::File
	 log4perl.appender.COVERAGE.filename =  sub { $0=~ s/\.(?:t|pl)$//; "./out.$0.cover" }
         log4perl.appender.COVERAGE.mode = write
	 log4perl.appender.COVERAGE.layout = org.apache.log4j.PatternLayout
	 log4perl.appender.COVERAGE.layout.ConversionPattern = (%d{HH:mm:ss.SSS}) %c: %m%n
         # now that file boilerplate is done,
	 # send something interesting there
	 log4perl.logger.Log.Log4perl.AutoCategorize.END = INFO, COVERAGE
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
