use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestHelper;

subtest 'basic' => sub {
    my ($output, $exit) = TestHelper::run_code(<<'', DEBUG => 1);
use if $ENV{DEBUG}, 'Debug::Comments';
#@! First debug message
warn "Hello\n"; #@! This is not a debug message
#@!
# The above line isn't a debug message, either
my $x = "Second";
#@! $x debug message

    is($exit, 0, 'Code runs successfully');
    my @debug = TestHelper::parse_debug_output($output);
    is(@debug, 2, 'Two debug messages emitted');
    is($debug[0]->{text}, 'First debug message', 'Basic message correct');
    is($debug[1]->{text}, 'Second debug message', 'Variable message correct');
    is($debug[0]->{line}, 2, 'Line number correct');
    like($output, qr/^Hello$/m, 'Non-debug output preserved');
};

# Test that filter doesn't activate without DEBUG
subtest 'inactive' => sub {
    my ($output, $exit) = TestHelper::run_code(<<'');
use if $ENV{DEBUG}, 'Debug::Comments';
#@! This should not appear
warn "Hello\n";

    is($exit, 0, 'Code runs successfully');
    is($output, "Hello\n", 'No debug output when DEBUG not set');
};

done_testing();
