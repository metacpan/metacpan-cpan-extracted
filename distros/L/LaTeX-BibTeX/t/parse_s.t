use strict;
use IO::Handle;
BEGIN { require "t/common.pl"; }

my $loaded;
BEGIN { $| = 1; print "1..36\n"; }
END {print "not ok 1\n" unless $loaded;}
use LaTeX::BibTeX;
$loaded = 1;
print "ok 1\n";

setup_stderr;

# ----------------------------------------------------------------------
# entry creation and parsing from a string

my ($text, $entry, @warnings, $result);

$text = <<'TEXT';
@foo { mykey,
  f1 = {hello } # { there},
  f2 = "fancy " # "that!" # foo # 1991,
  f3 = foo
    }
TEXT

test ($entry = new LaTeX::BibTeX::Entry);
test ($entry->parse_s ($text));
@warnings = warnings;
test (@warnings == 2 && 
      $warnings[0] eq 'line 3, warning: undefined macro "foo"' &&
      $warnings[1] eq 'line 4, warning: undefined macro "foo"');

# First, low-level tests: make sure the data structure itself looks right
test ($entry->{'status'});
test ($entry->{'type'} eq 'foo');
test ($entry->{'key'} eq 'mykey');
test (scalar @{$entry->{fields}} == 3);
test ($entry->{fields}[0] eq 'f1' &&
      $entry->{fields}[1] eq 'f2' &&
      $entry->{fields}[2] eq 'f3');
test (scalar keys %{$entry->{'values'}} == 3);
test ($entry->{'values'}{f1} eq 'hello there');

# Now the same tests again, but using the object's methods
test_entry ($entry, 'foo', 'mykey',
            ['f1', 'f2', 'f3'],
            ['hello there', 'fancy that!1991', '']);

# Repeat with "bundled" form (new and parse_s in one go)
test ($entry = new LaTeX::BibTeX::Entry $text);
@warnings = warnings;
test (@warnings == 2 && 
      $warnings[0] eq 'line 3, warning: undefined macro "foo"' &&
      $warnings[1] eq 'line 4, warning: undefined macro "foo"');

# Repeat tests of entry contents
test_entry ($entry, 'foo', 'mykey',
            ['f1', 'f2', 'f3'],
            ['hello there', 'fancy that!1991', '']);

# Make sure parsing an empty string, or string with no entry in it,
# just returns false... nope, doesn't work right now.  Need to
# look into how btparse responds to bt_parse_s() on an empty string
# before I know how LaTeX::BibTeX should do it!

# $entry = new LaTeX::BibTeX::Entry;
# $result = $entry->parse_s ('');
# test (! warnings && ! $result);

# $result = $entry->parse_s ('top-level junk that is not caught');
# test (! warnings && ! $result);


# Test the "proper noun at both ends" bug (the bt_get_text() call in
# BibTeX.xs stripped off the leading and trailing braces; has since
# been changed to bt_next_value(), under the assumption that compound
# values will have been collapsed to a single simple value)

# (thanks to Reiner Schotte for reporting this bug)

$text = <<'TEXT';
@foo{key, title = "{System}- und {Signaltheorie}"}
TEXT

$entry = new LaTeX::BibTeX::Entry $text;
test (! warnings && $entry->parse_ok);
test_entry ($entry, 'foo', 'key', 
            ['title'], ['{System}- und {Signaltheorie}']);
