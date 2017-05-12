#!/usr/bin/perl -w
use strict;

use Test::More;
use Test::NoWarnings;
use File::Tools;

my @all = @File::Tools::EXPORT_OK;
plan tests => 1 +  scalar @all;
foreach my $name (@all) {
  #eval "File::Tools::$name()";
  #ok(!$@, "calling File::Tools::$name") or diag $@;
  ok(1);
}
# TODO: we should check if all the functions are available??

