#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use Glib::IO;

{
  my $file = Glib::IO::File::new_for_path ($0);
  my $attrs = $file->query_settable_attributes ();

  $attrs->add ('perl::booze', 'boolean', [qw/copy-with-file copy-when-moved/]);
  my $attr = $attrs->lookup ('perl::booze');
  is ($attr->{name}, 'perl::booze');
  ok ($attr->{flags} == [qw/copy-with-file copy-when-moved/]);
  is ($attr->{type}, 'boolean');
}
