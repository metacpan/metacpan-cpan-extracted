#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  chdir 't' if -d 't';
  use lib '../blib/';
  use lib '../lib/';
  plan tests => 2;
  }

use Image::Info qw(image_info dim);

# This image caused hangs in earlier versions (bug #26127/#26130) due to
# a cycle in the IFDs:

eval {
  local $SIG{ALRM} = sub { die "oops - did hang\n" };
  alarm 5;
  my $i = image_info("../img/cynic_hang.jpg");
  is (ref($i), 'HASH', 'image_info ran');
  ok (!exists $i->{error}, 'image_info ran ok');
  alarm 0;
  };

if ($@) {
  # propagate unexpected errors
  die unless $@ eq "oops - did hang\n";
  # timed out
  }

1;

