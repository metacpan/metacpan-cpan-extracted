use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

# Caller opts back into RFC-style quoting via quote => '"'
is_deeply(
    file_tsv_parse_buf(qq("a\tb"\tc\n), { quote => '"' }),
    [["a\tb", 'c']],     # literal tab inside quoted field is preserved
    'file_tsv_parse_buf with quote => "\"" parses tab-in-quoted-field',
);

# Doubled-quote escape (under quote => '"')
is_deeply(
    file_tsv_parse_buf(qq("a""b"\tc\n), { quote => '"' }),
    [['a"b', 'c']],
    'file_tsv_parse_buf doubled-quote escape under quote => "\""',
);

# Custom quote char (single quote)
is_deeply(
    file_tsv_parse_buf(qq('a\tb'\tc\n), { quote => "'" }),
    [["a\tb", 'c']],
    'file_tsv_parse_buf with single-quote as quote char',
);

done_testing;
