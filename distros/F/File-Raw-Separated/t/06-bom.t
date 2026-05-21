use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

my $bom = "\xEF\xBB\xBF";

is_deeply(
    file_csv_parse_buf("${bom}a,b\n"),
    [['a', 'b']],
    'UTF-8 BOM stripped from first field by default',
);

# binary => 1 keeps BOM bytes literal
my $rows = file_csv_parse_buf("${bom}a,b\n", { binary => 1 });
is($rows->[0][0], "${bom}a", 'binary mode preserves BOM bytes literally')
    or diag(explain($rows));
is($rows->[0][1], 'b', 'second field unaffected');

# BOM in the middle of input is data, not stripped. In default
# (non-binary) mode the field gets sv_utf8_decode'd, so the 3-byte BOM
# decodes to the single Unicode codepoint U+FEFF.
is_deeply(
    file_csv_parse_buf("a,${bom}b\n"),
    [['a', "\x{feff}b"]],
    'BOM in middle of input is data (decoded to U+FEFF)',
);

# In binary mode it stays as raw bytes.
is_deeply(
    file_csv_parse_buf("a,${bom}b\n", { binary => 1 }),
    [['a', "${bom}b"]],
    'BOM in middle, binary mode keeps bytes',
);

done_testing;
