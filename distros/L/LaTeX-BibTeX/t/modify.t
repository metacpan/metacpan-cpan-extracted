use strict;
use IO::Handle;
BEGIN { require "t/common.pl"; }

my $loaded;
BEGIN { $| = 1; print "1..22\n"; }
END {print "not ok 1\n" unless $loaded;}
use LaTeX::BibTeX;
$loaded = 1;
print "ok 1\n";

setup_stderr;

# ----------------------------------------------------------------------
# entry modification methods

my ($text, $entry, @warnings, @fieldlist);

$text = <<'TEXT';
@article{homer97,
  author = {Homer Simpson and Ned Flanders},
  title = {Territorial Imperatives in Modern Suburbia},
  journal = {Journal of Suburban Studies},
  year = 1997
}
TEXT

test ($entry = new LaTeX::BibTeX::Entry);
test ($entry->parse_s ($text));

test ($entry->type eq 'article');
$entry->set_type ('book');
test ($entry->type eq 'book');

test ($entry->key eq 'homer97');
$entry->set_key ($entry->key . 'a');
test ($entry->key eq 'homer97a');

my @names = $entry->names ('author');
$names[0] = $names[0]->{'last'}[0] . ', ' . $names[0]->{'first'}[0];
$names[1] = $names[1]->{'last'}[0] . ', ' . $names[1]->{'first'}[0];
$entry->set ('author', join (' and ', @names));

my $author = $entry->get ('author');
test ($author eq 'Simpson, Homer and Flanders, Ned');
test (! warnings);

$entry->set (author => 'Foo Bar {and} Co.', 
             title  => 'This is a new title');
test ($entry->get ('author') eq 'Foo Bar {and} Co.');
test ($entry->get ('title') eq 'This is a new title');
test (slist_equal ([$entry->get ('author', 'title')],
                   ['Foo Bar {and} Co.', 'This is a new title']));
test (! warnings);

test (slist_equal ([$entry->fieldlist], [qw(author title journal year)]));
test ($entry->exists ('journal'));

$entry->delete ('journal');
@fieldlist = $entry->fieldlist;
test (! $entry->exists ('journal') &&
      slist_equal (\@fieldlist, [qw(author title year)]));
test (! warnings);

$entry->set_fieldlist ([qw(author title journal year)]);
@warnings = warnings;
test (@warnings == 1 && 
      $warnings[0] =~ /implicitly adding undefined field \"journal\"/i);

@fieldlist = $entry->fieldlist;
test ($entry->exists ('journal') &&
      ! defined $entry->get ('journal') &&
      slist_equal (\@fieldlist, [qw(author title journal year)]));
test (! warnings);

$entry->delete ('journal', 'author', 'year');
@fieldlist = $entry->fieldlist;
test (! $entry->exists ('journal') &&
      ! $entry->exists ('author') &&
      ! $entry->exists ('year') &&
      @fieldlist == 1 && $fieldlist[0] eq 'title');
test (! warnings);
