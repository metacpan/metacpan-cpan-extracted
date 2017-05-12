#
# Test for dispatcher behavior
#

use strict;
use Test::Simple tests => 29;

use Log::Channel;
use Log::Dispatch::File;

close STDERR;

my $stderrfile = "/tmp/logchan$$.stderr";
open STDERR, ">$stderrfile" or die;

######################################################################

package One;

use Carp;

my $log1 = new Log::Channel "t1";
sub msg1 { $log1->(@_) }

my $log2 = new Log::Channel "t2";
sub msg2 { $log2->(@_) }

sub ouch {
    carp @_;
}
sub oops {
    croak @_;
}

package One::Subone;
use Carp;

sub ouch {
    carp @_;
}

######################################################################

package main;

my $filename = "/tmp/logchan$$.log";
my $file = Log::Dispatch::File->new( name      => 'file1',
				     min_level => 'info',
				     filename  => $filename,
				     mode      => 'append' );

Log::Channel->commandeer("One");

######################################################################

One::msg1 "message 01\n";		# should go to stderr
One::msg2 "message 02\n";		# "
One::ouch "carp 11";

dispatch Log::Channel ("One", $file);

One::msg1 "message 03\n";		# should go to file
One::msg2 "message 04\n";		# "
One::ouch "carp 12";

eval {
    One::oops "croak 17";
};
ok ($@);

undispatch Log::Channel "One";

One::msg1 "message 05\n";		# should go to stderr
One::msg2 "message 06\n";		# "
One::ouch "carp 13";

dispatch Log::Channel ("One::t2", $file);

One::msg1 "message 07\n";		# should go to stderr
One::msg2 "message 08\n";		# should go to file
One::ouch "carp 14";			# should go to stderr

undispatch Log::Channel "One";

One::msg1 "message 09\n";		# should go to stderr
One::msg2 "message 10\n";		# "
One::ouch "carp 15";

eval {
    One::oops "croak 16";
};
ok ($@);

######################################################################
# Now check the log files

close STDERR;

open (LINES, "<$stderrfile") or die $!;
my @lines = <LINES>;
close LINES;
ok ((scalar grep { /message 01/ } @lines) == 1);
ok ((scalar grep { /message 02/ } @lines) == 1);
ok ((scalar grep { /message 03/ } @lines) == 0);
ok ((scalar grep { /message 04/ } @lines) == 0);
ok ((scalar grep { /message 05/ } @lines) == 1);
ok ((scalar grep { /message 06/ } @lines) == 1);
ok ((scalar grep { /message 07/ } @lines) == 1);
ok ((scalar grep { /message 08/ } @lines) == 0);
ok ((scalar grep { /message 09/ } @lines) == 1);
ok ((scalar grep { /message 10/ } @lines) == 1);
ok ((scalar grep { /carp 11/ } @lines) == 1);
ok ((scalar grep { /carp 13/ } @lines) == 1);
ok ((scalar grep { /carp 14/ } @lines) == 1);
ok ((scalar grep { /carp 15/ } @lines) == 1);
ok ((scalar grep { /croak 16/ } @lines) == 1);

open (LINES, "<$filename") or die $!;
@lines = <LINES>;
close LINES;
ok ((scalar grep { /message 01/ } @lines) == 0);
ok ((scalar grep { /message 02/ } @lines) == 0);
ok ((scalar grep { /message 03/ } @lines) == 1);
ok ((scalar grep { /message 04/ } @lines) == 1);
ok ((scalar grep { /message 05/ } @lines) == 0);
ok ((scalar grep { /message 06/ } @lines) == 0);
ok ((scalar grep { /message 07/ } @lines) == 0);
ok ((scalar grep { /message 08/ } @lines) == 1);
ok ((scalar grep { /message 09/ } @lines) == 0);
ok ((scalar grep { /message 10/ } @lines) == 0);
ok ((scalar grep { /carp 12/ } @lines) == 1);
ok ((scalar grep { /croak 17/ } @lines) == 1);

######################################################################
# Clean up

unlink $stderrfile;
unlink $filename;
