#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Term::ANSIColor 3.00 ();
use English qw(-no_match_vars);
use Capture::Tiny qw(capture capture_stderr);

plan tests => 12;

subtest 'Require some module' => sub {
    plan tests => 2;

    use_ok 'JIP::Debug', '0.021';
    require_ok 'JIP::Debug';

    diag(
        sprintf 'Testing JIP::Debug %s, Perl %s, %s',
            $JIP::Debug::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
    );
};

subtest 'Exportable functions' => sub {
    plan tests => 6;

    can_ok 'JIP::Debug', qw(to_debug to_debug_raw to_debug_empty);

    throws_ok { to_debug() } qr{
        Undefined \s subroutine \s &main::to_debug \s called
    }x;

    throws_ok { to_debug_raw() } qr{
        Undefined \s subroutine \s &main::to_debug_raw \s called
    }x;

    throws_ok { to_debug_empty() } qr{
        Undefined \s subroutine \s &main::to_debug_empty \s called
    }x;

    throws_ok { to_debug_count() } qr{
        Undefined \s subroutine \s &main::to_debug_count \s called
    }x;

    throws_ok { to_debug_trace() } qr{
        Undefined \s subroutine \s &main::to_debug_trace \s called
    }x;
};

subtest 'Exportable variables' => sub {
    plan tests => 10;

    no warnings qw(once);

    ok $JIP::Debug::COLOR           eq 'bright_green';
    ok $JIP::Debug::MSG_DELIMITER   eq q{-} x 80;
    ok $JIP::Debug::DUMPER_INDENT   == 1;
    ok $JIP::Debug::DUMPER_DEEPCOPY == 1;
    ok $JIP::Debug::DUMPER_SORTKEYS == 1;

    ok ref($JIP::Debug::HANDLE)          eq 'GLOB';
    ok ref($JIP::Debug::MAYBE_COLORED)   eq 'CODE';
    ok ref($JIP::Debug::MAKE_MSG_HEADER) eq 'CODE';

    is_deeply \%JIP::Debug::TRACE_PARAMS, {skip_frames => 1};

    is_deeply \%JIP::Debug::TRACE_AS_STRING_PARAMS, {};
};

subtest 'resolve_subroutine_name()' => sub {
    plan tests => 6;

    is JIP::Debug::resolve_subroutine_name(),                  undef;
    is JIP::Debug::resolve_subroutine_name(undef),             undef;
    is JIP::Debug::resolve_subroutine_name(q{}),               undef;
    is JIP::Debug::resolve_subroutine_name('subroutine_name'), undef;

    is JIP::Debug::resolve_subroutine_name('::subroutine_name'),                 'subroutine_name';
    is JIP::Debug::resolve_subroutine_name('package::package::subroutine_name'), 'subroutine_name';
};

subtest 'send_to_output()' => sub {
    plan tests => 4;

    no warnings qw(once);

    my ($stdout, $stderr) = capture {
        JIP::Debug::send_to_output(42);
    };
    is $stderr, 42;
    is $stdout, q{};

    local $JIP::Debug::HANDLE = \*STDOUT;
    ($stdout, $stderr) = capture {
        JIP::Debug::send_to_output(42);
    };
    is $stderr, q{};
    is $stdout, 42;
};

subtest 'MAYBE_COLORED()' => sub {
    plan tests => 8;

    no warnings qw(once);

    # with color
    is $JIP::Debug::MAYBE_COLORED->(),      undef;
    is $JIP::Debug::MAYBE_COLORED->(undef), undef;
    is $JIP::Debug::MAYBE_COLORED->(q{}),   Term::ANSIColor::colored(q{}, $JIP::Debug::COLOR);
    is $JIP::Debug::MAYBE_COLORED->(42),    Term::ANSIColor::colored(42, $JIP::Debug::COLOR);

    # without color
    {
        local $JIP::Debug::COLOR = undef;

        is $JIP::Debug::MAYBE_COLORED->(),      undef;
        is $JIP::Debug::MAYBE_COLORED->(undef), undef;
        is $JIP::Debug::MAYBE_COLORED->(q{}),   q{};
        is $JIP::Debug::MAYBE_COLORED->(42),    42;
    }
};

