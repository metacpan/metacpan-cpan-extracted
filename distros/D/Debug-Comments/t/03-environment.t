use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestHelper;

subtest 'TTY color detection' => sub {
  SKIP:
    {
        skip "No TTY available", 3 unless TestHelper::can_tty();
        my ($output, $exit) = TestHelper::run_code(<<'', DEBUG => 1, FORCE_TTY => 1);
use if $ENV{DEBUG}, 'Debug::Comments';
#@! Colored

        is($exit, 0, 'Code runs successfully');
        ok(TestHelper::has_ansi($output), 'TTY produces colored output');
        like($output, qr/\e\[0;34;47m/, 'Default color scheme present');
    }
};

subtest 'NO_COLOR override' => sub {
  SKIP:
    {
        skip "No TTY available", 3 unless TestHelper::can_tty();
        my ($output, $exit) = TestHelper::run_code(
            <<'', DEBUG => 1, NO_COLOR => 1, FORCE_TTY => 1);
use if $ENV{DEBUG}, 'Debug::Comments';
#@! Not colored

        is($exit, 0, 'Code runs successfully');
        ok(!TestHelper::has_ansi($output), 'NO_COLOR prevents coloring');
        my @debug = TestHelper::parse_debug_output($output);
        is($debug[0]->{text}, 'Not colored', 'Message still present');
    }
};

subtest 'custom color' => sub {
  SKIP:
    {
        skip "No TTY available", 2 unless TestHelper::can_tty();
        my ($output, $exit) = TestHelper::run_code(
            <<'', DEBUG => 1, FORCE_TTY => 1, DEBUG_COMMENTS_COLOR => '31;1');
use if $ENV{DEBUG}, 'Debug::Comments';
#@! Red bold

        is($exit, 0, 'Code runs successfully');
        like($output, qr/\e\[31;1m/, 'Custom color applied');
    }
};

subtest 'DEBUG_COMMENTS_LIMIT' => sub {
    my ($output, $exit) = TestHelper::run_code(
        <<'', DEBUG => 1, DEBUG_COMMENTS_LIMIT => 'Foo::* Bar');
package Foo::One;
use if $ENV{DEBUG}, 'Debug::Comments', '@1';
#@1 Foo::One here
package Foo::Two::Three;
use if $ENV{DEBUG}, 'Debug::Comments', '@2';
#@2 Foo::Two::Three here
package Bar;
use if $ENV{DEBUG}, 'Debug::Comments', '@3';
#@3 Bar here
package Bar::Baz;
use if $ENV{DEBUG}, 'Debug::Comments', '@4';
#@4 Bar::Baz should not appear

    is($exit, 0, 'Code runs successfully');
    my @debug = TestHelper::parse_debug_output($output);
    is(@debug, 3, 'Only allowed modules produce output');
    is($debug[0]->{text}, 'Foo::One here', 'Foo::* wildcard works');
    is($debug[1]->{text}, 'Foo::Two::Three here', 'Deep wildcard match');
    is($debug[2]->{text}, 'Bar here', 'Exact match works');
};

done_testing();
