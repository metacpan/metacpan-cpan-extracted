#!/usr/bin/perl

use warnings;
use strict;

use vars qw(@classes);
use lib 'lib';

BEGIN {
  eval { require File::Find::Rule; };
  if ($@) {
    print "1..0 # Skipped - do not have File::Find::Rule installed\n";
    exit;
  }
}

BEGIN {
  use File::Find::Rule;
  @classes = File::Find::Rule->file()->name('*.pm')->in('blib/lib');
}

use Test::Pod tests => scalar @classes;

foreach my $class (@classes) {
  pod_file_ok($class);
}
