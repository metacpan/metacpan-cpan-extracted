use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);

# trim => 1 strips leading/trailing space + tab from UNQUOTED fields only.
# Quoted fields preserve all bytes.
is_deeply(
    file_csv_parse_buf("  a  ,\"  b  \",\tc\t\n", { trim => 1 }),
    [['a', '  b  ', 'c']],
    'trim: unquoted fields trimmed; quoted preserved verbatim',
);

# trim default (off) leaves whitespace intact
is_deeply(
    file_csv_parse_buf("  a  ,\"  b  \"\n"),
    [['  a  ', '  b  ']],
    'trim default off: whitespace preserved',
);

# empty_is_undef: unquoted empty becomes undef; quoted empty stays ""
my $r = file_csv_parse_buf("a,,\"\"\n", { empty_is_undef => 1 });
is($r->[0][0], 'a',   'first field unchanged');
is($r->[0][1], undef, 'unquoted empty -> undef');
is($r->[0][2], '',    'quoted empty stays ""');

# Without empty_is_undef, both empties are ""
my $r2 = file_csv_parse_buf("a,,\"\"\n");
is_deeply($r2, [['a', '', '']],
    'without empty_is_undef: both empties are ""');

# Combined: trim + empty_is_undef on a whitespace-only unquoted field
# trims first → empty → undef
my $r3 = file_csv_parse_buf("a,   ,b\n", { trim => 1, empty_is_undef => 1 });
is_deeply($r3, [['a', undef, 'b']],
    'trim + empty_is_undef: whitespace-only unquoted -> undef');

done_testing;
