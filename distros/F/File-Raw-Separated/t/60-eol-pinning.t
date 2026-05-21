use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

# eol => 'lf' accepts LF lines
is_deeply(
    file_csv_parse_buf("a,b\nc,d\n", { eol => 'lf' }),
    [['a','b'], ['c','d']],
    'eol=lf accepts LF',
);

# eol => 'crlf' accepts CRLF lines
is_deeply(
    file_csv_parse_buf("a,b\r\nc,d\r\n", { eol => 'crlf' }),
    [['a','b'], ['c','d']],
    'eol=crlf accepts CRLF',
);

# eol => 'cr' accepts bare-CR
is_deeply(
    file_csv_parse_buf("a,b\rc,d\r", { eol => 'cr' }),
    [['a','b'], ['c','d']],
    'eol=cr accepts bare CR',
);

# Pinned mismatch under strict croaks
my $rc = eval { file_csv_parse_buf("a,b\r\n", { eol => 'lf', strict => 1 }) };
ok(!$rc, 'strict + eol=lf rejects CRLF input');
like($@, qr/eol/i, 'error mentions eol');

# Bad eol value rejected at decode time
$rc = eval { file_csv_parse_buf("a,b\n", { eol => 'bogus' }) };
ok(!$rc, 'bad eol value croaks');
like($@, qr/eol/i, 'error mentions eol');

# eol => 'auto' (default) auto-detects
is_deeply(
    file_csv_parse_buf("a,b\r\nc,d\r\n", { eol => 'auto' }),
    [['a','b'], ['c','d']],
    'eol=auto detects CRLF',
);

done_testing;
