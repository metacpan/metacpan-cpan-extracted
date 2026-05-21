use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

is_deeply(
    file_csv_parse_buf("a,b,\n"),
    [['a', 'b', '']],
    'trailing separator yields trailing empty field',
);

is_deeply(
    file_csv_parse_buf(",,\n"),
    [['', '', '']],
    'all-empty row',
);

is_deeply(
    file_csv_parse_buf("a,b,c"),    # no trailing newline
    [['a', 'b', 'c']],
    'no trailing newline still emits the row',
);

done_testing;
