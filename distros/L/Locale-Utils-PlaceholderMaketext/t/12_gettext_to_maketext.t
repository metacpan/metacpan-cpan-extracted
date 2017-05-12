#!perl -T

use strict;
use warnings;

use Test::More tests => 21;
use Test::NoWarnings;
use Test::Differences;
BEGIN {
    use_ok 'Locale::Utils::PlaceholderMaketext';
}

my $obj = Locale::Utils::PlaceholderMaketext->new;

is_deeply
    [ $obj->gettext_to_maketext(undef) ],
    [ undef ],
    'undef';

my @data = (
    [
        q{},
        q{},
        'empty string',
    ],
    [
        'foo %1 bar',
        'foo [_1] bar',
        'placeholder',
    ],
    [
        '~ %% foo [_1] bar [%1] baz [%%1]',
        '~~ % foo ~[_1~] bar ~[[_1]~] baz ~[%1~]',
        'escaped placeholder',
    ],
    [
        'foo %1 bar %quant(%2,singluar,plural,zero) baz %#(%3)',
        'foo [_1] bar [quant,_2,singluar,plural,zero] baz [#,_3]',
        'function quant',
    ],
    [
        'foo [_1] bar [quant,_2,singluar,plural,zero] baz [#,_3]',
        'foo ~[_1~] bar ~[quant,_2,singluar,plural,zero~] baz ~[#,_3~]',
        'escaped function quant',
    ],
    [
        'bar %*(%2,singluar,plural) baz',
        'bar [*,_2,singluar,plural] baz',
        'function *',
    ],
    [
        'bar [*,_2,singluar,plural] baz',
        'bar ~[*,_2,singluar,plural~] baz',
        'escaped function *',
    ],
    [
        'baz %#(%3)',
        'baz [#,_3]',
        'function #',
    ],
    [
        'baz [#,_3]',
        'baz ~[#,_3~]',
        'escaped function #',
    ],
);

for my $data (@data) {
    eq_or_diff
        +Locale::Utils::PlaceholderMaketext->gettext_to_maketext( $data->[0] ),
        @{$data}[ 1, 2 ];
    eq_or_diff
        $obj->gettext_to_maketext( $data->[0] ),
        @{$data}[ 1, 2 ];
}
