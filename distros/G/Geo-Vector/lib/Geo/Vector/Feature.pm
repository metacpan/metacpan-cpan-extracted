package Geo::Vector::Feature;
# @brief A root class for complex features.

use strict;
use warnings;
use Carp;
use Encode;
use Geo::GDAL;
use Geo::OGC::Geometry;

sub new {
    my $package = shift;
    my %params = @_;
    my $self = { properties => {} };
    bless $self => (ref($package) or $package);
    $self->{class} = $params{class} if exists $params{class};
    $self->{class} = 'Feature' unless $self->{class};
    $self->GeoJSON($params{GeoJSON}) if ($params{GeoJSON});
    return $self;
}

sub _Geometry {
    my($self, $object) = @_;
    # set type 25D depending on the actual dimension
    my $geometry;
    if ($object->{type} eq 'GeometryCollection') {
	$geometry = Geo::OGR::Geometry->create( Type => $object->{type} );
	for my $g (@{$object->{geometries}}) {
	    $geometry->AddGeometry($self->_Geometry($g));
	}
    } else { # assuming a non-collection geometry
	$geometry = Geo::OGR::Geometry->create( Type => $object->{type}, Points => $object->{coordinates} );
    }
    return $geometry;
}

sub GeoJSON {
    my($self, $object) = @_;
    if ($object) {
	if ($object->{type} eq 'Feature') {
	    $self->{OGRGeometry} = $self->_Geometry($object->{geometry});
	    my $to = $self->{properties};
	    my $from = $object->{properties};
	    for my $field (keys %$from) {
		$to->{$field} = $from->{$field};
	    }
	} else { # assuming a geometry
	    $self->{OGRGeometry} = $self->_Geometry($object);
	}
    } else {
	$object->{type} = 'Feature';
	my $from = $self->{properties};
	my $to = $object->{properties} = {};
	for my $field (keys %$from) {
	    $to->{$field} = $from->{$field};
	}
	my $type = $self->{OGRGeometry}->GeometryType;
	$type =~ s/25D//;
	if ($type =~ /Collection/) {
	    $object->{geometry}{type} = $type;
	    $object->{geometry}{geometries} = [];
	    for my $i (0..$self->{OGRGeometry}->GetGeometryCount-1) {
		my $g = $self->{OGRGeometry}->GetGeometryRef($i);
		my $type = $g->GeometryType;
		$type =~ s/25D//;
		my $geometry = { type => $type, coordinates => $g->Points };
		push @{$object->{geometry}{geometries}}, $geometry;
	    }
	} else {	    
	    $object->{geometry}{type} = $type;
	    $object->{geometry}{coordinates} = $self->{OGRGeometry}->Points;
	}
    }
    return $object;
}

sub Schema {
    my($self) = @_;
    my $s = Gtk2::Ex::Geo::Schema->new;
    my @fields;
    for my $f (sort keys %{$self->{properties}}) {
	next if $f eq 'class';
	push @fields, { Name => $f, Type => 'Scalar' }; # this needs more work
    }
    my $type = $self->{OGRGeometry} ? $self->{OGRGeometry}->GeometryType : '';
    $s->{GeometryType} = $type;
    $s->{Fields} = \@fields;
    return $s;
}

sub DeleteField {
    my($self, $field) = @_;
    delete $self->{properties}{$field};
}

sub Field {
    my($self, $field, $value) = @_;
    $self->{properties}{$field} = $value if defined $value;
    $self->{properties}{$field};
}
*GetField = *Field;
*SetField = *Field;

sub GetFieldCount {
    my($self) = @_;
    return sort keys %{$self->{properties}};
}

sub Geometry {
    my($self, $geometry) = @_;
    $self->{OGRGeometry} = $geometry if $geometry;
    return $self->{OGRGeometry};
}
*SetGeometry = *Geometry;
*GetGeometryRef = *Geometry;

# FID is unique within a layer, thus only the owning layer can legally
# set the fid.
sub FID {
    my($self) = @_;
    return $self->{FID};
}
*GetFID = *FID;

sub Row {
    my($self, %row) = @_;
    for my $key (keys %row) {
	if ($key eq 'FID') {
	} elsif ($key eq 'Geometry') {
	    $self->Geometry($row{Geometry});
	} else {
	    $self->Field($row{$key});
	}
    }
    %row = ( FID => $self->FID, Geometry => $self->Geometry );
    for my $key (keys %{$self->{properties}}) {
	$row{$key} = $self->{properties}{$key};
    }
    return \%row;
}

1;
