#!/usr/bin/perl -w
#
# Make sure we can "use" every module

use strict;
use vars qw(@classes);
use lib 'lib';

# Some warnings, so disable them
local $SIG{__WARN__} = sub { };

BEGIN {
  eval { require File::Find::Rule; };
  if ($@) {
    print "1..0 # Skipped - do not have File::Find::Rule installed\n";
    exit;
  }
}

BEGIN {
  use File::Find::Rule;
  @classes = map {
    my $x = $_;
    $x =~ s|^blib/lib/||;
    $x =~ s|/|::|g;
    $x =~ s|\.pm$||;
    $x;
    } grep {
    $_ !~ /templates/
    } File::Find::Rule->file()->name('*.pm')->in('blib/lib');
}

use Test::More tests => scalar @classes;

foreach my $class (@classes) {
  use_ok($class);
}
