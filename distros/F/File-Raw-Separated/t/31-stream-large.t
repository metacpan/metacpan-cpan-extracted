use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);
use File::Temp qw(tempfile);

# Generate a 10 MB fixture: 50 000 rows × ~200 bytes/row
my ($fh, $path) = tempfile(SUFFIX => '.csv', UNLINK => 1);
my $row_template = join(',', map { "field${_}_xxxxxxxxxxxxxxxxxx" } 1 .. 8);
for my $i (1 .. 50_000) {
    print $fh "$i,$row_template\n";
}
close $fh;

my $size = -s $path;
diag("fixture size: $size bytes");
ok($size > 5_000_000, "fixture is at least 5 MB (got $size)");

# Stream and count without retaining rows (so RSS doesn't balloon)
my $count = 0;
file_csv_parse_stream($path, sub { $count++ });
is($count, 50_000, 'streamed all 50 000 rows');

# Spot-check first/last via index-targeted streaming
my @keep_first;
my @keep_last;
my $i = 0;
file_csv_parse_stream($path, sub {
    push @keep_first, [@{$_[0]}] if $i == 0;
    push @keep_last,  [@{$_[0]}] if $i == 49_999;
    $i++;
});
is($keep_first[0][0], '1',     'first row index 1');
is($keep_last[0][0],  '50000', 'last row index 50000');

done_testing;
