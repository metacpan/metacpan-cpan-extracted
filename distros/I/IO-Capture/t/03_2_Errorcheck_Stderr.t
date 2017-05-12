# vim600: set syn=perl :
use Test::More tests => 4;
BEGIN { use_ok('IO::Capture::Stderr') };

# These will generate some warnings -> preventing from printing
#open STDERR_SAV, ">&STDERR" 
open STDERR, ">/dev/null";

#Test 2
# Now test creating two captures of the same type and starting both
my $capture1 = IO::Capture::Stderr->new();
my $capture2 = IO::Capture::Stderr->new();

my $rv1 = $capture1->start();

ok(!$capture2->start(), "Two captures");

$capture2->stop();

ok(!$capture1->start(), "Two starts");

ok(!$capture1->read(), "Read before stop");

# restore STDERR
#close STDERR; open STDERR, ">&STDERR_SAV"; close STDERR_SAV;
