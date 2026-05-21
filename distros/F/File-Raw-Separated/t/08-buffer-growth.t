use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

# Field of ~1 MiB to exercise the parser's geometric buffer growth.
my $big_field = 'x' x (1 << 20);
my $input = $big_field . ",y\n";

my $rows = file_csv_parse_buf($input);
is(scalar(@$rows), 1, 'one row');
is(scalar(@{$rows->[0]}), 2, 'two fields');
is(length($rows->[0][0]), 1 << 20, 'big field length preserved across reallocs');
is($rows->[0][1], 'y', 'second field intact');

# Hitting max_field_len cap croaks with FIELD_TOO_LONG
my $rc = eval { file_csv_parse_buf("x" x 100 . "\n", { max_field_len => 32 }) };
ok(!$rc, 'oversize field croaks');
like($@, qr/(field|max)/i, 'error mentions length / max');

done_testing;
