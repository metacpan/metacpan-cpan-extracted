use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

# Same input parsed via file_csv_parse_buf(sep => "\t", quote => undef) and
# via file_tsv_parse_buf() must yield identical AoA. Locks the contract that
# the two paths share the same dispatcher.

my @cases = (
    "a\tb\tc\n",
    "a\tb\nc\td\n",
    "x\ty\n",
    "single\n",
    "",
    "no\ttrailing\tnl",
);

for my $i (0 .. $#cases) {
    my $case = $cases[$i];
    my $via_csv = file_csv_parse_buf($case, { sep => "\t", quote => undef });
    my $via_tsv = file_tsv_parse_buf($case);
    is_deeply($via_tsv, $via_csv, "case $i: file_tsv_parse_buf == file_csv_parse_buf(sep=>\"\\t\", quote=>undef)")
        or diag(explain({ csv => $via_csv, tsv => $via_tsv }));
}

done_testing;
