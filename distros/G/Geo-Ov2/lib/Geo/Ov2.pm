package Geo::Ov2;

our @ISA = qw(IO::File);

use warnings;
use strict;
require IO::File;
use Carp;
use POSIX;
use locale;
use Locale::TextDomain 'net.suteren.POI.todevice';


=head1 NAME

Geo::Ov2 - Library for reading and writing TomTom Navigator .ov2 POI files.

Extends L<IO::File>

=head1 VERSION

Version 0.91

=cut

our $VERSION = '0.91';

our %defaults = ( repart_size=> 10, repartition => 1, deareize => 0 );
our %params;

=head1 SYNOPSIS

Because this is a child of L<IO::File>, all functions of L<IO::File> are accessibe. No overriding is done.

The core of this module is done by two main methods poiread and poiwrite.

There are also another supporting functions, such as area_envelope, deareizator, split_area which works with ov2 record 0x01 - area and makes TTN working faster.

The third sort of methods are getters/setters, which controls behavior of the module. These are deareize, repartition and repart_size.

And at the end thera are poireadall and poiwriteall, which reads and writes array of pois. Poiwriteall do also rearealization, if repartition flag is set and stripes original 0x01 records if deareize flag is set.

Perhaps a little code snippet.

    use Geo::Ov2;

    my $ov2 = Geo::Ov2->new( "<filename" );
    
    while ( my $poi = $ov2->poiread() ) {
	printf "type: %d; longitude: %f; latitude: %f; description: %s\n", ${$poi}{type}, ${$poi}{longitude}, ${$poi}{latitude}, ${$poi}{description};
    }

    my @pois = @{$ov2->poireadall()};
    foreach $poi (@pois) {
	printf "type: %d; longitude: %f; latitude: %f; description: %s\n", ${$poi}{type}, ${$poi}{longitude}, ${$poi}{latitude}, ${$poi}{description};
    }

    $ov2->poiwrite( { type => 2, longitude => 4000000, latitude => 1200000, descrption => "my POI" } );
    $ov2->poiwriteall( @pois );

    @pois = @{$self->deareizator( @pois )};
    @pois = @{$self->split_area( 0, @pois )};

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 _params

This is an internal function, which allows set and get parameters for each instance. This is required because of parrent L<IO::File> uses fle descriptor as $self, so it can not be used for storing other data.

=cut

sub _params {
	my $self = shift;
	my $params = shift;
	$params{$self} = $params if defined $params;
	$params{$self} = {} unless exists $params{$self};
	return $params{$self};
}

=head2 deareize

This is a getter and setter of deareize flag for specific instance of object.

=cut

sub deareize {
	my $self = shift;
	return $self->_param( "deareize", $_[0] );
}

=head2 repartition

This is a getter and setter of repartition flag for specific instance of object.

=cut

sub repartition {
	my $self = shift;
	return $self->_param( "repartition", $_[0] );
}

=head2 repart_size

This is a getter and setter of repart_size value for specific instance of object.

=cut

sub repart_size {
	my $self = shift;
	return $self->_param( "repart_size", $_[0] );
}

=head2 _param

This is an internal function, which allows set and get parameters for each instance. This is required because of parrent L<IO::File> uses fle descriptor as $self, so it can not be used for storing other data.

=cut

sub _param {
	my $self = shift;
	my $key = shift;
	croak __"undefined parameter." unless defined $key;
	my $new_value = shift;
	my %params = %{$self->_params};
	if ( defined $new_value ) {
		$params{$key} = $new_value;
		$self->_params( \%params );
	}
	unless ( defined $params{$key} ) {
		$params{$key} = $defaults{$key};
		$self->_params( \%params );
	}
	return $params{$key};
}

=head2 poiwrite

This method writes data referenced by hashref into ov2 file.
if "data" atribute is provided, it is written into a file, otherwise method pack data supplied in other attributes, fills "data" attribude and then it is written.

=head3 input

inpus is a hashref, which has following structure:

    {
        type => 2,
        longitude => 5000000,
        latitude => 1100000,
        description => "some text",
        data => "packed above data into binary form of ov2"
    }

=cut

