use strict;
use warnings;
use Test::More;
use Loo;

# ── Basic strip ───────────────────────────────────────────────────
{
    my $coloured = "\e[32mhello\e[0m \e[31mworld\e[0m";
    is(Loo::strip_colour($coloured), 'hello world', 'strip basic ANSI');
}

# ── Pass-through for plain text ───────────────────────────────────
{
    is(Loo::strip_colour('no colour'), 'no colour', 'strip: plain passthrough');
}

# ── Empty string ──────────────────────────────────────────────────
{
    is(Loo::strip_colour(''), '', 'strip: empty string');
}

# ── Multiple escapes ─────────────────────────────────────────────
{
    my $s = "\e[1m\e[32mbold green\e[0m normal \e[34mblue\e[0m";
    is(Loo::strip_colour($s), 'bold green normal blue', 'strip multiple escapes');
}

# ── Round-trip: coloured dump → strip → matches plain ─────────────
{
    my $dd_c = Loo->new([{a => [1, 'x']}]);
    $dd_c->{use_colour} = 1;
    $dd_c->Sortkeys(1);
    my $coloured = $dd_c->Dump;

    my $dd_p = Loo->new([{a => [1, 'x']}]);
    $dd_p->{use_colour} = 0;
    $dd_p->Sortkeys(1);
    my $plain = $dd_p->Dump;

    my $stripped = Loo::strip_colour($coloured);
    is($stripped, $plain, 'round-trip: strip(coloured) eq plain');
}

# ── Strip on already-plain text is idempotent ─────────────────────
{
    my $plain = "\$VAR1 = 42;\n";
    is(Loo::strip_colour($plain), $plain, 'strip idempotent on plain');
}

done_testing;
