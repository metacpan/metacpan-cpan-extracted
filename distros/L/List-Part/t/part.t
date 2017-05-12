use Test::More tests => 4;
BEGIN { use_ok('List::Part') };

chdir("t") if -d "t";

is_deeply(
    [ part { /a\.t/ } glob("*.t") ],
    [ ['part.t'], ['parta.t']  ],
    "Two-way boolean part()"
);

is_deeply(
    [ part { /a/ ? 0 : /b/ ? 1 : /c/ ? 2 : undef } qw(a b b c d) ],
    [ ['a'], [qw(b b)], ['c'] ],
    "Three-way part() with a discard"
);

is_deeply(
    [ part { /a/ ? 0 : /b/ ? 1 : /c/ ? 2 : undef } qw(aa bb cc ab bc) ],
    [ [qw(aa ab)], [qw(bb bc)], [qw(cc)] ],
    "Three-way part() with overlaps"
);