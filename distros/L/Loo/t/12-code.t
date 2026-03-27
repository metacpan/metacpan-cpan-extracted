use strict;
use warnings;
use Test::More;
use Loo;

# ── Code ref without deparse ──────────────────────────────────────
{
    my $dd = Loo->new([sub { return 1 }]);
    $dd->{use_colour} = 0;
    $dd->Deparse(0);
    my $out = $dd->Dump;
    like($out, qr/sub \{ "DUMMY" \}/, 'code ref no deparse: DUMMY placeholder');
}

# ── Code ref with deparse ────────────────────────────────────────
{
    my $dd = Loo->new([sub { return 1 }]);
    $dd->{use_colour} = 0;
    $dd->Deparse(1);
    my $out = $dd->Dump;
    like($out, qr/sub \{/, 'deparsed code: has sub {');
    like($out, qr/return/, 'deparsed code: has return');
    like($out, qr/1/, 'deparsed code: has value 1');
    unlike($out, qr/DUMMY/, 'deparsed code: no DUMMY');
}

# ── Code ref in data structure ────────────────────────────────────
{
    my $dd = Loo->new([[sub { return 2 }]]);
    $dd->{use_colour} = 0;
    $dd->Deparse(1);
    my $out = $dd->Dump;
    like($out, qr/\[\n.*sub \{/s, 'code in array: array wrapping');
    like($out, qr/return/, 'code in array: deparsed');
}

# ── Deparse with arithmetic ──────────────────────────────────────
{
    my $dd = Loo->new([sub { return $_[0] + $_[1] }]);
    $dd->{use_colour} = 0;
    $dd->Deparse(1);
    my $out = $dd->Dump;
    like($out, qr/\$_\[0\] \+ \$_\[1\]/, 'deparse arithmetic: $_[0] + $_[1]');
}

# ── Deparse with string concat ───────────────────────────────────
{
    my $dd = Loo->new([sub { return $_[0] . $_[1] }]);
    $dd->{use_colour} = 0;
    $dd->Deparse(1);
    my $out = $dd->Dump;
    like($out, qr/\$_\[0\] \. \$_\[1\]/, 'deparse concat: $_[0] . $_[1]');
}

# ── Deparse with ternary ─────────────────────────────────────────
{
    my $dd = Loo->new([sub { return $_[0] ? 1 : 0 }]);
    $dd->{use_colour} = 0;
    $dd->Deparse(1);
    my $out = $dd->Dump;
    like($out, qr/\? 1 : 0/, 'deparse ternary');
}

# ── Deparse with my variable ─────────────────────────────────────
{
    my $dd = Loo->new([sub { my $x = 10; return $x + 1 }]);
    $dd->{use_colour} = 0;
    $dd->Deparse(1);
    my $out = $dd->Dump;
    like($out, qr/my \$x = 10/, 'deparse my var');
    like($out, qr/\$x \+ 1/, 'deparse var use');
}

# ── Deparse with logical ops ─────────────────────────────────────
{
    my $dd = Loo->new([sub { return $_[0] && $_[1] }]);
    $dd->{use_colour} = 0;
    $dd->Deparse(1);
    my $out = $dd->Dump;
    like($out, qr/&&/, 'deparse logical and');
}

{
    my $dd = Loo->new([sub { return $_[0] || $_[1] }]);
    $dd->{use_colour} = 0;
    $dd->Deparse(1);
    my $out = $dd->Dump;
    like($out, qr/\|\|/, 'deparse logical or');
}

# ── Deparse with comparison ──────────────────────────────────────
{
    my $dd = Loo->new([sub { return $_[0] == 1 }]);
    $dd->{use_colour} = 0;
    $dd->Deparse(1);
    my $out = $dd->Dump;
    like($out, qr/==/, 'deparse equality');
}

# ── Deparse with negation ────────────────────────────────────────
{
    my $dd = Loo->new([sub { return -$_[0] }]);
    $dd->{use_colour} = 0;
    $dd->Deparse(1);
    my $out = $dd->Dump;
    like($out, qr/-\$_\[0\]/, 'deparse negation');
}

# ── Deparse with not ─────────────────────────────────────────────
{
    my $dd = Loo->new([sub { return !$_[0] }]);
    $dd->{use_colour} = 0;
    $dd->Deparse(1);
    my $out = $dd->Dump;
    like($out, qr/!\$_\[0\]/, 'deparse not');
}

# ── Deparse with anonymous constructors ──────────────────────────
{
    my $dd = Loo->new([sub { my $h = {}; my $a = []; return [$h, $a] }]);
    $dd->{use_colour} = 0;
    $dd->Deparse(1);
    my $out = $dd->Dump;
    like($out, qr/\{\}/, 'deparse anon hash');
    like($out, qr/\[\]/, 'deparse anon empty array');
    like($out, qr/\[\$h, \$a\]/, 'deparse return anon array');
}

done_testing;
