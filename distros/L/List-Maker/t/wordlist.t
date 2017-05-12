use Test::More 'no_plan';

use List::Maker;


# LIST CONTEXT...

is_deeply [< a word list >],   ['a','word','list'] => '< a word list >';
is_deeply [< >],               []                  => '< >';

is_deeply [< "a word" list >], ['a word','list']   => '< "a word" list >';
is_deeply [< 'a word' list >], ['a word','list']   => '< \'a word\' list >';

is_deeply [< "o'word" list >], ['o\'word','list']   => '< "o\'word" list >';
is_deeply [< 'u"word' list >], ['u"word','list']   => '< \'u"word\' list >';


# SCALAR CONTEXT...

is < a word list >."",  'a, word, and list' => '< a word list >';

is < "a word" list >."", 'a word and list'   => '< "a word" list >';
is < 'a word' list >."", 'a word and list'   => '< \'a word\' list >';

is < "o'word" list >."", 'o\'word and list'  => '< "o\'word" list >';
is < 'u"word' list >."", 'u"word and list'   => '< \'u"word\' list >';

is < word >."",          'word'              => '< word >';

is < >."",               ''                  => '< >';
