use Test::More tests => 4;
BEGIN { use_ok('List::Part', 'parta') };

is_deeply(
    [ parta [ qr/a/, qr/b/, qr/c/ ] => qw(a b b c d) ],
    [ ['a'], [qw(b b)], ['c'] ],
    "Three-way part() with a discard"
);

is_deeply(
    [ parta [ qr/a/, qr/b/, qr/c/ ] => qw(aa bb cc ab bc) ],
    [ [qw(aa ab)], [qw(bb bc)], [qw(cc)] ],
    "Three-way part() with overlaps"
);

is_deeply(
    [ parta [ qr/a/, qr/b/, qr/c/, qr// ] => qw(a b b c d) ],
    [ ['a'], [qw(b b)], ['c'], ['d'] ],
    "Three-way part() with a discard pile"
);