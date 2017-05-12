#!/usr/bin/perl -w
## Make sure we can "use" every module
use strict;
use vars qw(@classes);
use lib 'lib';


BEGIN {
  eval "use Test::Pod";
  if ($@) {
    print "1..0 # Skipped - do not have Test::Pod installed\n";
    exit;
  }
  eval "use File::Find::Rule";
  if ($@) {
    print "1..0 # Skipped - do not have File::Find::Rule installed\n";
    exit;
  }
}

BEGIN {
  @classes = File::Find::Rule->file()->name('*.pm')->in('blib/lib');
}

use Test::Pod tests => scalar @classes;

foreach my $class (@classes) {
  pod_file_ok($class);
}

