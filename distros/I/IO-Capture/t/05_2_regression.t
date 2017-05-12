# vim600: set syn=perl :
use strict;
use Test::More tests => 3;

use IO::Capture::Stdout;
use IO::Capture::Stderr;

my $out_capture = IO::Capture::Stdout->new();
my $err_capture = IO::Capture::Stderr->new();

# Test for bug number 1
$err_capture->start();
$out_capture->start();
$out_capture->stop();
$err_capture->stop();

ok(!$err_capture->read(), "Test for no error if empty");

# Test for bug number 3
# A read() in scalar context, followed by one in list context
#

our $module;
for $module (qw/Stderr Stdout/) {
	no strict 'refs';
	my $module_name = "IO::Capture::$module";
    my $capture = $module_name->new();
	use strict 'refs';
	$capture->start;

	if ($module eq "Stdout") {
		print "Line 1";
	}
	else {
		print STDERR "Line 1";
	}

	$capture->stop();
	my $read_one = $capture->read();

	$capture->start();
	if ($module eq "Stdout") {
		print "Line 2";
	}
	else {
		print STDERR "Line 2";
	}
	$capture->stop();

	my @read_two = $capture->read();

	ok($read_two[0] eq "Line 2", "Bug 3 - $module");
}
