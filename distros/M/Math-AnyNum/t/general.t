#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 116;

{
    use Math::AnyNum qw(:overload);

    is(ref(42), 'Math::AnyNum');
    like(sqrt(42),   qr/^6\.480740698407860230965967436087996\d*\z/);
    like(sqrt(-1),   qr/^i\z/);
    like(sqrt(-3.5), qr/^1\.87082869338697069279187436\d*i\z/);

    # False values
    ok(!0);
    ok(!(0.0));
    ok(!(0 / 3));
    ok(!NaN);
    ok(!(NaN + 4 * i));
    ok(!(4 * i + NaN));
    ok(!(0 * i));
    ok(!(0 + 0 * i));

    # True values
    ok(!!(1));
    ok(!!(3.41));
    ok(!!(3 + 4 * i));
    ok(!!(4 * i));
    ok(!!(3 + 0 * i));
    ok(!!(3 / 4));
    ok(!!(-3 / 4));

    ok((Math::AnyNum->new('0.1') + Math::AnyNum->new('0.2')) == Math::AnyNum->new_f('0.3'));
    ok((Math::AnyNum->new('0.01') + Math::AnyNum->new('0.02')) == Math::AnyNum->new_f('0.03'));
    ok((Math::AnyNum->new('0.001') + Math::AnyNum->new('0.002')) == Math::AnyNum->new_f('0.003'));

    my $x = -2;
    like($x->sqrt, qr/^1\.4142135623730950488016\d*i\z/);
    ok($x == -2);

    my $z = 42;
    is(-$z, "-42");
    like(-sqrt(sqrt($z)), qr/^-2\.5457298950218305182697889605762886\d*\z/);

    is(-(3 + 4 * sqrt(-1)), -3 - 4 * sqrt(-1));

    is(3.0000, 3);
    is(1e3,    1000);

    # Addition
    is(5 + 18, 23);
    like(sqrt(2) + sqrt(3),   qr/^3\.1462643699419723423291350657155704455\d*\z/);
    like(sqrt(-5) + sqrt(-2), qr/^3\.65028153987288474521086239294097431\d*i\z/);

    like(3 + sqrt(2), qr/^4\.414213562373095048801\d*\z/);
    like(sqrt(2) + 3, qr/^4\.414213562373095048801\d*\z/);

    # Overloaded constants
    is(9475632169135683520444551629250785939312732016903426588732995012037887035065279608177193340166382911,
        '9475632169135683520444551629250785939312732016903426588732995012037887035065279608177193340166382911');

    is(1238123_8126379123123_213, '12381238126379123123213');
    is(1238_12213,                '123812213');
    is(12_001,                    '12001');

    is(0x2A,      '42');
    is(0x2_a,     '42');
    is(05_2,      '42');
    is(0b1,       '1');
    is(01234,     '668');
    is(01_234,    '668');
    is(0b11_11_1, '31');

#<<<
    #~ {
        #~ no warnings;

        #~ is(0b11111111111111111111111111111111111_1111,                                    '549755813887');
        #~ is(0b111111111_1111___11111100111__10_0011111_11110111111_11111111111111111_1111, '36893434408654077951');
        #~ is(0b__,                                                                          '0');
        #~ is(0x__,                                                                          '0');
        #~ is(0__,                                                                           '0');
    #~ }
#>>>

    # Complex numbers
    is(Math::AnyNum->new('3+4i'),     '3+4i');
    is(Math::AnyNum->new('-i'),       '-i');
    is(Math::AnyNum->new('i'),        'i');
    is(Math::AnyNum->new('-1i'),      '-i');
    is(Math::AnyNum->new('-0i'),      '0');
    is(Math::AnyNum->new('0i'),       '0');
    is(Math::AnyNum->new('+i'),       'i');
    is(Math::AnyNum->new('+1i'),      'i');
    is(Math::AnyNum->new('2i'),       '2i');
    is(Math::AnyNum->new('-2i'),      '-2i');
    is(Math::AnyNum->new('0-2i'),     '-2i');
    is(Math::AnyNum->new('-0-2i'),    '-2i');
    is(Math::AnyNum->new('3.5-2.5i'), '3.5-2.5i');
    is(Math::AnyNum->new('3.5-2i'),   '3.5-2i');
    is(Math::AnyNum->new('-3.5+2i'),  '-3.5+2i');
    is(Math::AnyNum->new('-2-3.5i'),  '-2-3.5i');

    #is(Math::AnyNum->new('1/2+3i'),     '0.5+3i');        # not supported yet
    #is(Math::AnyNum->new('1/2-5/8i'),   '0.5-0.625i');    # =//=
    #is(Math::AnyNum->new('-1/2-13.2i'), '-0.5-13.2i');    # =//=

    is(Math::AnyNum->new('1e3-1e2i'),          '1000-100i');
    is(Math::AnyNum->new('1.42e-3-1.42e-3i'),  '0.00142-0.00142i');
    is(Math::AnyNum->new('-1.42e-3-1.42e-3i'), '-0.00142-0.00142i');
    is(Math::AnyNum->new('1.42e+3-1.42e+3i'),  '1420-1420i');
    is(Math::AnyNum->new('1.42e+3+1.42e+3i'),  '1420+1420i');
    is(Math::AnyNum->new('-1.42e-3i'),         '-0.00142i');
    is(Math::AnyNum->new('1.42e-3i'),          '0.00142i');
    is(Math::AnyNum->new('+1.42e-3i'),         '0.00142i');

    is(Math::AnyNum->new('-3-i'),  '-3-i');
    is(Math::AnyNum->new('-3+i'),  '-3+i');
    is(Math::AnyNum->new('-3+0i'), '-3');
    is(Math::AnyNum->new('-3-0i'), '-3');
    is(Math::AnyNum->new('3+i'),   '3+i');
    is(Math::AnyNum->new('3-i'),   '3-i');
    is(Math::AnyNum->new('3-1i'),  '3-i');
    is(Math::AnyNum->new('3+0i'),  '3');

    # With extra-spaces
    is(Math::AnyNum->new('3 + 4i'),    '3+4i');
    is(Math::AnyNum->new('-3.5 - 4i'), '-3.5-4i');

    # Special values
    is(Math::AnyNum->new('-1.42e-3'), '-0.00142');
    is(Math::AnyNum->new('42/12'),    '7/2');
    is(Math::AnyNum->new('12.34'),    '12.34');
    is(Math::AnyNum->new('0/0'),      'NaN');
    is(Math::AnyNum->new('0/0', 36),  'NaN');
    is(Math::AnyNum->new('-1/0', 36), '-Inf');
    is(Math::AnyNum->new('1/0', 36),  'Inf');
    is(Math::AnyNum->new('1/0'),      'Inf');
    is(Math::AnyNum->new('-2/0'),     '-Inf');
    is(Math::AnyNum->new('-2/'),      'NaN');
    is(Math::AnyNum->new('1/'),       'NaN');
    is(Math::AnyNum->new('/'),        'NaN');
    is(Math::AnyNum->new('0/'),       'NaN');
    is(Math::AnyNum->new('/2'),       'NaN');
    is(Math::AnyNum->new('/0'),       'NaN');

    is(Math::AnyNum->new('-2/0', 36), '-Inf');
    is(Math::AnyNum->new('-2/',  36), 'NaN');
    is(Math::AnyNum->new('1/',   36), 'NaN');
    is(Math::AnyNum->new('/',    36), 'NaN');
    is(Math::AnyNum->new('0/',   36), 'NaN');
    is(Math::AnyNum->new('/2',   36), 'NaN');
    is(Math::AnyNum->new('/0',   36), 'NaN');

    is(Math::AnyNum->new('000/000', 16), 'NaN');
    is(Math::AnyNum->new('dfp/abc', 12), 'NaN');
    is(Math::AnyNum->new('hi'),          'NaN');
    is(Math::AnyNum->new('-0/0'),        'NaN');
    is(Math::AnyNum->new('1234'),        '1234');
    is(Math::AnyNum->new('-1234'),       '-1234');
    is(Math::AnyNum->new('ff', 16),      '255');
    is(Math::AnyNum->new('ff/ae', 16),   '85/58');

    # Tests for a leading plus sign
    is(Math::AnyNum->new('+3/4'),       '3/4');
    is(Math::AnyNum->new('+3/4', 36),   '3/4');
    is(Math::AnyNum->new('+ff/aa', 36), '3/2');
    is(Math::AnyNum->new('+ff', 36),    '555');
    is(Math::AnyNum->new('+42'),        '42');
    is(Math::AnyNum->new('+42', 16),    '66');

    # Stringification of very small values
    like(1 / exp(Math::AnyNum->new('459')), qr/^4\.5586138580111498673250123473364\d*e-200\z/);
}
