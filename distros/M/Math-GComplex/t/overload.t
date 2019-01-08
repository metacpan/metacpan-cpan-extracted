#!perl -T

use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 94;

use Math::GComplex qw(:overload acos cosh pown powmod);

{
    my @A097691 = qw(8 56 551 6930 105937 1905632 39424240);    # https://oeis.org/A097691

    foreach my $n (3 .. 9) {
#<<<
        my $y = abs((2**(-$n) * (sqrt(4 - $n**2) + i * $n)**$n - 2**$n * (-sqrt(4 - $n**2) - i * $n)**(-$n)) / sqrt(4 - $n**2));
        is(sprintf('%.0f', $y), shift(@A097691), "a($n) = $y");
#>>>
    }
}

{
    my @A105309 = qw(1 1 2 5 9 20 41 85 178 369 769);           # https://oeis.org/A105309

    foreach my $n (0 .. $#A105309) {
#<<<
        my $y = abs((((sqrt(4 * i - 1) + i)**($n + 1) - (i - sqrt(4 * i - 1))**($n + 1)) / 2**($n + 1) / sqrt(4 * i - 1))**2);
        is(sprintf('%.0f', $y), shift(@A105309), "a($n) = $y");
#>>>
    }
}

{
    my @A001541 = qw(1 3 17 99 577 3363 19601 114243 665857);    # https://oeis.org/A001541

    foreach my $n (0 .. $#A001541) {

        my $t = shift(@A001541);

        my $x = cos($n * acos(3));
        my $y = cosh($n * log(3 + 2 * sqrt(2)));

        is(sprintf('%.0f', abs($x)), $t, "a($n) = $x");
        is(sprintf('%.0f', abs($y)), $t, "a($n) = $y");
    }
}

{
    # Each component of a complex number is another complex number (with imaginary part = 0)
    my $x = Math::GComplex->new(-3, -4);
    my $y = Math::GComplex->new(-7, -5);

    my $z = atan2($x, $y);

    is(ref($z->real), 'Math::GComplex');
    is(ref($z->imag), 'Math::GComplex');

    like($z->real->real, qr/^-2\.6255065752\d*\z/);
    like($z->imag->real, qr/^0\.13446357403\d*\z/);

    ok(abs($z->real->imag - 0) <= 1e-10);
    ok(abs($z->imag->imag - 0) <= 1e-10);

    my $z2 = atan2(-3 - 4 * i, -7 - 5 * i);

    like($z2->real, qr/^-2\.6255065752\d*\z/);
    like($z2->imag, qr/^0\.13446357403\d*\z/);
}

{
    my @A281964 = qw(1 2 4 16 104 624 3648 29184);
    my @A282132 = qw(0 1 3 6 30 300 2100 11760);

    my $sum  = 0;
    my $fact = 1;

    foreach my $k (1 .. scalar(@A281964)) {
        $fact *= $k;

        $sum += i->pown($k - 1) / $k;
        my $t = $sum * $fact;

        is($t->real, shift(@A281964));
        is($t->imag, shift(@A282132));
    }
}

{
    is(pown(0, 0),  1);
    is(pown(0, 3),  0);
    is(pown(1, 5),  1);
    is(pown(1, -5), 1);
    is(pown(2, -5), 0.03125);

    my $n = 2 + 3 * i;
    is($n->pown('10'), -341525 - 145668 * i);
    is($n->pown(10),   -341525 - 145668 * i);

    is((3 + 4 * i)->pown(7), 76443 + 16124 * i);
    is((3 + 4 * i)->pown(8), 164833 + 354144 * i);
}

{
    my $z = 13 + 34 * i;
    my $t = 24 + 97 * i;

    is($z >> 1, 6 + 17 * i);
    is($z << 3, 104 + 272 * i);

    is($z | $t, 29 + 99 * i);
    is($z & $t, 8 + 32 * i);
    is($z ^ $t, 21 + 67 * i);
}

{
    is(join(' ', powmod(2 + i,  100, 1234567)->reals), '498832 667730');
    is(join(' ', powmod(-2 -i,  99,  1234567)->reals), '160748 820328');
    is(join(' ', powmod(2 -i,   99,  1234567)->reals), '1073819 820328');
    is(join(' ', powmod(-2 + i, 99,  1234567)->reals), '160748 414239');

    is(powmod(2, 96, 97), 1);
    is(powmod(2, 43, 43), 2);
    is(powmod(i, 43, 43), 0 + 42 * i);
    is(powmod(i, 42, 43), 42);

    is(powmod(1 -i,  43 - 1, 43),         i);
    is(powmod(1 -i,  43 - 1, 43 + 3 * i), 36 + 14 * i);
    is(powmod(2 + i, 43,     43 + 3 * i), 39 + 44 * i);
}

is(join(' ', Math::GComplex::invmod(42,           2017)->reals),    '1969 0');
is(join(' ', Math::GComplex::invmod(3 + 4 * i,    2017)->reals),    '1291 968');
is(join(' ', Math::GComplex::invmod(91 + 23 * i,  2017)->reals),    '590 405');
is(join(' ', Math::GComplex::invmod(43 + 99 * i,  1234567)->reals), '1019551 667302');
is(join(' ', Math::GComplex::invmod(43 + 415 * i, 103)->reals),     '88 25');

is(join(' ', Math::GComplex::gcd(135 - 14 * i, 155 + 34 * i)->reals), '5 12');
is(join(' ', Math::GComplex::gcd(155 + 34 * i, 135 - 14 * i)->reals), '5 12');

{
    my $m = 2019;
    my $x = 3 + 4 * i;

    my $x1 = Math::GComplex::powmod($x, -42, $m);
    my $x2 = Math::GComplex::powmod($x, 42,  $m);

    is(join(' ', $x1->reals), '1520 1407');
    is(join(' ', $x2->reals), '305 1212');
}
