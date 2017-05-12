#!perl -T

use strict;
use warnings;

use Test::More tests => 32;
use Test::NoWarnings;
use Test::Differences;
BEGIN {
    use_ok 'Locale::Utils::PlaceholderMaketext';
}

my $obj = Locale::Utils::PlaceholderMaketext->new;

is_deeply
    [ $obj->expand_maketext(undef) ],
    [ undef ],
    'undef';

eq_or_diff
    $obj->expand_maketext(
        '[_1];[quant,_2,s];[quant,_3,s,p];[quant,_4,s,p,z]',
        undef,
        undef,
        'three',
        '4_234_567.890',
        4234567.890,
    ),
    ';0 s;0 p;z',
    'no strict array';

eq_or_diff
    $obj->expand_maketext(
        '[_1];[quant,_2,s];[quant,_3,s,p];[quant,_4,s,p,z]',
        [
            undef,
            undef,
            'three',
            '4_234_567.890',
            4234567.890,
        ],
    ),
    ';0 s;0 p;z',
    'no strict array_ref';

eq_or_diff
    $obj->expand_maketext(
        '~~;~[_1~];~[quant,_2,s~];~[*,_3,s,p~];~[#,4~]',
        1 .. 4,
    ),
    '~;[_1];[quant,_2,s];[*,_3,s,p];[#,4]',
    'escaped';

$obj->space(q{x});

eq_or_diff
    $obj->expand_maketext(
        '[quant,_1,s];[quant,_2,s,p]',
        1,
        2,
    ),
    '1xs;2xp',
    'space is x';

$obj->reset_space;
$obj->is_strict(1);

$obj->formatter_code(
    sub {
        my ($value, $type) = @_;

        $type eq 'numeric'
            or return $value;
        while ( $value =~ s{(\d+) (\d{3})}{$1,$2}xms ) {}
        $value =~ tr{.,}{,.};

        return $value;
    }
);

eq_or_diff
    $obj->expand_maketext(
        <<'EOT',
[_1]
[_2]
[_3]
[_4]
[_5]
[quant,_6,s]
[quant,_7,s]
[quant,_8,s]
[quant,_9,s]
[quant,_10,s]
EOT
        undef,
        'a',
        '3',
        '4234567.890',
        5234567.890,
        undef,
        'b',
        8,
        '9234567.890',
        10_234_567.890,
    ),
    <<'EOT',
[_1]
a
3
4.234.567,890
5.234.567,89
[quant,_6,s]
[quant,_7,s]
8 s
9.234.567,890 s
10.234.567,89 s
EOT
    'strict, numeric';

$obj->clear_formatter_code;

my @data = (
    {
        text   => '(1) foo [_1] bar [quant,_2,singular] baz [_3]',
        result => [
            '(1) foo and bar [quant,_2,singular] baz [_3]',
            '(1) foo and bar 0 singular baz [_3]',
            '(1) foo and bar 1 singular baz [_3]',
            '(1) foo and bar 2 singular baz [_3]',
        ],
    },
    {
        text   => '(2) foo [_1] bar [*,_2,singular] baz [_3]',
        result => [
            '(2) foo and bar [*,_2,singular] baz [_3]',
            '(2) foo and bar 0 singular baz [_3]',
            '(2) foo and bar 1 singular baz [_3]',
            '(2) foo and bar 2 singular baz [_3]',
        ],
    },
    {
        text   => '(3) foo [_1] bar [quant,_2,singular,plural] baz [_3]',
        result => [
            '(3) foo and bar [quant,_2,singular,plural] baz [_3]',
            '(3) foo and bar 0 plural baz [_3]',
            '(3) foo and bar 1 singular baz [_3]',
            '(3) foo and bar 2 plural baz [_3]',
        ],
    },
    {
        text   => '(4) foo [_1] bar [*,_2,singular,plural] baz [_3]',
        result => [
            '(4) foo and bar [*,_2,singular,plural] baz [_3]',
            '(4) foo and bar 0 plural baz [_3]',
            '(4) foo and bar 1 singular baz [_3]',
            '(4) foo and bar 2 plural baz [_3]',
        ],
    },
    {
        text   => '(5) foo [_1] bar [quant,_2,singular,plural,zero] baz [_3]',
        result => [
            '(5) foo and bar [quant,_2,singular,plural,zero] baz [_3]',
            '(5) foo and bar zero baz [_3]',
            '(5) foo and bar 1 singular baz [_3]',
            '(5) foo and bar 2 plural baz [_3]',
        ],
    },
    {
        text   => '(6) foo [_1] bar [*,_2,singular,plural,zero] baz [_3]',
        result => [
            '(6) foo and bar [*,_2,singular,plural,zero] baz [_3]',
            '(6) foo and bar zero baz [_3]',
            '(6) foo and bar 1 singular baz [_3]',
            '(6) foo and bar 2 plural baz [_3]',
        ],
    },
);

for my $data (@data) {
    my $index = 0;
    for my $number (undef, 0 .. 2) {
        my $defined_number
            = defined $number
            ? $number
            : 'undef';
        eq_or_diff
            $obj->expand_maketext(
                $data->{text},
                'and',
                $number,
            ),
            $data->{result}->[$index++],
            "'$data->{text}', 'and', $defined_number";
    }
}