subtest 'to_debug()' => sub {
    plan tests => 1;

    my $stderr_listing = capture_stderr {
        no warnings qw(once);

        local $JIP::Debug::MAKE_MSG_HEADER = sub { return 'header' };
        local $JIP::Debug::DUMPER_INDENT   = 0;

        JIP::Debug::to_debug(42);
    };
    like $stderr_listing, qr{
        ^
        header
        \n
        \$VAR1\s+=\s+\[42\];
        \n\n
        $
    }x;
};

subtest 'to_debug_raw()' => sub {
    plan tests => 1;

    my $stderr_listing = capture_stderr {
        no warnings qw(once);

        local $JIP::Debug::MAKE_MSG_HEADER = sub { return 'header' };

        JIP::Debug::to_debug_raw(42);
    };
    like $stderr_listing, qr{
        ^
        header
        \n
        42
        \n\n
        $
    }x;
};

subtest 'to_debug_empty()' => sub {
    plan tests => 1;

    my $stderr_listing = capture_stderr {
        no warnings qw(once);

        local $JIP::Debug::MAKE_MSG_HEADER = sub { return 'header' };

        JIP::Debug::to_debug_empty(42);
    };
    like $stderr_listing, qr{
        ^
        header
        \n
        \n{18}
        \n\n
        $
    }x;
};

subtest 'to_debug_count()' => sub {
    my @tests = (
        [q{<no \s label>}, 1],
        [q{<no \s label>}, 2],
        [q{<no \s label>}, 3, undef],
        [q{<no \s label>}, 4, q{}],
        [q{0}, 1, 0],
        [q{0}, 2, q{0}],
        [q{tratata}, 1, 'tratata'],
        [q{tratata}, 2, 'tratata'],
    );

    plan tests => scalar @tests;

    foreach my $test (@tests) {
        my ($label_regex, $count, @params) = @{ $test };

        my $stderr_listing = capture_stderr {
            no warnings qw(once);

            local $JIP::Debug::MAKE_MSG_HEADER = sub { return 'header' };

            JIP::Debug::to_debug_count(@params);
        };
        like $stderr_listing, qr{
            ^
            header
            \n
            $label_regex: \s $count
            \n\n
            $
        }x;
    }
};

subtest 'to_debug_count() with callback' => sub {
    plan tests => 1;

    no warnings qw(once);

    # cleanup
    local %JIP::Debug::COUNT_OF_LABEL = (
        $JIP::Debug::NO_LABEL_KEY => 0,
    );

    my $sequence = [];
    my $cb = sub {
        my ($label, $count) = @ARG;

        push @{ $sequence }, [$label, $count];
    };

    my @tests = (
        [],
        ['tratata'],
        [$cb],
        ['tratata', $cb],
        [$cb],
        ['tratata', $cb],
        [],
        ['tratata'],
    );

    foreach my $test (@tests) {
        capture_stderr { JIP::Debug::to_debug_count(@{ $test }); };
    }

    is_deeply $sequence, [
        [q{<no label>}, 2],
        [q{tratata},    2],
        [q{<no label>}, 3],
        [q{tratata},    3],
    ];
};

subtest 'to_debug_trace()' => sub {
    plan tests => 1;

    my $stderr_listing = capture_stderr {
        no warnings qw(once);

        local $JIP::Debug::MAKE_MSG_HEADER = sub { return 'header' };

        JIP::Debug::to_debug_trace();
    };
    like $stderr_listing, qr{
        ^
        header
        \n
        Trace \s begun \s at .* \s line \s \d+
        \n\n
        $
    }sx;
};

