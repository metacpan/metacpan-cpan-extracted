use warnings;
use strict;

use Test::More;

plan tests => 5;

use Lingua::EN::Inflexion;

is noun('expenses')->singular, 'expense' => 'expenses';

subtest '"who" forms' => sub {
    is noun('who')->plural, 'who' => 'who';
    is noun('whoever')->plural, 'whoever' => 'whoever';
    is noun('whosoever')->plural, 'whosoever' => 'whosoever';

    is noun('what')->plural, 'what' => 'what';
    is noun('whatever')->plural, 'whatever' => 'whatever';
    is noun('whatsoever')->plural, 'whatsoever' => 'whatsoever';

    is noun('whom')->plural, 'whom' => 'whom';
    is noun('whomever')->plural, 'whomever' => 'whomever';
    is noun('whomsoever')->plural, 'whomsoever' => 'whomsoever';

    is noun('whose')->plural, 'whose' => 'whose';
    is noun('whosever')->plural, 'whosever' => 'whosever';
};

subtest '"-ury" forms' => sub {
    is verb('buries')->plural, 'bury'   => 'buries';
    is verb('bury')->singular, 'buries' => 'bury';

    is noun('furies')->singular, 'fury'   => 'furies';
    is noun('fury')->plural,     'furies' => 'fury';

};

subtest '"-ops" forms' => sub {
    is noun('cyclops')->plural, 'cyclopses'   => 'cyclops';

};

is verb('backcast')->past, 'backcast' => 'backcast';

done_testing();

