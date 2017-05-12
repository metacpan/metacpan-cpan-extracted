#!/usr/local/bin/perl -w

use Benchmark;

my $code;

$code = <<CODEBLOCK1;
     alias => 'Logger',
     initstr => q{
	 log4perl.rootLogger=INFO, A1
	 # log4perl.appender.A1=Log::Dispatch::Screen
	 log4perl.appender.A1 = Log::Dispatch::File
	 log4perl.appender.A1.filename = ./mylog.t2
	 log4perl.appender.A1.mode = write
	 log4perl.appender.A1.layout = PatternLayout
	 log4perl.appender.A1.layout.ConversionPattern=%d %-5p@ %c - %m@ %n
	 # create COVERAGE log
	 log4perl.Log.Log4perl.AutoCategorize.END = INFO, COVERAGE
	 log4perl.appender.COVERAGE = Log::Dispatch::File
	 log4perl.appender.COVERAGE.filename = ./test-coverage.t2
         log4perl.appender.COVERAGE.mode = write
	 log4perl.appender.COVERAGE.layout = org.apache.log4j.PatternLayout
	 log4perl.appender.COVERAGE.layout.ConversionPattern = (%d{HH:mm:ss.SSS}) %c: %m%n
	 }
     );
CODEBLOCK1

$code .= <<'CODEBLOCK2';

foreach (1..10) {
    Logger->warn($_);
    Logger->info($_);
    foo();
    A->bar();
    A::bar();
}

sub foo {
    foreach (1..10) {
	Logger->warn($_);
    }
}

package A;
sub bar {
    my @d;
    foreach (1..10) {
	push @d, $_;
	Logger->warn($_,\@d);
	Logger->debug("this should be suppressed $_", \@d);
    }
}
CODEBLOCK2


# Use Perl code in strings...
timethese(-20, {
    'optimized' => qq{
	use Log::Log4perl::AutoCategorize
	    (
	     $code },
		
    'unoptimized' => qq{
	use Log::Log4perl::AutoCategorize
	    (
	     debug => 'n',
	     $code },
});



__END__
