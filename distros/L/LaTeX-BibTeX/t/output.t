use strict;
use IO::File;
BEGIN { require "t/common.pl"; }

my $loaded;
BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}
use LaTeX::BibTeX;
$loaded = 1;
print "ok 1\n";

setup_stderr;

# ----------------------------------------------------------------------
# entry output methods

my ($text, $entry, @warnings, @fields);
my ($new_text, $new_entry);

$text = <<'TEXT';
@article{homer97,
  author = "H{\"o}mer Simpson" # { \"und } # "Ned Flanders",
  title = {Territorial Imperatives in Modern Suburbia},
  journal = {Journal of Suburban Studies},
  year = 1997
}
TEXT

my $quote_warning = 'found \" (at brace-depth zero )?in string';

test ($entry = new LaTeX::BibTeX::Entry $text);
test ($entry->parse_ok);
@warnings = warnings;
test (@warnings == 1 &&
      $warnings[0] =~ /$quote_warning/);

$new_text = $entry->print_s;

test ($new_text =~ /^\@article\{homer97,$/m &&
      $new_text =~ /^\s*author\s*=\s*{H{\\"o}mer Simpson \\"und Ned Flanders},$/m &&
      $new_text =~ /^\s*title\s*=\s*[{"]Territorial[^}"]*Suburbia[}"],$/m &&
      $new_text =~ /^\s*journal\s*=\s*[{"]Journal[^\}]*Studies[}"],$/m &&
      $new_text =~ /^\s*year\s*=\s*[{"]1997[}"],?$/m);

$new_entry = new LaTeX::BibTeX::Entry $new_text;

test ($entry->parse_ok);
@warnings = warnings;
test (@warnings == 1 &&
      $warnings[0] =~ /$quote_warning/);
test ($entry->type eq $new_entry->type);
test ($entry->key eq $new_entry->key);
test (slist_equal (scalar $entry->fieldlist, scalar $new_entry->fieldlist));

@fields = $entry->fieldlist;
test (slist_equal ([$entry->get (@fields)], [$new_entry->get (@fields)]));

my @test = map { "t/test$_.bib" } 1..3;
my ($bib);

END { unlink @test }

open (BIB, ">$test[0]") || die "couldn't create $test[0]: $!\n";
$entry->print (\*BIB);
close (BIB);

$bib = new IO::File $test[1], O_CREAT|O_WRONLY
   or die "couldn't create $test[1]: $!\n";
$entry->print ($bib);
$bib->close;

$bib = new LaTeX::BibTeX::File $test[2], O_CREAT|O_WRONLY
   or die "couldn't create $test[2]: $!\n";
$entry->write ($bib);
$bib->close;

my (@contents, $i);
for $i (0 .. 2)
{
   open (BIB, $test[$i]) || die "couldn't open $test[$i]: $!\n";
   $contents[$i] = join ('', <BIB>);
   close (BIB);
}

test ($new_text eq $contents[0] &&
      $new_text eq $contents[1] &&
      $new_text eq $contents[2]);

