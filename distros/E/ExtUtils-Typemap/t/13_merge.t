#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;
use ExtUtils::Typemap;
use File::Spec;
use File::Temp;

sub _isa_any_ok {
  my $obj = shift;
  my @classes = @_;
  my $ok = 0;
  foreach (@classes) {
    $ok = 1 if $obj->isa($_);
  }
  ok($ok, "Object isa_any '".join("', '", @classes)."'");
  if (not $ok) {
    diag("Object isa '" . ref($obj) . "', not any of '".join("', '", @classes)."'");
  }
  return $ok;
}

my $datadir = -d 't' ? File::Spec->catdir(qw/t data/) : 'data';

sub slurp {
  my $file = shift;
  open my $fh, '<', $file
    or die "Cannot open file '$file' for reading: $!";
  local $/ = undef;
  return <$fh>;
}

my $first_typemap_file = File::Spec->catfile($datadir, 'simple.typemap');
my $second_typemap_file = File::Spec->catfile($datadir, 'other.typemap');
my $combined_typemap_file = File::Spec->catfile($datadir, 'combined.typemap');


SCOPE: {
  my $first = ExtUtils::Typemap->new(file => $first_typemap_file);
  _isa_any_ok($first, 'ExtUtils::Typemap', 'ExtUtils::Typemaps');
  my $second = ExtUtils::Typemap->new(file => $second_typemap_file);
  _isa_any_ok($second, 'ExtUtils::Typemap', 'ExtUtils::Typemaps');

  $first->merge(typemap => $second);

  is($first->as_string(), slurp($combined_typemap_file), "merging produces expected output");
}

SCOPE: {
  my $first = ExtUtils::Typemap->new(file => $first_typemap_file);
  _isa_any_ok($first, 'ExtUtils::Typemap', 'ExtUtils::Typemaps');
  my $second_str = slurp($second_typemap_file);

  $first->add_string(string => $second_str);

  is($first->as_string(), slurp($combined_typemap_file), "merging (string) produces expected output");
}
