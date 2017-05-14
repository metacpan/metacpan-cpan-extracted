use strict;
use vars qw($DEBUG);
use IO::Handle;
use POSIX qw(tmpnam);

BEGIN { require "t/common.pl"; }

my $loaded;
BEGIN { $| = 1; print "1..21\n"; }
END {print "not ok 1\n" unless $loaded;}
use LaTeX::BibTeX;
use LaTeX::BibTeX::Bib;
$loaded = 1;
print "ok 1\n";

$DEBUG = 1;

setup_stderr;

# Basic test of the BibEntry classes (really, its base classes
# BibFormat and BibSort)

my $entries = <<'ENTRIES';
@article{homer97,
  author = {Simpson, Homer J. and Andr{\'e} de la Poobah},
  title = {Territorial Imperatives in Modern Suburbia},
  journal = {Journal of Suburban Studies},
  volume = 4,
  pages = "125--130",
  year = 1997
}

@book{george98,
  author = "George Simpson",
  title = "How to Found a Big Department Store",
  year = 1998
}
ENTRIES

# (Currently) we have to go through a LaTeX::BibTeX::File object to get
# Entry objects blessed into a structured entry class, so start
# by creating the file to parse.
my $fn = tmpnam . ".bib";
open (F, ">$fn") || die "couldn't create $fn: $!\n";
print F $entries;
close (F);

# Open it as a LaTeX::BibTeX::File object, set the structure class (which
# controls the structured entry class of all entries parsed from that
# file), and get the structure class (so we can set options on it).
my $file = new LaTeX::BibTeX::File ($fn);
$file->set_structure ('Bib');
my $structure = $file->structure;

# Read the two entries
my $entry1 = new LaTeX::BibTeX::BibEntry $file;
my $entry2 = new LaTeX::BibTeX::BibEntry $file;

$file->close;
unlink ($fn) || warn "couldn't delete temporary file $fn: $!\n";

# The default options of BibStructure are:
#   namestyle => 'full'
#   nameorder => 'first'
#   atitle    => 1 (true)
#   sortby    => 'name'
# Let's make sure these are respected.

my @blocks = $entry1->format;
test (@blocks == 4 &&                   # 4 blocks:
      defined $blocks[0] &&             # author
      defined $blocks[1] &&             # title
      defined $blocks[2] &&             # journal
      !defined $blocks[3]);             # note (there is no note!)
test (ref $blocks[0] eq 'ARRAY' &&      # 1 sentence, 1 clauses (2 authors)
      @{$blocks[0]} == 1);
test ($blocks[0][0] eq "Homer~J. Simpson and Andr{\\'e} de~la Poobah");
test (ref $blocks[1] eq 'ARRAY' &&      # 1 sentence, 1 clause for title
      @{$blocks[1]} == 1 &&
      $blocks[1][0] eq "Territorial imperatives in modern suburbia");
test (ref $blocks[2] eq 'ARRAY' &&      # 1 sentence for journal
      @{$blocks[2]} == 1);
test (ref $blocks[2][0] eq 'ARRAY' &&   # 3 clauses in that 1 sentence
      @{$blocks[2][0]} == 3);
test ($blocks[2][0][0] eq 'Journal of Suburban Studies' &&
      $blocks[2][0][1] eq '4:125--130' &&
      $blocks[2][0][2] eq '1997');

# Tweak options, one at a time, testing the result of each tweak
$structure->set_options (nameorder => 'last');
@blocks = $entry1->format;
test ($blocks[0][0] eq "Simpson, Homer~J. and de~la Poobah, Andr{\\'e}");

$structure->set_options (namestyle => 'abbrev',
                         nameorder => 'first');
@blocks = $entry1->format;
test ($blocks[0][0] eq "H.~J. Simpson and A. de~la Poobah");

$structure->set_options (nameorder => 'last');
@blocks = $entry1->format;
test ($blocks[0][0] eq "Simpson, H.~J. and de~la Poobah, A.");

$structure->set_options (namestyle => 'nopunct');
@blocks = $entry1->format;
test ($blocks[0][0] eq "Simpson, H~J and de~la Poobah, A");

$structure->set_options (namestyle => 'nospace');
@blocks = $entry1->format;
test ($blocks[0][0] eq "Simpson, HJ and de~la Poobah, A");

$structure->set_options (atitle_lower => 0);
@blocks = $entry1->format;
test ($blocks[1][0] eq "Territorial Imperatives in Modern Suburbia");

# Now some formatting tests on the second entry (a book).  Note that the
# two entries share a structure object, so the last-set options apply
# here!

@blocks = $entry2->format;
test (@blocks == 4 &&                   # again, 4 blocks:
      defined $blocks[0] &&             # name (authors or editors)
      defined $blocks[1] &&             # title (and volume no.)
      defined $blocks[2] &&             # no/series/publisher/date
      ! defined $blocks[3]);            # note (again none)
test ($blocks[0][0] eq "Simpson, G");
test ($blocks[1][0][0] eq "How to Found a Big Department Store" &&
      ! $blocks[1][0][1]);              # no volume number
test (! $blocks[2][0] &&                # no number/series
      ! $blocks[2][1][0] &&             # no publisher
      ! $blocks[2][1][1] &&             # no publisher address
      ! $blocks[2][1][2] &&             # no edition
      $blocks[2][1][3] eq '1998');      # but we do at least have a date!

# fiddle a bit more with name-generation options just to make sure
# everything's in working order
$structure->set_options (namestyle => 'full',
                         nameorder => 'first');
@blocks = $entry2->format;
test ($blocks[0][0] eq "George Simpson");

# Now test sorting: by default, the book (G. Simpson 1998) should come
# before the article (H. J. Simpson 1997) because the default sort
# order is (name, year).
test ($entry2->sort_key lt $entry1->sort_key);

# But if we change to sort by year, the article comes first
$structure->set_options (sortby => 'year');
test ($entry1->sort_key lt $entry2->sort_key);
