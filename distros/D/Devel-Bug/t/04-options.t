#!/usr/bin/env perl

use v5.8;
use warnings;
use utf8;

use Test2::V0;

our $buf;
open *TESTOUT, '>', \$buf or die "Cannot open capture buffer: $!";

sub reset_capture {
    close *TESTOUT;
    $buf = '';
    open *TESTOUT, '>', \$buf or die "Cannot reopen capture buffer: $!";
}

require Devel::Bug;

sub bug :lvalue;

# ---------------------------------------------------------------------------
# color option
# ---------------------------------------------------------------------------

# color => 1 (ON): ANSI codes always, even to non-terminal
{
    Devel::Bug->import(out => *TESTOUT, color => 1, vc => 'red');
    reset_capture();
    my $in;
    ($in = bug('c') = 42);
    like   $buf, qr/\e\[/, 'color=ON produces ANSI codes to non-terminal';
    is     $in,  42,        'value passes through with color=ON';
}

# color => undef (OFF): no ANSI codes ever
{
    Devel::Bug->import(out => *TESTOUT, color => undef, vc => 'red');
    reset_capture();
    my $in;
    ($in = bug('c') = 42);
    unlike $buf, qr/\e\[/, 'color=OFF produces no ANSI codes';
}

# color => '' (AUTO): no ANSI codes to non-terminal
{
    Devel::Bug->import(out => *TESTOUT, color => '', vc => 'red');
    reset_capture();
    my $in;
    ($in = bug('c') = 42);
    unlike $buf, qr/\e\[/, 'color=AUTO produces no ANSI codes to non-terminal';
}

# color => 'auto' (AUTO): string form accepted, same as ''
{
    Devel::Bug->import(out => *TESTOUT, color => 'auto', vc => 'red');
    reset_capture();
    my $in;
    ($in = bug('c') = 42);
    unlike $buf, qr/\e\[/, "color='auto' produces no ANSI codes to non-terminal";
}

# color => 'on' (ON): string form accepted, same as 1
{
    Devel::Bug->import(out => *TESTOUT, color => 'on', vc => 'red');
    reset_capture();
    my $in;
    ($in = bug('c') = 42);
    like $buf, qr/\e\[/, "color='on' produces ANSI codes to non-terminal";
}

# color => 'off' (OFF): string form accepted, same as undef
{
    Devel::Bug->import(out => *TESTOUT, color => 'off', vc => 'red');
    reset_capture();
    my $in;
    ($in = bug('c') = 42);
    unlike $buf, qr/\e\[/, "color='off' produces no ANSI codes";
}

# ---------------------------------------------------------------------------
# delims option
# ---------------------------------------------------------------------------

# delims => 1 (ON): always parens, even when colored
{
    Devel::Bug->import(out => *TESTOUT, color => 1, vc => 'red', delims => 1);
    reset_capture();
    my $in;
    ($in = bug('p') = 42);
    like $buf, qr/\(/, 'delims=ON forces parens even when colored';
}

# delims => 'on' (ON): string form accepted, same as 1
{
    Devel::Bug->import(out => *TESTOUT, color => 1, vc => 'red', delims => 'on');
    reset_capture();
    my $in;
    ($in = bug('p') = 42);
    like $buf, qr/\(/, "delims='on' forces parens even when colored";
}

# delims => undef (OFF): never parens, even when not colored
{
    Devel::Bug->import(out => *TESTOUT, color => undef, delims => undef);
    reset_capture();
    my $in;
    ($in = bug('p') = 42);
    like   $buf, qr/p=42/, 'delims=OFF value still in output';
    unlike $buf, qr/\(/,   'delims=OFF suppresses parens';
}

# delims => 'off' (OFF): string form accepted, same as undef
{
    Devel::Bug->import(out => *TESTOUT, color => undef, delims => 'off');
    reset_capture();
    my $in;
    ($in = bug('p') = 42);
    unlike $buf, qr/\(/, "delims='off' suppresses parens";
}

# delims => '' (AUTO) + color=OFF: parens added (plain text needs delineation)
{
    Devel::Bug->import(out => *TESTOUT, color => undef, delims => '');
    reset_capture();
    my $in;
    ($in = bug('p') = 42);
    like $buf, qr/p=\(42\)/, 'delims=AUTO adds parens when not colored';
}

# delims => 'auto' (AUTO) + color=OFF: string form accepted, same as ''
{
    Devel::Bug->import(out => *TESTOUT, color => undef, delims => 'auto');
    reset_capture();
    my $in;
    ($in = bug('p') = 42);
    like $buf, qr/p=\(42\)/, "delims='auto' adds parens when not colored";
}

# delims => '' (AUTO) + color=ON: no parens (color delineates value)
{
    Devel::Bug->import(out => *TESTOUT, color => 1, vc => 'red', delims => '');
    reset_capture();
    my $in;
    ($in = bug('p') = 42);
    unlike $buf, qr/\(/, 'delims=AUTO suppresses parens when colored';
}

# delims=OFF does not suppress parens for multiline (delims still driven by $ml)
# Wait: delims=OFF means OFF regardless of multiline.
{
    Devel::Bug->import(out => *TESTOUT, color => undef, delims => undef, multiline => 1);
    reset_capture();
    my @in;
    (@in = (bug 'p') = (1, 2, 3));
    unlike $buf, qr/\(/, 'delims=OFF suppresses parens even with multiline';
}

# ---------------------------------------------------------------------------
# terminal path: mock _isTerm + _sttyWidth to simulate terminal output
# ---------------------------------------------------------------------------

# delims=ON + terminal: parens even when color=AUTO would suppress them
{
    Devel::Bug->import(out => *TESTOUT, color => '', vc => 'red', delims => 1);
    reset_capture();
    no warnings 'redefine';
    local *Devel::Bug::_isTerm    = sub { 1 };
    local *Devel::Bug::_sttyWidth = sub { 80 };
    my $in;
    ($in = bug('p') = 42);
    like $buf, qr/\(/, 'delims=ON holds on terminal regardless of color';
}

# delims=OFF + terminal: no parens
{
    Devel::Bug->import(out => *TESTOUT, color => undef, delims => undef);
    reset_capture();
    no warnings 'redefine';
    local *Devel::Bug::_isTerm    = sub { 1 };
    local *Devel::Bug::_sttyWidth = sub { 80 };
    my $in;
    ($in = bug('p') = 42);
    unlike $buf, qr/\(/, 'delims=OFF holds on terminal regardless of color';
}

# color=OFF + terminal: no ANSI codes
{
    Devel::Bug->import(out => *TESTOUT, color => undef, vc => 'red');
    reset_capture();
    no warnings 'redefine';
    local *Devel::Bug::_isTerm    = sub { 1 };
    local *Devel::Bug::_sttyWidth = sub { 80 };
    my $in;
    ($in = bug('c') = 42);
    unlike $buf, qr/\e\[/, 'color=OFF produces no ANSI codes on terminal';
}

# color=AUTO + terminal: ANSI codes applied
{
    Devel::Bug->import(out => *TESTOUT, color => '', vc => 'red');
    reset_capture();
    no warnings 'redefine';
    local *Devel::Bug::_isTerm    = sub { 1 };
    local *Devel::Bug::_sttyWidth = sub { 80 };
    my $in;
    ($in = bug('c') = 42);
    like $buf, qr/\e\[/, 'color=AUTO produces ANSI codes on terminal';
}

# color=ON + terminal: ANSI codes applied
{
    Devel::Bug->import(out => *TESTOUT, color => 1, vc => 'red');
    reset_capture();
    no warnings 'redefine';
    local *Devel::Bug::_isTerm    = sub { 1 };
    local *Devel::Bug::_sttyWidth = sub { 80 };
    my $in;
    ($in = bug('c') = 42);
    like $buf, qr/\e\[/, 'color=ON produces ANSI codes on terminal';
}

# ---------------------------------------------------------------------------
# noterm option
# ---------------------------------------------------------------------------

# baseline: color=AUTO on mocked terminal produces ANSI codes
{
    Devel::Bug->import(out => *TESTOUT, color => '', vc => 'red');
    reset_capture();
    no warnings 'redefine';
    local *Devel::Bug::_isTerm    = sub { 1 };
    local *Devel::Bug::_sttyWidth = sub { 80 };
    my $in;
    ($in = bug('c') = 42);
    like $buf, qr/\e\[/, 'color=AUTO on terminal produces ANSI codes (baseline)';
}

# noterm=1 suppresses terminal detection: color=AUTO stays uncolored
{
    Devel::Bug->import(out => *TESTOUT, color => '', vc => 'red', noterm => 1);
    reset_capture();
    no warnings 'redefine';
    local *Devel::Bug::_isTerm    = sub { 1 };
    local *Devel::Bug::_sttyWidth = sub { 80 };
    my $in;
    ($in = bug('c') = 42);
    unlike $buf, qr/\e\[/, 'noterm=1 suppresses terminal detection for color=AUTO';
}

# noterm=1 does not suppress color=ON
{
    Devel::Bug->import(out => *TESTOUT, color => 1, vc => 'red', noterm => 1);
    reset_capture();
    my $in;
    ($in = bug('c') = 42);
    like $buf, qr/\e\[/, 'noterm=1 does not suppress color=ON';
}

# ---------------------------------------------------------------------------
# terminal width detection cascade: stty → Term::Size::Perl
# Simulate unavailability via an @INC hook that blocks Term/Size/Perl.pm.
# ---------------------------------------------------------------------------
{
    my $attempts = 0;

    my $block = sub {
        return unless $_[1] eq 'Term/Size/Perl.pm';
        $attempts++;
        die "Term::Size::Perl not available\n";
    };

    # noterm=1: detection skipped entirely — neither stty nor Term::Size::Perl attempted
    {
        no warnings 'redefine';
        local *Devel::Bug::_isTerm    = sub { 1 };
        local *Devel::Bug::_sttyWidth = sub { 0 };
        $attempts = 0;
        delete local $INC{'Term/Size/Perl.pm'};
        local @INC = ($block, @INC);

        Devel::Bug->import(out => *TESTOUT, color => '', vc => 'red', noterm => 1);
        reset_capture();
        my $in;
        ($in = bug('c') = 42);
        is     $attempts, 0,       'noterm=1: Term::Size::Perl not attempted';
        unlike $buf,      qr/\e\[/,'noterm=1: no colors (termW=0)';
        is     $in,       42,      'noterm=1: value passes through';
    }

    # stty works: Term::Size::Perl not attempted
    {
        no warnings 'redefine';
        local *Devel::Bug::_isTerm    = sub { 1 };
        local *Devel::Bug::_sttyWidth = sub { 80 };
        $attempts = 0;
        delete local $INC{'Term/Size/Perl.pm'};
        local @INC = ($block, @INC);

        Devel::Bug->import(out => *TESTOUT, color => '', vc => 'red');
        reset_capture();
        my $in;
        ($in = bug('c') = 42);
        is   $attempts, 0,      'stty works: Term::Size::Perl not attempted';
        like $buf,      qr/\e\[/,'stty works: terminal detected, colors applied';
    }

    # stty fails, Term::Size::Perl works: termW from Term::Size::Perl
    {
        no warnings 'redefine';
        local *Devel::Bug::_isTerm    = sub { 1 };
        local *Devel::Bug::_sttyWidth = sub { 0 };
        local *Devel::Bug::_tspWidth  = sub { 80 };

        Devel::Bug->import(out => *TESTOUT, color => '', vc => 'red');
        reset_capture();
        my $in;
        ($in = bug('c') = 42);
        like $buf, qr/\e\[/, 'stty fails, Term::Size::Perl works: colors applied';
    }

    # stty fails, Term::Size::Perl unavailable: termW=0, carp fired
    {
        no warnings 'redefine';
        local *Devel::Bug::_isTerm    = sub { 1 };
        local *Devel::Bug::_sttyWidth = sub { 0 };
        $attempts = 0;
        delete local $INC{'Term/Size/Perl.pm'};
        local @INC = ($block, @INC);

        Devel::Bug->import(out => *TESTOUT, color => '', vc => 'red');
        reset_capture();
        my $in;
        my $warned = '';
        local $SIG{__WARN__} = sub { $warned .= $_[0] };
        ($in = bug('c') = 42);
        is     $attempts, 1,                    'stty fails, Term::Size::Perl unavailable: require attempted';
        unlike $buf,      qr/\e\[/,             'stty fails, Term::Size::Perl unavailable: no colors (termW=0)';
        is     $in,       42,                   'value passes through';
        like   $warned,   qr/Term::Size::Perl/, 'stty fails, Term::Size::Perl unavailable: carp fired';
    }
}

# ---------------------------------------------------------------------------
# aliases for delims
# ---------------------------------------------------------------------------

ok lives { Devel::Bug->import(out => *STDERR, delimiters => 1) }, "alias 'delimiters' accepted";
ok lives { Devel::Bug->import(out => *STDERR, d          => 1) }, "alias 'd' accepted";

done_testing;
