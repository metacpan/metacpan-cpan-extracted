#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# 0-examples-xrefs.t is shared by several distributions.
#
# 0-examples-xrefs.t is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# 0-examples-xrefs.t is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

BEGIN { require 5 }
use strict;
use ExtUtils::Manifest;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $manifest = ExtUtils::Manifest::maniread();
my @example_files = grep m{examples/.*\.pl$}, keys %$manifest;
my @lib_files = grep m{lib/.*\.(pm|pod)$}, keys %$manifest;

sub any_file_contains_example {
  my ($example) = @_;
  my $filename;
  foreach $filename (@lib_files) {
    if (pod_contains_example($filename, $example)) {
      return 1;
    }
  }
  foreach $filename (@example_files) {
    if ($filename ne $example
        && raw_contains_example($filename, $example)) {
      return 1;
    }
  }
  return 0;
}

sub pod_contains_example {
  my ($filename, $example) = @_;
  open FH, "< $filename" or die "Cannot open $filename: $!";
  my $content = do { local $/; <FH> }; # slurp
  close FH or die "Error closing $filename: $!";
  return scalar ($content =~ /F<\Q$example\E>
                            |F<examples>\s+directory
                             /xs);
}
sub raw_contains_example {
  my ($filename, $example) = @_;
  $example =~ s{^examples/}{};
  open FH, "< $filename" or die "Cannot open $filename: $!";
  my $ret = scalar (grep /\b$example\E\b/, <FH>);
  close FH or die "Error closing $filename: $!";
  return $ret > 0;
}


plan tests => scalar(@example_files);
my $example;
foreach $example (@example_files) {
  is (any_file_contains_example($example), 1,
      "$example mentioned in some lib/ file");
}

exit 0;
