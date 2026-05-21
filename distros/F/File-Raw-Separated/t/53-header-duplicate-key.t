use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

# Duplicate key in header → croaks BEFORE producing any data row
my $rc = eval {
    file_csv_parse_buf("a,b,a\n1,2,3\n", { header => 1 });
    1;
};
ok(!$rc, 'duplicate header key croaks');
like($@, qr/duplicate header key/i, 'error mentions duplicate header key');
like($@, qr/'a'/, 'error names the offending key');

# A unique header followed by a duplicate among the body rows is fine —
# only the header is validated.
my $r = file_csv_parse_buf("a,b\n1,2\n3,4\n", { header => 1 });
is_deeply($r, [
    { a => 1, b => 2 },
    { a => 3, b => 4 },
], 'distinct header parses fine');

done_testing;
