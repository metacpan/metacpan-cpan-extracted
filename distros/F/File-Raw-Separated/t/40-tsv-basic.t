use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

# Plain TSV
is_deeply(
    file_tsv_parse_buf("a\tb\tc\nd\te\tf\n"),
    [['a','b','c'], ['d','e','f']],
    'plain TSV: two rows × three fields',
);

# Single field
is_deeply(
    file_tsv_parse_buf("only-field\n"),
    [['only-field']],
    'single tab-free field',
);

# TSV defaults: quote disabled — quote chars are literal data
is_deeply(
    file_tsv_parse_buf(qq("a"\tb\n)),
    [['"a"', 'b']],
    'TSV default: quote chars are literal',
);

# file_tsv_parse_buf_each yields the same rows
my @rows;
file_tsv_parse_buf_each(
    "p\tq\nr\ts\n",
    sub { push @rows, [@{$_[0]}] },
);
is_deeply(\@rows, [['p','q'], ['r','s']], 'file_tsv_parse_buf_each fires per row');

done_testing;
