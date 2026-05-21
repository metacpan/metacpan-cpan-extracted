use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);
use File::Temp qw(tempfile);

my ($fh, $path) = tempfile(SUFFIX => '.csv', UNLINK => 1);
print $fh "a\nb\nc\nd\ne\nf\n";
close $fh;

# Callback dies on row 3 — exception must propagate, but rows 1-2
# must still have been seen.
my @seen;
my $rc = eval {
    file_csv_parse_stream($path, sub {
        push @seen, $_[0][0];
        die "stop on row 3\n" if @seen == 3;
    });
    1;
};

ok(!$rc, 'file_csv_parse_stream propagates die');
is($@, "stop on row 3\n", 'die message preserved verbatim');
is_deeply(\@seen, ['a', 'b', 'c'], 'three rows seen before abort');

# After abort, the parser is supposed to leave no leftover state. We
# can verify this with another fresh parse on the same file in the
# same process.
my @seen2;
file_csv_parse_stream($path, sub { push @seen2, $_[0][0] });
is_deeply(\@seen2, ['a','b','c','d','e','f'],
    'next stream call sees all rows (no leftover state from prior abort)');

# Bad path croaks cleanly
$rc = eval { file_csv_parse_stream('/no/such/file.csv', sub { }); 1 };
ok(!$rc, 'bad path croaks');
like($@, qr/cannot open/i, 'error mentions cannot open');

done_testing;
