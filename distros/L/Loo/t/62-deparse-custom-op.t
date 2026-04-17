use strict;
use warnings;
use Test::More;

use Loo qw(dDump ncDump);

# Custom ops require Perl 5.14+ and Shannon::Entropy::XS for a real-world
# custom op registered via XOP + call checker.
BEGIN {
    plan skip_all => 'Custom ops require Perl 5.14+'
        if $] < 5.014;
    eval { require Shannon::Entropy::XS; Shannon::Entropy::XS->import('entropy') };
    plan skip_all => 'Shannon::Entropy::XS not available'
        if $@;
}

# ── Basic: custom op name is recovered ───────────────────────────
{
    my $sub = sub { entropy("hello") };
    my $out = dDump($sub);
    like($out, qr/entropy\(/, 'custom op name "entropy" appears in deparse');
    like($out, qr/'hello'/, 'custom op argument is deparsed');
}

# ── Custom op in assignment context ──────────────────────────────
{
    my $sub = sub { my $x = entropy("test"); return $x };
    my $out = dDump($sub);
    like($out, qr/my \$x = entropy\('test'\)/, 'custom op in assignment context');
    like($out, qr/return \$x/, 'return after custom op assignment');
}

# ── Custom op with variable argument ─────────────────────────────
{
    my $sub = sub { my $s = "data"; entropy($s) };
    my $out = dDump($sub);
    like($out, qr/entropy\(\$s\)/, 'custom op with lexical variable argument');
}

# ── OO interface with Deparse ────────────────────────────────────
{
    my $sub = sub { entropy("oo test") };
    my $loo = Loo->new([$sub]);
    $loo->{use_colour} = 0;
    $loo->Deparse(1);
    my $out = $loo->Dump;
    like($out, qr/entropy\(/, 'OO deparse: custom op name present');
    like($out, qr/'oo test'/, 'OO deparse: argument present');
}

# ── Colour vs no-colour consistency ──────────────────────────────
{
    my $sub = sub { my $v = entropy("colour"); return $v };

    my $dd_c = Loo->new([$sub]);
    $dd_c->{use_colour} = 1;
    $dd_c->Deparse(1);
    my $coloured = $dd_c->Dump;

    my $dd_nc = Loo->new([$sub]);
    $dd_nc->{use_colour} = 0;
    $dd_nc->Deparse(1);
    my $plain = $dd_nc->Dump;

    my $stripped = Loo::strip_colour($coloured);
    is($stripped, $plain, 'custom op: stripped coloured matches plain');
}

# ── Multiple custom op calls in one sub ──────────────────────────
{
    my $sub = sub {
        my $a = entropy("first");
        my $b = entropy("second");
        return $a + $b;
    };
    my $out = dDump($sub);
    my @matches = ($out =~ /entropy\(/g);
    is(scalar @matches, 2, 'two custom op calls both deparsed');
}

done_testing;
