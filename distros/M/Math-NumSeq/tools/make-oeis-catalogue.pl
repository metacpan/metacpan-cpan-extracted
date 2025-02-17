#!perl -w

# Copyright 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl tools/make-oeis-catalogue.pl
#

use 5.004;
use strict;
use Cwd;
use Getopt::Long;
use Data::Dumper;
use ExtUtils::Manifest;
use Module::Util;
use File::Path;

use vars '$VERSION';
$VERSION = 75;

# uncomment this to run the ### lines
# use Smart::Comments;

my $outmodule = 'BuiltinTable';
my $distname = 'Math-NumSeq';
my $outversion = $VERSION;
my $other = '';

Getopt::Long::GetOptions
  ('dist=s'       => \$distname,
   'module=s'     => \$outmodule,
   'outversion=s' => \$outversion,
   'other=s'      => \$other,
  );
if (@ARGV) {
  die "Unrecognised options ",join(' ',@ARGV);
}
my $outdirname = "lib/Math/NumSeq/OEIS/Catalogue/Plugin/";
my $outfilename = "$outdirname/$outmodule.pm";

my %seen;
my $exit_code = 0;

my @info_arrayref;
my @filenames;
if (Cwd::getcwd() =~ /devel$/) {
  @filenames = glob "lib/Math/NumSeq/*.pm";
} else {
  my $manifest_href = ExtUtils::Manifest::maniread();
  @filenames = keys %$manifest_href;
}
### @filenames

# files for Math::NumSeq::Foo, and not sub-parts
@filenames = grep { m{^(lib/Math/NumSeq/[^/]*
                      |lib/App/MathImage/NumSeq/[^/]*)$}x
                    } @filenames;
@filenames = sort @filenames;

my $module_count = 0;
my $anum_count = 0;

foreach my $filename (@filenames) {
  my $class = $filename;
  $class =~ s{^lib/}{};
  $class = Module::Util::path_to_module($class);
  $module_count++;

  ### $filename
  ### $class

  open my $in, '<', $filename
    or die "Cannot open $filename";
  while (<$in>) {
    chomp;
    my $where = "$filename:$.";
    my $type = 'Catalogue';
    my ($anum, $parameters, $comment);
    if (/^[ \t]*# OEIS-(Catalogue|Other): /) {
      ### OEIS-Catalogue
      ($type, $anum, $parameters, $comment)
        = /^[ \t]*# OEIS-(Catalogue|Other): +(A[0-9]+)\s*(.*?)(#.*)?$/
          or die "$where: oops, bad OEIS line: $_";
    } elsif (/^use constant oeis_anum\W/) {
      ### use constant
      ($anum, $comment) = /^use constant oeis_anum\s*=>\s*['"]?(.*?)['"].*?(#.*)?/
        or die "$where: oops, bad OEIS line: $_";
      $parameters = '';
    } elsif (/OEIS-Catalogue array begin/ .. /OEIS-Catalogue array end/) {
      next if /^\s*undef/;
      next if /^\s*# OEIS-Catalogue array/;
      next if /^\s*(#|$)/;
      ($anum,$parameters,$comment) = /^[^#]*'(A\d+)',?\s*(?:#\s*(.*?)(#.*)?)?$/
        or die "$where: oops, bad OEIS array line: $_";
      defined $parameters
        or die "$where: no parameters comment part in array line: $_";
    } else {
      next;
    }
    ### $type
    ### $anum
    ### $parameters
    ### $comment

    if ($other eq '') {
      next if $type eq 'Other';
    } elsif ($other eq 'only') {
      next if $type ne 'Other';
    } elsif ($other eq 'both') {
    } else {
      die "Unrecognised --other";
    }

    $anum or die "$where: oops, no OEIS number: $_";

    my @parameters = split /[ \t]+/, $parameters;
    @parameters = map {/(.*?)=(.*)/
                         or die "$where: oops, unrecognised parameter $_";
                       ($1,$2)}
      @parameters;
    ### @parameters
    if (@parameters & 1) {
      die "Oops, odd number of  OEIS params: $_";
    }
    defined $class
      or die "$filename:$.: oops, no \"package\" line";

    if ($type ne 'Other') {
      if ($seen{$anum}) {
        print STDERR "$where: duplicate of $anum\n$seen{$anum}: is here\n";
        $exit_code = 1;
        next;
      }
      $seen{$anum} = $where;
    }

    push @info_arrayref,
      {
       anum  => $anum,
       class => $class,
       (scalar(@parameters) ? (parameters => \@parameters) : ()),
      };
    $anum_count++;
  }
  close $in or die;
}

my $dump = Data::Dumper->new([\@info_arrayref])->Sortkeys(1)->Terse(1)->Indent(1)->Dump;
# $dump =~ s/^{\n//;
# $dump =~ s/}.*\n//;

# mangle digit strings '123' to number literals 123
# but not '00' or similar strings with leading zeros
$dump =~ s/'(0|[1-9]\d*)'/$1/g;

my $part='part';
File::Path::make_path ($outdirname);
open my $out, '>', $outfilename
  or die "Cannot create $outfilename: $!";
print $out <<"HERE";
# Copyright 2011, 2012, 2013, 2014 Kevin Ryde

# Generated by Math-NumSeq tools/make-oeis-catalogue.pl -- DO NOT EDIT

# This file is $part of $distname.
#
# $distname is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# $distname is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with $distname.  If not, see <http://www.gnu.org/licenses/>.

package Math::NumSeq::OEIS::Catalogue::Plugin::$outmodule;
use 5.004;
use strict;

use vars '\$VERSION', '\@ISA';
\$VERSION = $outversion;
use Math::NumSeq::OEIS::Catalogue::Plugin;
\@ISA = ('Math::NumSeq::OEIS::Catalogue::Plugin');

## no critic (CodeLayout::RequireTrailingCommaAtNewline)

# total $anum_count A-numbers in $module_count modules

use constant info_arrayref =>
HERE

print $out "$dump;\n1;\n__END__\n";
print "wrote $outfilename\n";
exit $exit_code;
