package Geo::Cartogram;

use 5.008008;
use strict;

use Geo::ShapeFile;

our $VERSION = '0.01';

=head1 NAME

Geo::Cartogram - Perl extension for generating cartograms

=head1 SYNOPSIS

  use Geo::Cartogram;

  my $cart = Geo::Cartogram->new('world.shp');

  # Generates map.gen file as expected by cartogram program
  $cart->generateMapFile('cartogram/map.gen');

  # Generate census.dat file, this will result in homogeneous cartogram
  $cart->generateDataFile('cartogram/census.dat');

  # Use subroutine to get region atribute
  my $getPopulation = sub {
    my $country = shift;
    return $mylib->getPopulation($country->{name});
  };

  $cart->generateDataFile('cartogram/census.dat', $getPopulation);

  chdir('cartogram');
  system('./cartogram');

=head1 DESCRIPTION

A cartogram is a map in which the sizes of the enumeration units have been rescaled according
to an attribute they posses rather than their actual size.

Resizing a map's regions in a way that keeps the map recognizable is a difficult problem. Michael Gastner
proposed a method and made available a C program to generate cartograms. By now, Geo::Cartogram simply
takes a map in ESRI's shapefile format (.shp) and a user-defined function to generate the files needed for
Gastner's program to run. See "CARTOGRAM PROGRAM" below.

=head1 CONSTRUCTOR

=over 4

=item new($shapeFile)

Receives the path of file in ESRI's shapefile format. The ".shp" is optional, there must also be the .dbf and .shx files
in same dir.

=cut

sub new {
    my $pack = shift;
    my $fileName = shift;

    $fileName =~ s/(\.shp)?$/.shp/i;

    my $shapefile = new Geo::ShapeFile($fileName) 
	or return undef;

    bless { SHAPE => $shapefile }, $pack;
}

sub shape { shift->{SHAPE} }

=pod

=back

=head1 METHODS

=over 4

=item generateMapFile($mapfile);

This will read map polygons information from shapefile and write $mapfile in format expected by cartogram
program. The file format is the same as exported by ArcInfo program. You probably want to call this file map.gen.

=cut

sub generateMapFile {
    my $self = shift;
    my $mapfile = shift || 'map.gen';

    open GEN, ">$mapfile" or die "Can't open $mapfile for writing: $!";

    foreach my $shapeId (1 .. $self->shape->shapes()) {
	my $shape = $self->shape->get_shp_record($shapeId);

	foreach my $partId (1 .. $shape->num_parts()) {
	    print GEN $shapeId, "\n";

	    my @segments = $shape->get_segments($partId);

	    foreach my $segment (@segments) {
		print GEN $segment->[0]->{X}, " ", $segment->[0]->{Y}, "\n";
	    }
	    my $segment = pop @segments;
	    print GEN $segment->[1]->{X}, " ", $segment->[1]->{Y}, "\n";
	    print GEN "END\n";
	}
    }

    print GEN "END\n";

    close GEN;

    1;
}

=pod

=item generateDataFile($datafile, [$attributeFunction]);

This will generate a data file containing the relative size of each region of the map and write it to
$datafile, which cartogram program expects to be called census.dat.

$attributeFunction is a subroutine reference that receives a hashref containing all information from a
map region (according to DBF file that comes with shapefile) and returns its relative size. If no
function is given, all regions will be drawn with equal size.

=cut

sub generateDataFile {
    my $self = shift;
    my $datafile = shift || 'census.dat';
    my $sizeSub = shift || sub { 1 };

    ref($sizeSub) eq 'CODE' or die "generateDataFile expects a subroutine as second parameter";

    open DAT, ">$datafile" or die "Can't open $datafile for writing: $!";
    
    foreach my $shapeId (1 .. $self->shape->shapes()) {
	my $regionData = $self->shape->get_dbf_record($shapeId);

	my $size = &$sizeSub($regionData);

	print DAT "$shapeId $size\n";
    }
    close DAT;

    1;
}

=pod

=back

=head1 CARTOGRAM PROGRAM

cartogram.c was written by Michael Gastner and is available for download at http://www.santafe.edu/%7Emgastner/.

Its license is not clearly stated, but the author let you use it and doesn't say any restriction, just ask you
to acknowledge the use of his code and its first publication as below in any output of the code:
 
"Generating population density-equalizing maps", Michael T. Gastner and M. E. J. Newman,
Proceedings of the National Academy of Sciences of the United States of America, vol. 101, pp. 7499-7504, 2004.

In my debian system with gcc 4.1 I had some trouble compiling cartogram.c. I had to:

- add "#include <stdlib.h>" in the beginning cartogram.c
- manually link GNU math library when compiling: gcc -o cartogram -lm /usr/lib/libm.a cartogram.c

=head1 SEE ALSO

Geo::ShapeFile
http://www.santafe.edu/%7Emgastner/
http://www.sasi.group.shef.ac.uk/worldmapper/

=head1 AUTHOR

Luis Fagundes, E<lt>lhfagundes@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Luis Fagundes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
__END__