sub poiwrite {
	my $self = shift;
	my $poi  = shift;
	my %poi  = %$poi;
	my $data = $poi{data};
	unless ( exists $poi{data} ) {
		my $type      = $poi{type};
		my $longitude = $poi{longitude};
		my $latitude  = $poi{latitude};
		if ( $type == 0x01 ) {
			my $longitude2 = $poi{longitude2};
			my $latitude2  = $poi{latitude2};
			my $size     = $poi{size};
			$data = pack "CVVVVV", $type, $size, $longitude, $latitude,
			  $longitude2, $latitude2;
		} elsif ( $type == 0x02 ) {
			my $description = $poi{description};
			$data = pack "CVVV", $type, 13 + lenght $description, $latitude,
			  $longitude;
			$data = $data . $description;
		} elsif ( $type == 0x04 ) {
			$data = pack "C", $type;
			$data = $data . substr( pack( "V", $longitude ), 1 );
			$data = $data . substr( pack( "V", $latitude ),  1 );
		} elsif ( $type == 0x05 or $type == 0x15 ) {
			my $description = $poi{description};
			$data = pack "C", $type;
			$data = $data . substr( pack( "V", $longitude ), 1 );
			$data = $data . substr( pack( "V", $latitude ),  1 );
			$data = $data . substr( $description, 0, 2 );    # TODO
		} elsif ( $type == 0x06 ) {
			my $description = $poi{description};
			$data = pack "C", $type;
			$data = $data . substr( pack( "V", $longitude ), 1 );
			$data = $data . substr( pack( "V", $latitude ),  1 );
			$data = $data . substr( $description, 0, 3 );    # TODO
		} elsif ( $type == 0x07
			or $type == 0x08
			or $type == 0x18
			or $type == 0x09
			or $type == 0x19
			or $type == 0x0a
			or $type == 0x1a
			or $type == 0x0c )
		{
			my $description = $poi{description};
			$data = pack "CC", $type, length $description;
			$data = $data . substr( pack( "V", $longitude ), 1 );
			$data = $data . substr( pack( "V", $latitude ),  1 );
			$data = $data . $description;
		} else {
			croak "Unknown type of POI.";
		}
	}
	print {$self} $data;

}

=head2 poiread

This method reads data  from ov2 file and returns hashref into POI structure:

    {
        type => 2,
        longitude => 5000000,
        latitude => 1100000,
        description => "some text",
        data => "packed above data into binary form of ov2"
    }

=cut

