# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}

use HTML::Clean;
$loaded = 1;
;
# Test constructors

my $h = new HTML::Clean();
if (!defined($h)) {
   print "not ok 1\n";
} else {
   print "ok 1\n";
}

my $data = "testing, 1 2 3\n";

$h = new HTML::Clean(\$data);
if (!defined($h)) {
   print "not ok 2\n";
} else {
   print "ok 2\n";
}

# test level operator

$h->level(2);
if ($h->level() != 2) {
   print "not ok 3\n";
   print "Level is " . $h->level() . "\n";
} else {
   print "ok 3\n";
}

$h->level(9);

# Test stripping..
# first val is text to manipulate
# second val is good result

my @data = (
"<strong>some bold text</strong><em>some italic text</em>",
"<b>some bold text</b><i>some italic text</i>",

"&Agrave;&copy;&ntilde;",
"À&copy;ñ",

"Some text <b>with</b> empty <B></B> tags <font face=arial></font>",
"Some text <b>with</b> empty  tags ",

);

my $test = 3;
while (1) {
  $test++;
  my $orig = shift(@data) || last;
  my $good = shift(@data);
  $h->initialize(\$orig);
  $h->compat();
  $h->strip();

  if ($orig eq $good) {
    print "ok $test\n";
  } else {
   print "not ok $test\n";
   print "got:\n$orig\n\nexpected:\n$good\n\n";
  }
}
exit;

