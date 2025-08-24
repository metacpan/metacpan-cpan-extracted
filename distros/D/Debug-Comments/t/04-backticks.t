use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestHelper;

subtest 'backtick stripping' => sub {
    my ($output, $exit) = TestHelper::run_code(<<'', DEBUG => 1);
use if $ENV{DEBUG}, 'Debug::Comments';
#@! Text with `backticks` here

    is($exit, 0, 'Code runs successfully');
    like($output, qr/Backticks stripped/, 'Warning issued');
    my @debug = TestHelper::parse_debug_output($output);
    is($debug[0]->{text}, 'Text with backticks here', 'Backticks removed');
};

subtest 'multiple backticks' => sub {
    my ($output, $exit) = TestHelper::run_code(<<'', DEBUG => 1);
use if $ENV{DEBUG}, 'Debug::Comments';
#@! Has `one` and `two` and `three`

    is($exit, 0, 'Code runs successfully');
    # Should only warn once per line
    my @warning = $output =~ /^Backticks stripped .*/mg;
    is(@warning, 1, 'One warning per line');
    my @debug = TestHelper::parse_debug_output($output);
    is($debug[0]->{text}, 'Has one and two and three', 'All backticks removed');
};

done_testing();
