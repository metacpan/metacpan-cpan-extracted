use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);
use File::Temp qw(tempfile);

# Basic header mode (collect)
is_deeply(
    file_csv_parse_buf("name,age\nalice,30\nbob,25\n", { header => 1 }),
    [
        { name => 'alice', age => '30' },
        { name => 'bob',   age => '25' },
    ],
    'header mode: rows are hashrefs',
);

# Empty body (only header) → empty AoA
is_deeply(
    file_csv_parse_buf("name,age\n", { header => 1 }),
    [],
    'header mode: header-only input gives empty AoA',
);

# Truly empty input → empty AoA, no headers consumed
is_deeply(
    file_csv_parse_buf("", { header => 1 }),
    [],
    'header mode: empty input gives empty AoA',
);

# file_csv_parse_buf_each in header mode: callback gets a HASH ref
my @hashes;
file_csv_parse_buf_each(
    "id,name\n1,alice\n2,bob\n",
    sub { push @hashes, { %{$_[0]} } },   # explicit copy
    { header => 1 },
);
is_deeply(
    \@hashes,
    [
        { id => 1, name => 'alice' },
        { id => 2, name => 'bob' },
    ],
    'file_csv_parse_buf_each header mode: callback receives HASH ref per row',
);

# Confirm the callback's $_[0] is a HASH ref, not an ARRAY ref
my $kind;
file_csv_parse_buf_each(
    "k,v\nfoo,bar\n",
    sub { $kind = ref $_[0] },
    { header => 1 },
);
is($kind, 'HASH', 'callback row arg is HASH ref under header mode');

# file_csv_parse_stream in header mode
my ($fh, $path) = tempfile(SUFFIX => '.csv', UNLINK => 1);
print $fh "city,country\nlondon,uk\nparis,fr\n";
close $fh;

my @stream_rows;
file_csv_parse_stream(
    $path,
    sub { push @stream_rows, { %{$_[0]} } },
    { header => 1 },
);
is_deeply(
    \@stream_rows,
    [
        { city => 'london', country => 'uk' },
        { city => 'paris',  country => 'fr' },
    ],
    'file_csv_parse_stream header mode: same shape',
);

done_testing;
