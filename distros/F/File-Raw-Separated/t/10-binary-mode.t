use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

# Binary mode: bytes pass through unchanged. The buffer contains
# arbitrary high bytes (0x80-0xFF) that aren't valid UTF-8 on their own;
# binary mode must not corrupt them.

my $buf = "\x80\x81,\xC0\xC1,\xFF\xFE\n";

my $rows = file_csv_parse_buf($buf, { binary => 1 });
is(scalar(@$rows), 1, 'one row');
is(scalar(@{$rows->[0]}), 3, 'three fields');
is($rows->[0][0], "\x80\x81", 'field 0 preserved byte-for-byte');
is($rows->[0][1], "\xC0\xC1", 'field 1 preserved byte-for-byte');
is($rows->[0][2], "\xFF\xFE", 'field 2 preserved byte-for-byte');

# In non-binary mode, sv_utf8_decode is a no-op for invalid UTF-8
# (returns 0), so bytes are still preserved — just without the UTF-8
# flag set. Verify length is byte length.
my $rows2 = file_csv_parse_buf($buf);
is(length($rows2->[0][0]), 2, 'non-binary mode keeps bytes when UTF-8 decode fails');
ok(!utf8::is_utf8($rows2->[0][0]), 'invalid UTF-8 leaves SV as bytes');

done_testing;
