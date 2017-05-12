# Published Methods 'Exist' Test
# vim600: set syn=perl :

use Test::More tests => 6;
BEGIN { use_ok('IO::Capture::Stderr') };

my $capture;

# Test 2
eval { $capture = IO::Capture::Stderr->new()};
ok(!$@, "Constructor Test");
print "Error checking 'new' constructor: $@\n" if $@;

# These will generate some warnings -> preventing from printing
open STDERR_SAV, ">&STDERR"; open STDERR, ">/dev/null";

eval {$capture->start};
ok(!$@, "Checking start method" );
print "\n" . "*" x 80 . qq/\nError checking published method, "start": $@\n/ . "*" x 80 . "\n" if $@;

eval {$capture->stop};
ok(!$@, "Checking stop method" );
print "\n" . "*" x 80 . qq/\nError checking published method, "stop": $@\n/ . "*" x 80 . "\n" if $@;

eval {$capture->read};
ok(!$@, "Checking read method" );
print "\n" . "*" x 80 . qq/\nError checking published method, "read": $@\n/ . "*" x 80 . "\n" if $@;

eval {$capture->line_pointer};
ok(!$@, "Checking line_pointer method" );
print "\n" . "*" x 80 . qq/\nError checking published method, "line_pointer": $@\n/ . "*" x 80 . "\n" if $@;

close STDERR; open STDERR, ">&STDERR_SAV"; close STDERR_SAV;
