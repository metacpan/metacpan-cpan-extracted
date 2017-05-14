use strict;
use vars qw($DEBUG);
use IO::Handle;
BEGIN { require "t/common.pl"; }

my $loaded;
BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use LaTeX::BibTeX qw(:nameparts :joinmethods);
use LaTeX::BibTeX::Name;
use LaTeX::BibTeX::NameFormat;
$loaded = 1;
print "ok 1\n";

$DEBUG = 1;

setup_stderr;

# Get a name to work with (and just a quick check that the Name class
# is in working order)
my $name = new LaTeX::BibTeX::Name
        "Charles Louis Xavier Joseph de la Vall{\'e}e Poussin";
my @first = $name->part ('first');
my @von = $name->part ('von');
my @last = $name->part ('last');
test (slist_equal (\@first, [qw(Charles Louis Xavier Joseph)]) &&
      slist_equal (\@von, [qw(de la)]) &&
      slist_equal (\@last, ['Vall{\'e}e', 'Poussin']));


# Start with a basic "von last, jr, first" formatter
my $format = new LaTeX::BibTeX::NameFormat ('vljf', 1);
test ($format->apply ($name) eq "de~la Vall{\'e}e~Poussin, C.~L. X.~J." &&
      $format->apply ($name) eq $name->format ($format));

# Tweak options: force ties between tokens of the first name
$format->set_options (BTN_FIRST, 1, BTJ_FORCETIE, BTJ_NOTHING);
test ($format->apply ($name) eq "de~la Vall{\'e}e~Poussin, C.~L.~X.~J.");

# And no ties in the "von" part
$format->set_options (BTN_VON, 0, BTJ_SPACE, BTJ_SPACE);
test ($format->apply ($name) eq "de la Vall{\'e}e~Poussin, C.~L.~X.~J.");

# No punctuation in the first name
$format->set_text (BTN_FIRST, undef, undef, undef, '');
test ($format->apply ($name) eq "de la Vall{\'e}e~Poussin, C~L~X~J");

# And drop the first name inter-token separation entirely
$format->set_options (BTN_FIRST, 1, BTJ_NOTHING, BTJ_NOTHING);
test ($format->apply ($name) eq "de la Vall{\'e}e~Poussin, CLXJ");

# Now we get silly: keep the first name tokens jammed together, but
# don't abbreviate them any more
$format->set_options (BTN_FIRST, 0, BTJ_NOTHING, BTJ_NOTHING);
test ($format->apply ($name) eq
      "de la Vall{\'e}e~Poussin, CharlesLouisXavierJoseph");

# OK, but spaces back in to the first name
$format->set_options (BTN_FIRST, 0, BTJ_SPACE, BTJ_NOTHING);
test ($format->apply ($name) eq
      "de la Vall{\'e}e~Poussin, Charles Louis Xavier Joseph");
