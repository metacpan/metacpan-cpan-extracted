# vim600: set syn=perl :
use Test::More tests => 7;
BEGIN { use_ok('IO::Capture::Stdout') };

# These will generate some warnings -> preventing from printing
open STDERR_SAV, ">&STDERR"; open STDERR, ">/dev/null";

# Now test creating two captures of the same type and starting both
my $capture1 = IO::Capture::Stdout->new();
my $capture2 = IO::Capture::Stdout->new();

my $rv1 = $capture1->start();

#Test 2
ok(!$capture1->start,"Two starts");

#Test 3
ok(!$capture2->start(), "Two captures");

$capture2->stop();

#Test 4
ok(!$capture1->start(), "Two starts");

#Test 5
ok(!$capture1->read(), "Read before stop");

$capture1->stop();

my $capture3 = IO::Capture::Stdout->new();

#Test 6
ok(!$capture3->stop(), "Stop before Start");

$capture3->start();
$capture3->stop();

#Test 7
ok(!$capture3->stop(), "Two Stops");

# restore STDERR
close STDERR; open STDERR, ">&STDERR_SAV"; close STDERR_SAV;
