use strict;
use IO::Handle;
BEGIN { require "t/common.pl"; }

my $loaded;
BEGIN { $| = 1; print "1..56\n"; }
END {print "not ok 1\n" unless $loaded;}
use LaTeX::BibTeX;
$loaded = 1;
print "ok 1\n";

setup_stderr;

# ----------------------------------------------------------------------
# entry creation and parsing from files

my ($fh, $entry);

my $regular_file = 'btparse/t/data/regular.bib';

# first, from a regular ol' Perl filehandle, with 'new' and 'parse"
# bundled into one call
open (BIB, $regular_file) || die "couldn't open $regular_file: $!\n";
test ($entry = new LaTeX::BibTeX::Entry $regular_file, \*BIB);
test (slist_equal
      ([warnings], 
       [$regular_file . ', line 5, warning: undefined macro "junk"']));
test_entry ($entry, 'book', 'abook',
            [qw(title editor publisher year)],
            ['A Book', 'John Q. Random', 'Foo Bar \& Sons', '1922']);
test (! new LaTeX::BibTeX::Entry $regular_file, \*BIB);


# An interesting note: if I forget the 'seek' here, a bug is exposed in
# btparse -- it crashes with an internal error if it hits eof twice in a
# row.  Should add a test for that bug to the official suite, once
# it's fixed of course.  ;-)

seek (BIB, 0, 0);

# now the same, separating the 'new' and 'parse' calls -- also a test
# to see if we can pass undef for filename and get no filename in the 
# error message (and suffer no other consequences!)
test ($entry->parse (undef, \*BIB));
test (slist_equal
      ([warnings], 
       ['line 5, warning: undefined macro "junk"']));
test_entry ($entry, 'book', 'abook',
            [qw(title editor publisher year)],
            ['A Book', 'John Q. Random', 'Foo Bar \& Sons', '1922']);
test (! $entry->parse (undef, \*BIB));

close (BIB);

# this is so I can stop checking the damned 'undefined macro' warning
# -- guess I really do need a "set macro value" interface at some level...
# (problem is that there's just one macro table for the whole process)

test ($entry->parse_s ('@string(junk={, III})'));
test_entry ($entry, 'string', undef, ['junk'], [', III']);

# Now open that same file using IO::File, and pass in the resulting object
# instead of a glob ref; everything else here is just the same

$fh = new IO::File $regular_file
   or die "couldn't open $regular_file: $!\n";
test ($entry = new LaTeX::BibTeX::Entry $regular_file, $fh);
test (! warnings);
test_entry ($entry, 'book', 'abook',
            [qw(title editor publisher year)],
            ['A Book', 'John Q. Random, III', 'Foo Bar \& Sons', '1922']);
test (! new LaTeX::BibTeX::Entry $regular_file, $fh);
$fh->seek (0, 0);

# and again, with unbundled 'parse' call
test ($entry->parse ($regular_file, $fh));
test (! warnings);
test_entry ($entry, 'book', 'abook',
            [qw(title editor publisher year)],
            ['A Book', 'John Q. Random, III', 'Foo Bar \& Sons', '1922']);
test (! new LaTeX::BibTeX::Entry $regular_file, $fh);

$fh->close;
