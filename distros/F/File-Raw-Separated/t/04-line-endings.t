use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

is_deeply(
    file_csv_parse_buf("a,b\nc,d\n"),
    [['a','b'], ['c','d']],
    'LF',
);

is_deeply(
    file_csv_parse_buf("a,b\r\nc,d\r\n"),
    [['a','b'], ['c','d']],
    'CRLF',
);

is_deeply(
    file_csv_parse_buf("a,b\rc,d\r"),
    [['a','b'], ['c','d']],
    'bare CR',
);

# Pinning eol mode
is_deeply(
    file_csv_parse_buf("a,b\nc,d\n", { eol => 'lf' }),
    [['a','b'], ['c','d']],
    'eol=lf accepts LF',
);

# Strict + pinned mismatch
my $rc = eval { file_csv_parse_buf("a,b\r\n", { eol => 'lf', strict => 1 }) };
ok(!$rc, 'strict + eol=lf rejects CRLF input');
like($@, qr/eol/i, 'error message mentions eol');

done_testing;
