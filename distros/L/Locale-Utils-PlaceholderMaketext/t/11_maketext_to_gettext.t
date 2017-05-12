#!perl -T

use strict;
use warnings;

use Test::More tests => 13;
use Test::NoWarnings;
use Test::Differences;
BEGIN {
    use_ok 'Locale::Utils::PlaceholderMaketext';
}

is_deeply
    [
        Locale::Utils::PlaceholderMaketext
            ->new( is_escape_percent_sign => 1 )
            ->maketext_to_gettext('foo % [_1] bar'),
    ],
    [ 'foo %% %1 bar' ],
    'escape percent sign';

my $obj = Locale::Utils::PlaceholderMaketext->new;

is_deeply
    [ $obj->maketext_to_gettext(undef) ],
    [ undef ],
    'undef';

my @data = (
    [
        q{},
        q{},
        'empty string',
    ],
    [
        'foo % [_1] bar',
        'foo % %1 bar',
        'placeholder',
    ],
    [
        '~~ % foo ~[_1~] bar ~[[_1]~] baz ~[%1~]',
        '~ % foo [_1] bar [%1] baz [%1]',
        'escaped placeholder',
    ],
    [
        'foo [_1] bar [quant,_2,singluar,plural,zero] baz [#,_3]',
        'foo %1 bar %quant(%2,singluar,plural,zero) baz %#(%3)',
        'function quant',
    ],
    [
        'foo ~[_1~] bar ~[quant,_2,singluar,plural,zero~] baz ~[#,_3~]',
        'foo [_1] bar [quant,_2,singluar,plural,zero] baz [#,_3]',
        'escaped function quant',
    ],
    [
        'bar [*,_2,singluar,plural] baz',
        'bar %*(%2,singluar,plural) baz',
        'function *',
    ],
    [
        'bar ~[*,_2,singluar,plural~] baz',
        'bar [*,_2,singluar,plural] baz',
        'escaped function *',
    ],
    [
        'baz [#,_3]',
        'baz %#(%3)',
        'function #',
    ],
    [
        'baz ~[#,_3~]',
        'baz [#,_3]',
        'escaped function #',
    ],
);

for my $data (@data) {
    eq_or_diff
        $obj->maketext_to_gettext( $data->[0] ),
        @{$data}[ 1, 2 ];
}