sub poiread {
	my $self = shift;
	my $res = read( $self, my $buff, 1);
	return undef unless $res and $res == 1;
	my $data = $buff;
	my $type = unpack "C", $buff;
	my %poi;
	if ( $type == 0x01 ) {
		read( $self, $buff, 20 ) == 20
		  or croak __"Unexpected end of ov2 file.";
		#next if $repartition;
		$data = $data . $buff;
		my ( $size, $longitude, $latitude, $longitude2, $latitude2 ) =
		  unpack "VVVVV", $buff;
		%poi = (
			type       => $type,
			size       => $size,
			longitude  => $longitude,
			latitude   => $latitude,
			longitude2 => $longitude2,
			latitude2   => $latitude2,
			data => $data
		);
	} elsif ( $type == 0x02 ) {
		read( $self, $buff, 4 ) == 4
		  or croak __"Unexpected end of ov2 file.";
		$data = $data . $buff;
		my $size = unpack "V", $buff;
		read( $self, $buff, 8 ) == 8
		  or croak __"Unexpected end of ov2 file.";
		$data = $data . $buff;
		my ( $longitude, $latitude ) = unpack "VV", $buff;
		read( $self, $buff, $size - 13 ) == $size - 13
		  or croak __"Unexpected end of ov2 file.";
		$data = $data . $buff;
		%poi  = (
			type        => $type,
			size        => $size,
			longitude   => $longitude,
			latitude    => $latitude,
			data        => $data,
			description => $buff
		);
	} elsif ( $type == 0x04 ) {
		read( $self, $buff, 3 ) == 3
		  or croak __"Unexpected end of ov2 file.";
		$data = $data . $buff;
		my $tmp = "00" . $buff;
		read( $self, $buff, 3 ) == 3
		  or croak __"Unexpected end of ov2 file.";
		$data = $data . $buff;
		$tmp  = $tmp . "00" . $buff;
		my ( $longitude, $latitude ) = unpack "VV", $tmp;
		%poi = (
			type      => $type,
			longitude => $longitude,
			latitude  => $latitude,
			data      => $data
		);
	} elsif ( $type == 0x05 or $type == 0x15 ) {
		read( $self, $buff, 3 ) == 3
		  or croak __"Unexpected end of ov2 file.";
		$data = $data . $buff;
		my $tmp = "00" . $buff;
		read( $self, $buff, 3 ) == 3
		  or croak __"Unexpected end of ov2 file.";
		$data = $data . $buff;
		$tmp  = $tmp . "00" . $buff;
		my ( $longitude, $latitude ) = unpack "VV", $buff;
		read( $self, $buff, 2 ) == 2
		  or croak __"Unexpected end of ov2 file.";
		$data = $data . $buff;
		%poi  = (
			type        => $type,
			longitude   => $longitude,
			latitude    => $latitude,
			data        => $data,
			description => $buff
		);
	} elsif ( $type == 0x06 ) {
		read( $self, $buff, 3 ) == 3
		  or croak __"Unexpected end of ov2 file.";
		$data = $data . $buff;
		my $tmp = "00" . $buff;
		read( $self, $buff, 3 ) == 3
		  or croak __"Unexpected end of ov2 file.";
		$data = $data . $buff;
		$tmp  = $tmp . "00" . $buff;
		my ( $longitude, $latitude ) = unpack "VV", $buff;
		read( $self, $buff, 3 ) == 3
		  or croak __"Unexpected end of ov2 file.";
		$data = $data . $buff;
		%poi  = (
			type        => $type,
			longitude   => $longitude,
			latitude    => $latitude,
			description => $buff,
			data        => $data
		);
	} elsif ( $type == 0x07
		or $type == 0x08
		or $type == 0x18
		or $type == 0x09
		or $type == 0x19
		or $type == 0x0a
		or $type == 0x1a
		or $type == 0x0c )
	{
		read( $self, $buff, 1 ) == 1
		  or croak __"Unexpected end of ov2 file.";
		$data = $data . $buff;
		my $size = unpack "C", $buff;
		read( $self, $buff, 3 ) == 3
		  or croak __"Unexpected end of ov2 file.";
		$data = $data . $buff;
		my $tmp = "00" . $buff;
		read( $self, $buff, 3 ) == 3
		  or croak __"Unexpected end of ov2 file.";
		$data = $data . $buff;
		$tmp  = $tmp . "00" . $buff;
		my ( $longitude, $latitude ) = unpack "VV", $buff;
		read( $self, $buff, $size ) == $size
		  or croak __"Unexpected end of ov2 file.";
		$data = $data . $buff;
		%poi  = (
			type        => $type,
			size        => $size,
			longitude   => $longitude,
			latitude    => $latitude,
			description => $buff,
			data        => $data
		);
	} else {
		croak __"Unknown type of POI.";
	}
	return \%poi;
}

=head2 poiwriteall

Method gets array of hashrefs into POIs and writes it into ov2 file.
When deareize is set, it also strips all 0x01 records (area) befor writting.
When repartition is set, it does deareize and then it creates own area structure for POIs in array. Then all it is written to ov2 file.

=cut

sub poiwriteall {
	my $self     = shift;
	my @pois     = @_;
	#printf STDERR "%d %d\n", $self->repartition, $self->deareize;
	@pois = @{$self->deareizator( @pois )} if ( $self->repartition or $self->deareize );
	@pois = @{$self->split_area( 0, @pois )} if $self->repartition;
	foreach my $poi (@pois) {
		$self->poiwrite($poi);
	}
}

=head2 poireadall

This method reads the whole ov2 file and returns array of hashrefs into POI structures.

=cut

sub poireadall {
	my $self = shift;
	my @pois;
	while ( my $poi = $self->poiread() ) {
		my %poi = %$poi;
		push @pois, \%poi;
	}
	return \@pois;
}

=head2 area_envelope

This method expects array of hashrefs into POIs and returns structure of 0x01 record, which is area for these POIs.

=cut

