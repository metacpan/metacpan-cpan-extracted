#! /usr/bin/perl -w

use IO::Prompt -argv;

use Data::Dumper 'Dumper';
warn Dumper [@ARGV];

# This time it's probably a no-op, since @ARGV will be non-empty...

use IO::Prompt -argv;

use Data::Dumper 'Dumper';
warn Dumper [@ARGV];
