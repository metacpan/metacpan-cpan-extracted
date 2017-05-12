use strict;
use warnings;

# Tests here are few, but important.  They are a starting point.
# Among the things not tested are:
#   interactions of include and exclude filters in build_file_list
#   variations in the form of what_needs_compiling calls
#   error messages for bad calls, including misspelled args and empty lists

use Test::More tests => 6;

BEGIN { use_ok('Java::Build::Tasks'); }

my $javas = build_file_list(
    BASE_DIR         => 't/src',
    INCLUDE_PATTERNS => [ qr/\.java$/ ],
    EXCLUDE_PATTERNS => [ qr/Test/ ],
    STRIP_BASE_DIR   => 1,
);

my $hello = $javas->[0];
is($hello, "Hello.java", "build_file_list");

`touch t/compiled/Hello.class`;

my $dirty = what_needs_compiling(
    SOURCE_FILE_LIST => $javas,
    SOURCE_DIR       => 't/src',
    DEST_DIR         => 't/compiled',
);

cmp_ok(@$dirty, '==', 0, "Hello.java is uptodate");

rename 't/compiled/Hello.class', 't/compiled/HelloSaved.class';

$dirty = what_needs_compiling(
    SOURCE_FILE_LIST => $javas,
    SOURCE_DIR       => 't/src',
    DEST_DIR         => 't/compiled',
);
my $only_dirty = $dirty->[0];
is($only_dirty, "Hello.java", "Hello.java is dirty");

rename 't/compiled/HelloSaved.class', 't/compiled/Hello.class';

my $bad_source = build_file_list(
    BASE_DIR         => 't/badsrc',
);
is(scalar @$bad_source, 2, "directories excluded");

my $dollar_list = build_file_list(
    BASE_DIR         => 't/compiled',
    INCLUDE_PATTERNS => [ qr/\$/ ],
    QUOTE_DOLLARS    => 1,
);
like($dollar_list->[0], qr/Hello\$1.class/, "dollars quoted");

# These lines helped explore the dollar sign quoting problem.
# The fruit of that investigation appears in 04TasksOnDisk.t

# push @$dollar_list, 't/compiled/Hello.class';
#my @new_list = map { "'$_'" } @$dollar_list;
#
#print `ls '$dollar_list->[0]' 't/compiled/Hello.class'`;
#print `ls @new_list`;