sub area_envelope {
	my $self = shift;
	my @pois = @_;
	my ( $longitude2, $longitude, $latitude2, $latitude ) = ( undef, undef, undef, undef );
	my $size = 0;
	my $atleastone = 0;
	foreach my $i (@pois) {
		my %poi = %$i;
		$atleastone = 1;
		$longitude2 = $poi{longitude} unless defined $longitude2;
		$longitude = $poi{longitude} unless defined $longitude;
		$latitude2 = $poi{latitude} unless defined $latitude2;
		$latitude = $poi{latitude} unless defined $latitude;
		$longitude2 = $poi{longitude} if $poi{longitude} < $longitude2;
		$latitude2  = $poi{latitude} if $poi{latitude} < $latitude2;
		$longitude = $poi{longitude} if $poi{longitude} > $longitude;
		$latitude  = $poi{latitude} if $poi{latitude} > $latitude;
		my $type = $poi{type};
		if ( $type == 0x01 ) {
			$size += 21;
		} elsif ( $type == 0x02 ) {
			$poi{size} = 13 + length $poi{description} unless $poi{size};
			$size += $poi{size};
		} elsif ( $type == 0x04 ) {
			$size += 7;
		} elsif ( $type == 0x05 or $type == 0x15 ) {
			$size += 9;
		} elsif ( $type == 0x06 ) {
			$size += 10;
		} elsif ( $type == 0x07
			or $type == 0x08
			or $type == 0x18
			or $type == 0x09
			or $type == 0x19
			or $type == 0x0a
			or $type == 0x1a
			or $type == 0x0c )
		{
			$poi{size} = length $poi{description} unless $poi{size};
			$size += $poi{size} + 8;
		} else {
			croak __"Unknown type of POI.";
		}
	}
	$size += 21;
	my $data = "";
	$data = pack( "CVVVVV", 1, $size, $longitude, $latitude, $longitude2, $latitude2 ) if $atleastone;
	$size = 21 if $atleastone;
	my %poi = ( type => 1, size => $size, longitude => $longitude, latitude => $latitude, longitude2 => $longitude2, latitude2 => $latitude2, data => $data );
	#printf "debug: %d %d %d %d\n", $longitude, $latitude, $longitude2, $latitude2;
	return \%poi;
}

=head2 deareizator

This method expects array of POI hashrefs on input and rturns reference to array which is copy of source array, but without 0x01 records.

=cut

sub deareizator {
	my $self = shift;
	my @pois = @_;
	my @poiout;
	foreach my $i ( @pois ) {
		if ( ${$i}{type} != 1 ) {
			push @poiout, \%{$i} 
		}
	}
	return \@poiout;
}

=head2 split_area

On input is array of POI hashrefs. This array must be without 0x01 records - use deareizator.
Output is reference to array which contains POIs organized into tree of areas.
This can significantly improve speed of displaying POIs in TTN.

=cut

sub split_area {
	my $self = shift;
	my $orientation = shift;
	my @pois = @_;
	$orientation++;
	#@pois = @{_sortpois( $orientation, @pois)};
	my $dimension = "longitude";
	$dimension = "latitude" if $orientation % 2;
	@pois = sort { ${$a}{$dimension} <=> ${$b}{$dimension} } @pois;

=pod

	foreach my $i ( @pois ) {
		printf STDERR "sort: %s: %d\n", $dimension, ${$i}{$dimension};
	}
	printf STDERR "========================\n";

=cut
	my $blocksize = ( ( $#pois + 1 ) / ( $self->repart_size - 1 ) ) + 1;
	if ( $#pois > $self->repart_size and $orientation < 10 ) {
		my @poiout;
		my $i = 0;
		while ( ( $i + $blocksize - 1 ) <= $#pois ) {
			my $tmp = $i;
			$i += $blocksize;
			my @tmp = @pois[$tmp ..  $i - 1 ];
			my $pois = $self->split_area($orientation, @tmp );
			push @poiout, @$pois;
		}
		if ( $i < $#pois + 1) {
			my @tmp = @pois[$i .. $#pois];
			my $pois = $self->split_area($orientation, @tmp );
			push @poiout, @$pois;
		}
		@pois = @poiout;
	}
	my %poi = %{$self->area_envelope( @pois )};
	unshift @pois, \%poi; 
	return \@pois;
}

=head1 SEE ALSO

L<IO::File>,
L<TomTom Navigator SDK|http://www.tomtom.com/lib/doc/ttnavsdk3_manual.pdf>,
L<POI file format|http://www.licour.com/gps/poi_format/poi_file_format.html>,

=head1 AUTHOR

Petr Vranik, C<< <hPa at SuTeren.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-geo-ov2 at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Ov2>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 TODO

=over 4

=item 1) Implement reading and writing poi.dat

It means operating in two modes. In mode of ov2 behavior stays the same as now. In poi.dat mode it will return hash of arrays on read and expect hash of arrays on write. The top level hash will contain categories and in each category there will be array of POIs, as returned nowadays.

=item 2) Make Czech translations of README and INSTALL.

=item 3) Implement seekability on POI basis.

=item 4) Implement other IO::File methods on POI basis.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Ov2

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Ov2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Ov2>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Ov2>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Ov2>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Petr Vranik, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Geo::Ov2
