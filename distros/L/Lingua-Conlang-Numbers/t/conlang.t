#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Test::More tests => 27;

# handle utf8 output
my $builder = Test::More->builder;
binmode $builder->output,         ':utf8';
binmode $builder->failure_output, ':utf8';
binmode $builder->todo_output,    ':utf8';

use ok 'Lingua::Conlang::Numbers', qw( :all );

are_num2conlang(
    [ eo          => -9,    'negativa naŭ' ],
    [ eo          =>  0,    'nul'          ],
    [ eo          =>  0.9,  'nul komo naŭ' ],
    [ eo          =>  9,    'naŭ'          ],
    [ eo          => 'NaN', 'ne nombro'    ],
    [ EO          =>  9,    'naŭ'          ],
    [ esperanto   =>  9,    'naŭ'          ],
    [ jbo         =>  9,    'so'           ],
    [ lojban      =>  9,    'so'           ],
    [ tokipona    =>  9,    'mute'         ],
    [ TokiPona    =>  9,    'mute'         ],
    [ toki_pona   =>  9,    'mute'         ],
    [ 'Toki Pona' =>  9,    'mute'         ],
);

are_num2conlang_ordinal(
    [ eo       => -9, 'negativ-naŭa' ],
    [ eo       =>  0, 'nula'         ],
    [ eo       =>  9, 'naŭa'         ],
    [ jbo      =>  9, 'somoi'        ],
    [ tokipona =>  9, 'nanpa mute'   ],
);

# negative tests
ok !num2conlang(),             'no args fails';
ok !num2conlang('eo'),         'one arg fails';
ok !num2conlang(undef, undef), 'double undef fails';
ok !num2conlang(undef, 9),     'undef lang fails';
ok !num2conlang(eo => undef),  'undef num fails';
ok !num2conlang(xx => 9),      'unknown lang fails';

# num2conlang_languages
is num2conlang_languages(), 4, '4 languages available';
ok scalar(
    grep { $_ eq 'eo' } num2conlang_languages()
), 'languages include eo';

sub are_num2conlang {
    my (@tests) = @_;

    for my $test (@tests) {
        my ($lang, $num, $word) = @{$test};
        is num2conlang($lang => $num), $word, "$lang: $num -> $word";
    }
}

sub are_num2conlang_ordinal {
    my (@tests) = @_;

    for my $test (@tests) {
        my ($lang, $num, $word) = @{$test};
        is num2conlang_ordinal($lang => $num), $word, "$lang: $num -> $word";
    }
}
