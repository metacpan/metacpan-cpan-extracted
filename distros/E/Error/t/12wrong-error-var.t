#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use Error qw(:try);

try {
  eval {
   throw Error::Simple "This is caught by eval, not by try.";
  };

  # TEST
  ok (($@ && $@ =~ /This is caught by eval, not by try/),
      "Checking that eval { ... } is sane"
     );

  print "# Error::THROWN = $Error::THROWN\n";

  die "This is a simple 'die' exception.";

  # not reached
}
otherwise {
  my $E = shift;
  my $t = $Error::THROWN ? "$Error::THROWN" : '';
  print "# Error::THROWN = $t\n";
  $E ||= '';
  print "# E = $E\n";

  # TEST
  ok ("$E" =~ /This is a simple 'die' exception/,
      "Checking that the argument to otherwise is the thrown exception"
  );
};
