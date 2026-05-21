use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

# Plain unquoted CSV
is_deeply(
    file_csv_parse_buf("a,b,c\n"),
    [['a', 'b', 'c']],
    'three plain fields',
);

# Multiple rows
is_deeply(
    file_csv_parse_buf("a,b\nc,d\n"),
    [['a', 'b'], ['c', 'd']],
    'two rows',
);

# Quoted with doubled-quote escape
is_deeply(
    file_csv_parse_buf(q("a""b",c) . "\n"),
    [['a"b', 'c']],
    'doubled-quote escape',
);

# Quoted field containing the separator
is_deeply(
    file_csv_parse_buf(q("a,b",c) . "\n"),
    [['a,b', 'c']],
    'separator inside quoted field',
);

# Mixed quoted and unquoted
is_deeply(
    file_csv_parse_buf(qq(plain,"quoted","with""escape"\n)),
    [['plain', 'quoted', 'with"escape']],
    'mixed quoting in one row',
);

done_testing;
