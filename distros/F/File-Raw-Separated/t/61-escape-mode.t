use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

# Backslash-escape mode: inside quoted field, backslash consumes the
# next byte literally. Doubled-quote escape continues to work alongside.

# Escaped quote
is_deeply(
    file_csv_parse_buf(qq("a\\"b",c\n), { escape => '\\' }),
    [['a"b', 'c']],
    'escape => \\ allows \\" inside quoted field',
);

# Escaped backslash itself
is_deeply(
    file_csv_parse_buf(qq("a\\\\b",c\n), { escape => '\\' }),
    [['a\\b', 'c']],
    'escape => \\ doubles backslash literally',
);

# Doubled-quote still works in escape mode
is_deeply(
    file_csv_parse_buf(qq("a""b",c\n), { escape => '\\' }),
    [['a"b', 'c']],
    'doubled-quote works alongside escape mode',
);

# Without escape opt, backslash is literal
is_deeply(
    file_csv_parse_buf(qq("a\\b",c\n)),
    [['a\\b', 'c']],
    'no escape opt: backslash inside quoted field is literal',
);

done_testing;
