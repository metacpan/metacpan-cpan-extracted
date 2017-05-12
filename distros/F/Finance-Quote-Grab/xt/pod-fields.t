#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2015 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Finance-Quote-Grab.  If not, see <http://www.gnu.org/licenses/>.


# Check that the supported fields described in each pod matches what the
# code says.

use 5.005;
use strict;
use FindBin;
use ExtUtils::Manifest;
use File::Spec;
use Test::More;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
# use Smart::Comments;

# new in 5.6, so unless got it separately with 5.005
eval { require Pod::Parser }
  or plan skip_all => "Pod::Parser not available -- $@";
plan tests => 4;

require MyPodParser;

my $toplevel_dir = File::Spec->catdir ($FindBin::Bin, File::Spec->updir);
my $manifest_file = File::Spec->catfile ($toplevel_dir, 'MANIFEST');
my $manifest = ExtUtils::Manifest::maniread ($manifest_file);

my @check_files = grep {m{^lib/.*\.pm$}} keys %$manifest;
foreach my $filename (@check_files) {
  check_file ($filename);
}

sub check_file {
  my ($filename) = @_;
  diag "check_file: $filename";

  my $class = $filename;
  $class =~ s{^lib/}{};
  $class =~ s{\.pm$}{};
  $class =~ s{/}{::}g;
  ### check_file
  ### $filename
  ### $class

  $filename = File::Spec->rel2abs ($filename, $toplevel_dir);
  my $parser = MyPodParser->new;
  $parser->parse_from_file ($filename);
  my $pod_fields = $parser->fields_found;

  require $filename;
  my %labels = $class->labels;
  foreach my $method (keys %labels) {
    my $code_fields = $labels{$method};
    ### $pod_fields
    ### $code_fields

    $pod_fields = [ sort @$pod_fields ];
    $code_fields = [ sort @$code_fields ];
    is_deeply ($pod_fields, $code_fields,
               "pod vs code fields, $filename");
  }
}

exit 0;
