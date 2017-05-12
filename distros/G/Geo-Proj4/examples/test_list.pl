#!/usr/bin/env perl
# when run, it will show all definitions.
use warnings;
use strict;

use lib qw[blib/lib blib/arch ../blib/lib ../blib/arch];

use Geo::Proj4;

print "Ellisoids:\n";
my @ells = Geo::Proj4->listEllipsoids;
foreach my $ell (@ells)
{   my $def = Geo::Proj4->ellipsoidInfo($ell);
    print "  $ell: $def->{name}\n"
        , "      ellipses: $def->{ell}"
        , ", major: $def->{major}\n";
}

print "\nUnits:\n";
my @units = Geo::Proj4->listUnits;
foreach my $unit (@units)
{   my $def = Geo::Proj4->unitInfo($unit);
    printf "  %6s: %12.6f meter; %s\n", $unit, $def->{to_meter}, $def->{name};
}

print "\nDatums:\n";
my @datums = Geo::Proj4->listDatums;
foreach my $datum (@datums)
{   my $def = Geo::Proj4->datumInfo($datum);
    print "  $datum: ", ($def->{comments}||''), "\n"
        , "      $def->{definition}\n";
}

print "\nProjections:\n";
my @types = Geo::Proj4->listTypes;
foreach my $type (@types)
{   my $def = Geo::Proj4->typeInfo($type);
    my $descr = $def->{description} || '';
    $descr  =~ s/\s*\z//;
    $descr .= "\n(has inverse)" if $def->{has_inverse};
    $descr  =~ s/\n\s*/\n      /g;
    print "  $type: $descr\n";
}
