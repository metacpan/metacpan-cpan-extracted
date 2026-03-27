use strict;
use warnings;
use Test::More;
use Loo;

# ── Deparse multiple code patterns ───────────────────────────────

my @patterns = (
    ['simple return',  sub { return 42 },               qr/return 42/],
    ['param add',      sub { return $_[0] + $_[1] },    qr/\$_\[0\] \+ \$_\[1\]/],
    ['ternary',        sub { return $_[0] ? 1 : 0 },    qr/\$_\[0\] \? 1 : 0/],
    ['logical and',    sub { return $_[0] && $_[1] },    qr/\$_\[0\] && \$_\[1\]/],
    ['logical or',     sub { return $_[0] || 'x' },      qr/\|\| 'x'/],
    ['defined or',     sub { return $_[0] // 'y' },      qr|// 'y'|],
    ['comparison',     sub { return $_[0] == 1 },        qr/\$_\[0\] == 1/],
    ['my var',         sub { my $x = 10; return $x },    qr/my \$x = 10/],
    ['negation',       sub { return -$_[0] },            qr/-\$_\[0\]/],
    ['not',            sub { return !$_[0] },            qr/!\$_\[0\]/],
    ['multiply',       sub { return $_[0] * $_[1] },    qr/\$_\[0\] \* \$_\[1\]/],
);

for my $pat (@patterns) {
    my ($name, $code, $re) = @$pat;
    my $dd = Loo->new([$code]);
    $dd->{use_colour} = 0;
    $dd->Deparse(1);
    my $out = $dd->Dump;
    like($out, qr/sub \{/, "$name: has sub {");
    like($out, $re, "$name: correct body");
}

# ── Deparse colour vs no-colour consistency ───────────────────────
{
    my $code = sub { return $_[0] + 1 };

    my $dd_c = Loo->new([$code]);
    $dd_c->{use_colour} = 1;
    $dd_c->Deparse(1);
    my $coloured = $dd_c->Dump;

    my $dd_nc = Loo->new([$code]);
    $dd_nc->{use_colour} = 0;
    $dd_nc->Deparse(1);
    my $plain = $dd_nc->Dump;

    my $stripped = Loo::strip_colour($coloured);
    is($stripped, $plain, 'deparse: stripped coloured eq plain');
}

done_testing;
