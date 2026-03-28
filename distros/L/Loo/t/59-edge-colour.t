use strict;
use warnings;
use Test::More;
use Loo qw(cDump ncDump);

# ── cDump produces ANSI codes for all value types ───────────────
{
    my $out = cDump(42);
    like($out, qr/\e\[/, 'cDump integer: has ANSI');
    is(Loo::strip_colour($out), "\$VAR1 = 42;\n", 'cDump integer: stripped matches plain');
}

{
    my $out = cDump('hello');
    like($out, qr/\e\[/, 'cDump string: has ANSI');
    is(Loo::strip_colour($out), "\$VAR1 = 'hello';\n", 'cDump string: stripped matches plain');
}

{
    my $out = cDump(undef);
    like($out, qr/\e\[/, 'cDump undef: has ANSI');
    is(Loo::strip_colour($out), "\$VAR1 = undef;\n", 'cDump undef: stripped matches plain');
}

{
    my $out = cDump([1, 'two']);
    like($out, qr/\e\[/, 'cDump array: has ANSI');
    my $stripped = Loo::strip_colour($out);
    like($stripped, qr/1/, 'cDump array: stripped has integer');
    like($stripped, qr/'two'/, 'cDump array: stripped has string');
}

{
    my $dd = Loo->new([{a => 1}]);
    $dd->{use_colour} = 1;
    $dd->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/\e\[/, 'cDump hash: has ANSI');
    my $stripped = Loo::strip_colour($out);
    like($stripped, qr/'a' => 1/, 'colour hash: stripped correct');
}

# ── Theme: monokai ──────────────────────────────────────────────
{
    my $dd = Loo->new([{key => 'val'}]);
    $dd->{use_colour} = 1;
    $dd->Theme('monokai')->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/\e\[/, 'monokai theme: has ANSI');
    my $stripped = Loo::strip_colour($out);
    like($stripped, qr/'key' => 'val'/, 'monokai: stripped correct');
}

# ── Theme: light ────────────────────────────────────────────────
{
    my $dd = Loo->new([42]);
    $dd->{use_colour} = 1;
    $dd->Theme('light');
    my $out = $dd->Dump;
    like($out, qr/\e\[/, 'light theme: has ANSI');
    is(Loo::strip_colour($out), "\$VAR1 = 42;\n", 'light theme: stripped correct');
}

# ── Theme: none ─────────────────────────────────────────────────
{
    my $dd = Loo->new([42]);
    $dd->{use_colour} = 1;
    $dd->Theme('none');
    my $out = $dd->Dump;
    is($out, "\$VAR1 = 42;\n", 'none theme: no ANSI codes');
}

# ── strip_colour on string with no ANSI ────────────────────────
{
    my $plain = "hello world";
    is(Loo::strip_colour($plain), $plain, 'strip_colour: no-op on plain string');
}

# ── strip_colour on empty string ────────────────────────────────
{
    is(Loo::strip_colour(''), '', 'strip_colour: empty string');
}

# ── Colour consistency: cDump stripped == ncDump ────────────────
{
    my $data = {nested => [1, undef, 'str', qr/x/]};
    my $dd_c = Loo->new([$data]);
    $dd_c->{use_colour} = 1;
    $dd_c->Sortkeys(1);
    my $colour = $dd_c->Dump;

    my $dd_n = Loo->new([$data]);
    $dd_n->{use_colour} = 0;
    $dd_n->Sortkeys(1);
    my $plain = $dd_n->Dump;

    is(Loo::strip_colour($colour), $plain, 'colour stripped == plain for complex structure');
}

# ── Colour with blessed objects ─────────────────────────────────
{
    my $obj = bless {v => 1}, 'Coloured';
    my $out = cDump($obj);
    like($out, qr/\e\[/, 'colour blessed: has ANSI');
    my $stripped = Loo::strip_colour($out);
    like($stripped, qr/bless/, 'colour blessed: stripped has bless');
    like($stripped, qr/'Coloured'/, 'colour blessed: stripped has class');
}

done_testing;
