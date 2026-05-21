use strict;
use warnings;
use utf8;
use Test::More;
use Encode qw(encode_utf8);
use File::Raw::Separated qw(import);

# Build the buffer from real Unicode strings, encoded explicitly to bytes.
my $buf = encode_utf8(qq(café,東京,résumé\n));

my $rows = file_csv_parse_buf($buf);
is(scalar(@$rows), 1, 'one row');
my @fields = @{ $rows->[0] };
is(scalar(@fields), 3, 'three fields');

# In default (non-binary) mode the parser invoked sv_utf8_decode, so
# fields should compare as Unicode strings.
ok(utf8::is_utf8($fields[0]), 'field 0 has UTF-8 flag set after decode')
    or diag(explain(\@fields));
is($fields[0], 'café',    'field 0 round-trips as Unicode');
is($fields[1], '東京',     'field 1 round-trips as Unicode');
is($fields[2], 'résumé', 'field 2 round-trips as Unicode');

done_testing;
