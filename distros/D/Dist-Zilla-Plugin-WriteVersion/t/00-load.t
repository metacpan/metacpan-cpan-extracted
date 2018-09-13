#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::Most tests => 1;

use File::Find;

#Find files in the usual places
my $searchDir = "$FindBin::Bin/../lib/";
File::Find::find( \&testLib, $searchDir );

sub testLib {
  my ($filename) = @_;
  $filename = $File::Find::name unless $filename;

  return unless $filename =~ m/\.p[ml]$/;

  require_ok($filename);
}
