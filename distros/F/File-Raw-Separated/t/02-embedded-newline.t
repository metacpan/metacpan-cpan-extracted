use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

is_deeply(
    file_csv_parse_buf(qq("line1\nline2",x\n)),
    [["line1\nline2", 'x']],
    'embedded LF in quoted field',
);

is_deeply(
    file_csv_parse_buf(qq("a\r\nb",c\n)),
    [["a\r\nb", 'c']],
    'embedded CRLF in quoted field is preserved literally',
);

# Multiple embedded newlines
is_deeply(
    file_csv_parse_buf(qq("one\ntwo\nthree",done\n)),
    [["one\ntwo\nthree", 'done']],
    'multiple embedded newlines in one quoted field',
);

done_testing;
