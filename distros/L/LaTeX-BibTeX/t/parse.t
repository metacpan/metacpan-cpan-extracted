use strict;
use vars ('$DEBUG');
use IO::Handle;
BEGIN { require "t/common.pl"; }

my $loaded;
BEGIN { $| = 1; print "1..26\n"; }
END {print "not ok 1\n" unless $loaded;}
use LaTeX::BibTeX;
$loaded = 1;
print "ok 1\n";

$DEBUG = 0;

setup_stderr;

# ----------------------------------------------------------------------
# entry creation and parsing from a LaTeX::BibTeX::File object

my ($bibfile, $entry);
my $multiple_file = 'btparse/t/data/simple.bib';

test ($bibfile = new LaTeX::BibTeX::File $multiple_file);
test ($entry = new LaTeX::BibTeX::Entry $bibfile);
test (slist_equal
      ([warnings], 
       [$multiple_file . ', line 5, warning: undefined macro "junk"']));
test_entry ($entry, 'book', 'abook',
            [qw(title editor publisher year)],
            ['A Book', 'John Q. Random', 'Foo Bar \& Sons', '1922']);

test ($entry->read ($bibfile));
test_entry ($entry, 'string', undef,
            ['macro', 'foo'],
            ['macro  text ', 'blah blah   ding dong ']);


test ($entry->read ($bibfile));
test ($entry->parse_ok &&
      $entry->type eq 'comment' &&
      $entry->metatype == BTE_COMMENT &&
      $entry->value eq 'this is a comment entry, anything at all can go in it (as long as parentheses are balanced), even {braces}');

test ($entry->read ($bibfile));
test ($entry->parse_ok && 
      $entry->type eq 'preamble' &&
      $entry->metatype == BTE_PREAMBLE &&
      $entry->value eq 'This is a preamble---the concatenation of several strings');

test (! $entry->read ($bibfile));
