use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

# TSV header mode (collect)
is_deeply(
    file_tsv_parse_buf("name\tage\nalice\t30\n", { header => 1 }),
    [{ name => 'alice', age => '30' }],
    'file_tsv_parse_buf header mode',
);

# file_tsv_parse_buf_each header mode
my @rows;
file_tsv_parse_buf_each(
    "k\tv\na\t1\nb\t2\n",
    sub { push @rows, { %{$_[0]} } },
    { header => 1 },
);
is_deeply(
    \@rows,
    [
        { k => 'a', v => '1' },
        { k => 'b', v => '2' },
    ],
    'file_tsv_parse_buf_each header mode',
);

done_testing;
