#!/usr/bin/env perl

BEGIN { require './t/inc/setup.pl' };

use strict;
use warnings;
use utf8;

if (check_gi_version (1, 32, 0)) {
  plan tests => 6;
} else {
  plan skip_all => 'Need gobject-introspection 1.32.0';
}

my $v1 = Glib::Variant->new ("i", 27);
my $v2 = Glib::Variant->new ("s", "Hello");

check_variants (GI::array_gvariant_none_in ([$v1, $v2]));
check_variants (GI::array_gvariant_container_in ([$v1, $v2]));
check_variants (GI::array_gvariant_full_in ([$v1, $v2]));

sub check_variants {
  my ($v1, $v2) = @{$_[0]};
  is ($v1->get ("i"), 27);
  is ($v2->get ("s"), "Hello");
}
