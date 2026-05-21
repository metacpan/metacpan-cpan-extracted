use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

is_deeply(
    file_csv_parse_buf(""),
    [],
    'empty buffer => empty AoA',
);

is_deeply(
    file_csv_parse_buf("\n"),
    [],
    'lone newline => no rows',
);

is_deeply(
    file_csv_parse_buf("\n\n\n"),
    [],
    'all blank lines => no rows',
);

# file_csv_parse_buf_each over empty input never invokes the callback
my $hits = 0;
file_csv_parse_buf_each("", sub { $hits++ });
is($hits, 0, 'each callback not invoked on empty input');

file_csv_parse_buf_each("\n\n", sub { $hits++ });
is($hits, 0, 'each callback not invoked on blank-only input');

done_testing;
