use strict;
use warnings;
use Test::More;
use Loo;

# ── _detect_colour with $USE_COLOUR override ─────────────────────
{
    local $Loo::USE_COLOUR = 1;
    is(Loo::_detect_colour(), 1, 'USE_COLOUR=1 returns 1');
}

{
    local $Loo::USE_COLOUR = 0;
    is(Loo::_detect_colour(), 0, 'USE_COLOUR=0 returns 0');
}

# ── _detect_colour with NO_COLOR env ─────────────────────────────
{
    local $Loo::USE_COLOUR;
    local $ENV{NO_COLOR} = '';
    is(Loo::_detect_colour(), 0, 'NO_COLOR set: returns 0');
}

{
    local $Loo::USE_COLOUR;
    local $ENV{NO_COLOR} = '1';
    is(Loo::_detect_colour(), 0, 'NO_COLOR=1: returns 0');
}

# ── _detect_colour with TERM=dumb ────────────────────────────────
{
    local $Loo::USE_COLOUR;
    delete local $ENV{NO_COLOR};
    local $ENV{TERM} = 'dumb';
    is(Loo::_detect_colour(), 0, 'TERM=dumb: returns 0');
}

# ── _detect_colour precedence: USE_COLOUR beats NO_COLOR ─────────
{
    local $Loo::USE_COLOUR = 1;
    local $ENV{NO_COLOR} = '';
    is(Loo::_detect_colour(), 1, 'USE_COLOUR=1 overrides NO_COLOR');
}

# ── _detect_colour precedence: USE_COLOUR beats TERM=dumb ────────
{
    local $Loo::USE_COLOUR = 1;
    local $ENV{TERM} = 'dumb';
    is(Loo::_detect_colour(), 1, 'USE_COLOUR=1 overrides TERM=dumb');
}

# ── _detect_colour with no overrides (non-TTY test harness) ──────
{
    local $Loo::USE_COLOUR;
    delete local $ENV{NO_COLOR};
    delete local $ENV{TERM};
    # Under test harness, STDOUT is not a TTY
    my $result = Loo::_detect_colour();
    ok($result == 0 || $result == 1, 'no overrides: returns 0 or 1');
}

done_testing;
