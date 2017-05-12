use strict;
use warnings;

use Test::More (tests => 29);
use Test::NoWarnings;

use lib qw(lib);

use_ok('Math::NumberBase');

# constructor test
{
    my $base = Math::NumberBase->new();
    isa_ok($base, 'Math::NumberBase');
    is($base->get_base(), 10, 'got default base');
    is_deeply($base->get_symbols(), [qw(0 1 2 3 4 5 6 7 8 9)], 'got default symbols for default base');

    $base = Math::NumberBase->new(4, 'abcd');
    is($base->get_base(), 4, 'got passed base number');
    is_deeply($base->get_symbols(), [qw(a b c d)], 'got passed symbols');
    is_deeply(
        $base->get_symbol_value_map(), 
        {
            'a' => 0,
            'b' => 1,
            'c' => 2,
            'd' => 3
        }, 
        'got symbol => value map from the passed symbols'
    );

    eval { Math::NumberBase->new(-2); };
    like($@, qr/^\$base can not be less than 2/, 'die when $base less than 2');

    eval { Math::NumberBase->new(3.2); };
    like($@, qr/^\$base must be an integer/, 'die when $base is not an integer');

    eval { Math::NumberBase->new(37); };
    like(
        $@, 
        qr/^Can not guess what should be the \$symbols when \$base > 36 and \$symbols is not defined/, 
        'die when $base is greater than 36 but $symbols is not defined'
    );

    eval { Math::NumberBase->new(2, '012'); };
    like($@, qr/\$symbols length is not equal to \$base/, 'die when $symbols length is not equal to $base');

    eval { Math::NumberBase->new(4, '0112'); };
    like($@, qr/\$symbols contains duplicate\(s\)/, 'die when $symbols contains duplicate(s)');
}

foreach my $test (
    #base   symbols                 number_in_decimal   number_in_base_x
    [16,    undef,                  16,                 '10'            ],
    [16,    '0123456789QWERTY',     773037414154,       'W3YE9TR70Q'    ],
    [10,    '9876543210',           1234567890,         '8765432109'    ],
    [4,     'BLAH',                 4,                  'LB'            ],
) {
    my ($base, $symbols, $number_in_decimal, $number_in_base_x) = @$test;

    my $number_base = Math::NumberBase->new($base, $symbols);
    is(
        $number_base->to_decimal($number_in_base_x), 
        $number_in_decimal, 
        "$number_in_base_x becomes $number_in_decimal"
    );
    is(
        $number_base->from_decimal($number_in_decimal), 
        $number_in_base_x, 
        "$number_in_decimal becomes $number_in_base_x"
    );

    my $base7 = Math::NumberBase->new(7, 'qwertyu');
    my $number_in_base7 = $number_base->convert_to($number_in_base_x, $base7);
    is(
        $base7->to_decimal($number_in_base7), 
        $number_in_decimal, 
        "$number_in_base_x converted to $number_in_base7 in base 7"
    );
    is(
        $number_base->convert_from($number_in_base7, $base7), 
        $number_in_base_x, 
        "$number_in_base_x converted from $number_in_base7 in base 7"
    );
}
