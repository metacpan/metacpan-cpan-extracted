use strict;
use vars ('$DEBUG');
use IO::Handle;
BEGIN { require "t/common.pl"; }

my $loaded;
BEGIN { $| = 1; print "1..36\n"; }
END {print "not ok 1\n" unless $loaded;}
use LaTeX::BibTeX qw(:macrosubs);
$loaded = 1;
print "ok 1\n";

$DEBUG = 1;

setup_stderr;

# ----------------------------------------------------------------------
# test macro parsing and expansion

my ($macrodef, $regular, $entry, @warnings);

$macrodef = <<'TEXT';
@string ( foo = "  The Foo
  Journal",  
        sons  = " \& Sons",
    bar 
=    {Bar   } # sons,

)
TEXT

$regular = <<'TEXT';
@article { my_article, 
            author = { Us and Them },
            journal = foo,
            publisher = "Fu" # bar 
          }
TEXT

# Direct access to macro table, part 1: make sure the macros we're going to
# defined aren't defined

print "testing that none of our macros are defined yet\n" if $DEBUG;
test (macro_length ('foo') == 0 &&
      macro_length ('sons') == 0 &&
      macro_length ('bar') == 0);

test (! defined macro_text ('foo') &&
      ! defined macro_text ('sons') &&
      ! defined macro_text ('bar'));
@warnings = warnings;
test (@warnings == 3 &&
      $warnings[0] =~ /undefined macro "foo"/ &&
      $warnings[1] =~ /undefined macro "sons"/ &&
      $warnings[2] =~ /undefined macro "bar"/);


# Now parse the macro-definition entry; this should put the three 
# macros we're interested in into the macro table so we can
# successfully parse the regular entry
print "parsing macro-definition entry to define 3 macros\n" if $DEBUG;
$entry = new LaTeX::BibTeX::Entry;
$entry->parse_s ($macrodef);
test (! warnings);
test_entry ($entry, 'string', undef, 
            [qw(foo sons bar)],
            ['  The Foo   Journal', ' \& Sons', 'Bar    \& Sons']);

# Direct access to macro table, part 2: make sure the macros we've just
# defined now have the correct values
print "checking macro table to ensure that the macros were properly defined\n"
   if $DEBUG;
test (macro_length ('foo') == 19 &&
      macro_length ('sons') == 8 &&
      macro_length ('bar') == 14);

test (macro_text ('foo') eq '  The Foo   Journal' &&
      macro_text ('sons') eq ' \& Sons' &&
      macro_text ('bar') eq 'Bar    \& Sons');
test (! warnings);


# Parse the regular entry -- there should be no warnings, because
# we've just defined the 'foo' and 'bar' macros on which it depends

# calling a parse or read method on an existing object isn't documented
# as an "ok thing to do", but it is (at least as the XS code currently
# is!) -- hence I can leave the "new" uncommented
# $entry = new LaTeX::BibTeX::Entry;
print "parsing the regular entry which uses those 2 of those macros\n"
   if $DEBUG;
$entry->parse_s ($regular);
test (! warnings);
test_entry ($entry, 'article', 'my_article',
            [qw(author journal publisher)],
            ['Us and Them', 'The Foo Journal', 'FuBar \& Sons']);


# Delete the 'bar' macro and change 'foo' -- this should result in 
# one warning about the macro value being overridden
delete_macro ('bar');
test (macro_length ('bar') == 0 &&
      ! defined macro_text ('bar') &&
      (@warnings = warnings) == 1 &&
      $warnings[0] =~ /undefined macro "bar"/);

add_macro_text ('foo', 'The Journal of Fooology');
test ((@warnings = warnings) == 1 && 
      $warnings[0] =~ /overriding existing definition of macro "foo"/);


# Now re-parse our regular entry; we should get a warning about the deleted
# "bar" macro, and the "journal" field (which relies on "foo") should have 
# a different value

$entry->parse_s ($regular);
test ((@warnings = warnings) == 1 &&
      $warnings[0] =~ /undefined macro "bar"/);
test_entry ($entry, 'article', 'my_article',
            [qw(author journal publisher)],
            ['Us and Them', 'The Journal of Fooology', 'Fu']);
