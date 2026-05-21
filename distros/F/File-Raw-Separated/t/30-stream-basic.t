use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);
use File::Temp qw(tempfile);

# Generate a moderate fixture
my ($fh, $path) = tempfile(SUFFIX => '.csv', UNLINK => 1);
for my $i (1 .. 100) {
    print $fh "row$i,col2_$i,col3_$i\n";
}
close $fh;

# Stream and collect rows
my @rows;
file_csv_parse_stream($path, sub {
    push @rows, [@{$_[0]}];   # explicit copy (AV is reused)
});

is(scalar(@rows), 100, 'streamed 100 rows');
is_deeply($rows[0],  ['row1',   'col2_1',   'col3_1'],   'first row content');
is_deeply($rows[49], ['row50',  'col2_50',  'col3_50'],  'middle row content');
is_deeply($rows[99], ['row100', 'col2_100', 'col3_100'], 'last row content');

# Quoted CSV streaming
my ($fh2, $path2) = tempfile(SUFFIX => '.csv', UNLINK => 1);
print $fh2 qq("a,b","c""d"\n);
print $fh2 qq("line1\nline2",x\n);
close $fh2;

my @qrows;
file_csv_parse_stream($path2, sub { push @qrows, [@{$_[0]}] });
is_deeply(\@qrows, [
    ['a,b', 'c"d'],
    ["line1\nline2", 'x'],
], 'quoted + multiline streaming preserved');

done_testing;
