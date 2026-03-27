use strict;
use warnings;
use Test::More;
use Loo;

# ── Colour output is longer than plain ────────────────────────────
{
    my $dd = Loo->new([42]);
    $dd->{use_colour} = 1;
    my $coloured = $dd->Dump;
    my $stripped = Loo::strip_colour($coloured);

    cmp_ok(length($coloured), '>', length($stripped),
           'coloured output longer than stripped');
    is($stripped, "\$VAR1 = 42;\n", 'stripped matches plain output');
}

# ── Colour in array ──────────────────────────────────────────────
{
    my $dd = Loo->new([[1, 'hello']]);
    $dd->{use_colour} = 1;
    my $coloured = $dd->Dump;
    my $stripped = Loo::strip_colour($coloured);

    like($coloured, qr/\e\[/, 'array: ANSI escapes present');
    like($stripped, qr/1/, 'array stripped: value present');
    like($stripped, qr/'hello'/, 'array stripped: string present');
}

# ── Colour in hash ───────────────────────────────────────────────
{
    my $dd = Loo->new([{a => 1}]);
    $dd->{use_colour} = 1;
    $dd->Sortkeys(1);
    my $coloured = $dd->Dump;
    my $stripped = Loo::strip_colour($coloured);

    like($coloured, qr/\e\[/, 'hash: ANSI escapes present');
    like($stripped, qr/'a' => 1/, 'hash stripped: correct content');
}

# ── ncDump forces no colour ──────────────────────────────────────
{
    my $dd = Loo->new([42]);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    unlike($out, qr/\e\[/, 'no colour: no ANSI escapes');
}

# ── Theme switching ───────────────────────────────────────────────
{
    my $dd = Loo->new([42]);
    $dd->{use_colour} = 1;
    $dd->Theme('monokai');
    my $monokai = $dd->Dump;

    $dd->Theme('default');
    my $default = $dd->Dump;

    my $s_monokai = Loo::strip_colour($monokai);
    my $s_default = Loo::strip_colour($default);
    is($s_monokai, $s_default, 'different themes same stripped output');

    cmp_ok(length($monokai), '>', length($s_monokai),
           'monokai theme produces colour');
}

# ── Colour in deparsed code ───────────────────────────────────────
{
    my $dd = Loo->new([sub { return 1 }]);
    $dd->{use_colour} = 1;
    $dd->Deparse(1);
    my $coloured = $dd->Dump;
    my $stripped = Loo::strip_colour($coloured);

    cmp_ok(length($coloured), '>', length($stripped),
           'deparsed code: colour present');
    like($stripped, qr/sub \{/, 'deparsed code stripped: has sub');
    like($stripped, qr/return/, 'deparsed code stripped: has return');
}

done_testing;
