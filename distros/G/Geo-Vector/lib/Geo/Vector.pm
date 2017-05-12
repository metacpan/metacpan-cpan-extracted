package Geo::Vector;

## @class Geo::Vector
# @brief A geospatial layer that consists of Geo::OGR::Features.
#
# This module should be discussed in geo-perl@list.hut.fi.
#
# The homepage of this module is 
# http://geoinformatics.tkk.fi/twiki/bin/view/Main/GeoinformaticaSoftware.
#
# @author Ari Jolma
# @author Copyright (c) 2005- by Ari Jolma
# @author This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.5 or,
# at your option, any later version of Perl 5 you may have available.

=pod

=head1 NAME

Geo::Vector - Perl extension for geospatial vectors

The <a href="http://map.hut.fi/doc/Geoinformatica/html/">documentation
of Geo::Vector</a> is in doxygen format.

=cut

use 5.008;
use strict;
use warnings;
use Carp;
use Encode;
use POSIX;
POSIX::setlocale( &POSIX::LC_NUMERIC, "C" ); # http://www.remotesensing.org/gdal/faq.html nr. 11
use Scalar::Util qw(blessed);
use XSLoader;
use File::Basename;
use Geo::GDAL;
use Geo::OGC::Geometry;
use Geo::Vector::Feature;
use Geo::Vector::Layer;
use JSON::XS;
use Gtk2;

use vars qw( @ISA %RENDER_AS );

our $VERSION = '0.52';

require Exporter;

@ISA = qw( Exporter );

our %EXPORT_TAGS = ( 'all' => [qw( %RENDER_AS )] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# from ral_visual.h:
%RENDER_AS = ( Native => 0, Points => 1, Lines => 2, Polygons => 4 );

## @ignore
# tell dynaloader to load this module so that xs functions are available to all:
sub dl_load_flags {0x01}

XSLoader::load( 'Geo::Vector', $VERSION );

## @cmethod @geometry_types()
#
# @brief Returns a list of valid geometry types.
#
# @return a list of valid geometry types (as strings).
sub geometry_types {
    return @Geo::OGR::Geometry::GEOMETRY_TYPES;
}

## @cmethod @render_as_modes()
#
# @brief Returns a list of valid render as modes.
#
# @return a list of valid render as modes (as strings).
sub render_as_modes {
    return keys %RENDER_AS;
}

## @cmethod ref %layers($driver, $data_source)
#
# @brief Lists the layers that are available in a data source.
# @return A hashref to a (layer_name => geometry_type) hash.
sub layers {
    my($driver, $data_source) = @_;
    $driver = '' unless $driver;
    $data_source = '' unless $data_source;
    my $self = {};
    open_data_source($self, $driver, $data_source, 0);
    return unless $self->{OGR}->{DataSource};
    my %layers;
    for my $i ( 0 .. $self->{OGR}->{DataSource}->GetLayerCount - 1 ) {
	my $l  = $self->{OGR}->{DataSource}->GetLayerByIndex($i);
	my $fd = $l->GetLayerDefn();
	my $t  = $fd->GetGeomType;
	next unless exists $Geo::OGR::Geometry::TYPE_INT2STRING{$t};
	$layers{ $l->GetName } = $Geo::OGR::Geometry::TYPE_INT2STRING{$t};
    }
    return \%layers;
}

## @cmethod void delete_layer($driver, $data_source, $layer)
#
# @brief Attempts to delete a layer from a datasource.
# @param[in] driver
# @param[in] data_source
# @param[in] layer Name of the layer that should be deleted.
sub delete_layer {
    my($driver, $data_source, $layer) = @_;
    my $self = {};
    open_data_source($self, $driver, $data_source, 1);
    for my $i ( 0 .. $self->{OGR}->{DataSource}->GetLayerCount - 1 ) {
	my $l = $self->{OGR}->{DataSource}->GetLayerByIndex($i);
	$self->{OGR}->{DataSource}->DeleteLayer($i), last
	    if $l->GetName() eq $layer;
    }
}

## @cmethod Geo::Vector new($data_source)
#
# @brief Create a new Geo::Vector object for the first layer in a
# given OGR data souce.
#
# An example of creating a Geo::Vector object for a ESRI shapefile:
# @code
# $v = Geo::Vector->new("borders.shp");
# @endcode
#
# @param data_source An OGR data source string
# @return A new Geo::Vector object

## @cmethod Geo::Vector new(%params)
#
# @brief Create a new Geo::Vector object.
#
# A Geo::Vector object is either a wrapped Geo::OGR::Layer or a
# collection of Geo::OGR::Feature objects. Without any parameters an
# empty OGR memory layer without any attributes is created. A feature
# collection object does not have a unique schema.
#
# @param params Named parameters, all are optional: (see also the
# named parameters of the Geo::Vector::layer method)
# - \a driver => string Name of the OGR driver for creating or opening
# a data source. If not given, an attempt is made to open the data
# source using the data source parameter.
# - \a create_options => reference to a hash of data source creation
# options. May be empty. Forwarded to
# Geo::OGR::CreateDataSource. Required to create other than memory
# data sources.
# - \a data_source => string OGR data source to create or
# open. Opening a data source is first attempted unless create_options
# is given. If open fails, creation is attempted.
# - \a open => string The layer to open.
# - \a update => boolean Set true if open in update mode.
# - \a layer => string [deprecated] Same as \a open.
# - \a create => string The layer to create.
# - \a layer_options forwarded to Geo::OGR::DataSource::CreateLayer.
# - \a SQL => string SQL-string, forwarded to
# Geo::OGR::DataSource::ExecuteSQL. An alternative to \a open and \a
# create.
# - \a geometry_type => string The geometry type for the
# new layer. Default is 'Unknown'.
# - \a schema, as in method Geo::Vector::schema.
# - \a encoding => string, the encoding of the attribute values of the
# features.
# - \a srs => either a string which defines a spatial reference system
# (e.g. 'EPSG:XXXX') or a Geo::OSR::SpatialReference object. The srs
# for the new layer. Default is 'EPSG:4326'.
# - \a features => a reference to a list of features to be inserted
# into the collection. May be empty. If given, the resulting object is
# a feature collection object, and not an OGR layer.
# - \a geometries => a reference to a list of geometries to be
# inserted as new features into the collection. Creates features
# without attributes for the geometries. May be empty. If given, the
# resulting object is a feature collection object, and not an OGR
# layer. Do not mix with \a features.
# @return A new Geo::Vector object
sub new {
    my $package = shift;
    my $self = {};
    bless $self => (ref($package) or $package);

    my %params = @_ == 1 ? ( single => $_[0] ) : @_;

    # the single parameter can be a filename, geometry, feature, or a
    # list of geometries or features, which are copied into a new
    # memory layer

    if (ref($params{single})) {
    } else {
	$params{data_source} = $params{single} if $params{single};
    }

    # aliases
    $params{data_source} = $params{filename} if $params{filename};
    $params{data_source} = $params{datasource} if $params{datasource};
    $params{open} = $params{name} if $params{name};
    $params{open} = $params{layer_name} if $params{layer_name};
    $params{open} = $params{layer} if $params{layer};
    $params{SQL} = $params{sql} if $params{sql};
    $params{layer_options} = [] unless $params{layer_options};
    $params{geometry_type} = $params{schema}{GeometryType} if ref $params{schema};

    if ($params{features} or $params{geometries}) {
	$self->{update} = 1;
	$self->{features} = {};
	if ($params{geometries}) {
	    for my $g (@{$params{geometries}}) {
		$self->geometry($g);
	    }
	} elsif (-r $params{features}) {
	    open my $fh, "<$params{features}";
	    my @a = <$fh>;
	    close $fh;
	    my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
	    my $object = $coder->decode("@a");
	    if ($object->{type} eq 'FeatureCollection') {
		for my $o (@{$object->{features}}) {
		    $self->feature(Geo::Vector::Feature->new(GeoJSON => $o));
		}
	    } else {
		$self->feature(Geo::Vector::Feature->new(GeoJSON => $object));
	    }
	} else {	
	    for my $f (@{$params{features}}) {
		$self->feature($f);
	    }
	}
	return $self;
    }

    $params{update} = 0 unless defined $params{update};
    $params{update} = 1 if $params{create};
    $self->{update} = $params{update};
    $self->{encoding} = $params{encoding};
    $params{create_options} = [] if (!$params{create_options} and $params{create});

    $self->open_data_source($params{driver}, $params{data_source}, $params{update}, $params{create_options});

    if ($params{create} or $self->{OGR}->{Driver}->{name} eq 'Memory') {

	my $srs;
	if (blessed($params{srs}) and $params{srs}->isa('Geo::OSR::SpatialReference')) {
	    $srs = $params{srs};
	} else {
	    $srs = new Geo::OSR::SpatialReference;
	    $params{srs} = 'EPSG:4326' unless $params{srs};
	    if ( $params{srs} =~ /^EPSG:(\d+)/ ) {
		eval { $srs->ImportFromEPSG($1); };
		croak "ImportFromEPSG failed: $@" if $@;
	    } else {
		croak "SRS $params{srs} not yet supported";
	    }
	}
	$params{geometry_type} = 'Unknown' unless $params{geometry_type};
	$params{layer_options} = '' unless $params{layer_options};
	croak "$self->{OGR}->{Driver}->{name}: $params{data_source}: ".
	    "Data source does not have the capability to create layers"
	    unless $self->{OGR}->{DataSource}->TestCapability('CreateLayer');
	eval {
	    $self->{OGR}->{Layer} =
		$self->{OGR}->{DataSource}->CreateLayer( $params{create}, 
							 $srs, 
							 $params{geometry_type},
							 $params{layer_options});
	};
	croak "CreateLayer failed: $@" unless $self->{OGR}->{Layer};
	
    } elsif ( $params{SQL} ) {
	    
	$self->{SQL} = $params{SQL};
	eval {
	    $self->{OGR}->{Layer} =
		$self->{OGR}->{DataSource}->ExecuteSQL( $self->{SQL} );
	};
	croak "ExecuteSQL failed: $@" unless $self->{OGR}->{Layer};
	
    } elsif ($params{open}) {
	
	$self->{OGR}->{Layer} =
	    $self->{OGR}->{DataSource}->Layer( $params{open} );
	croak "Could not open layer '$params{open}': $@" unless $self->{OGR}->{Layer};
	
    } else {
	
	# open the first layer
	$self->{OGR}->{Layer} = $self->{OGR}->{DataSource}->GetLayerByIndex();
	croak "Could not open the default layer: $@" unless $self->{OGR}->{Layer};
	
    }

    schema($self, $params{schema}) if $params{schema};
    $self->{OGR}->{Layer}->SyncToDisk unless $self->{OGR}->{Driver}->{name} eq 'Memory';
    return $self;
}

## @ignore
sub save {
    my($self, $filename) = @_;
    my $object = { type => 'FeatureCollection', features => [] };
    for my $f (values %{$self->{features}}) {
	push @{$object->{features}}, $f->GeoJSON;
    }
    my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
    my $data = $coder->encode($object);
    open my $fh, ">$filename";
    print $fh $data;
    close $fh;
}

## @ignore
sub open_data_source {
    my($self, $driver, $data_source, $update, $create_options) = @_;
    if ($driver or !$data_source) {
	if (!$data_source) {
	    $data_source = '';
	    $self->{OGR}->{Driver} = Geo::OGR::GetDriver('Memory');
	    $create_options = {};
	} elsif (blessed($driver) and $driver->isa('Geo::OGR::Driver')) {
	    $self->{OGR}->{Driver} = $driver;
	} else {
	    $self->{OGR}->{Driver} = Geo::OGR::GetDriver($driver);
	}
	croak "Can't find driver: $driver" unless $self->{OGR}->{Driver};
	
	unless ($create_options) {

	    eval {
		$self->{OGR}->{DataSource} = $self->{OGR}->{Driver}->Open($data_source, $update);
	    };
	    unless ($self->{OGR}->{DataSource}) {
		$@ = "no reason given" unless $@;
		croak "Can't open data source '$data_source': $@"
	    }
	    
	} else {

	    croak "$self->{OGR}->{Driver}->{name}: ".
		"Driver does not have the capability to create data sources"
		unless $self->{OGR}->{Driver}->TestCapability('CreateDataSource');
	    
	    eval {
		$self->{OGR}->{DataSource} = 
		    $self->{OGR}->{Driver}->CreateDataSource($data_source, $create_options);
	    };
	    $@ = "no reason given" unless $@;
	    croak "Can't open nor create data source '$data_source': $@" unless $self->{OGR}->{DataSource};

	}

    } else {
	eval {
	    $self->{OGR}->{DataSource} = Geo::OGR::Open($data_source, $update);
	};
        $@ = "no reason given" unless $@;
	croak "Can't open data source: $@" unless $self->{OGR}->{DataSource};
	$self->{OGR}->{Driver} = $self->{OGR}->{DataSource}->GetDriver;
    }
    $self->{encoding} = "utf8" if $self->{OGR}->{Driver}->GetName eq 'PostgreSQL';
}

## @ignore
sub DESTROY {
    my $self = shift;
    return unless $self;
    $self->{OGR}->{Layer}->SyncToDisk if ($self->{update} and $self->{OGR}->{Layer});
    if ( $self->{SQL} and $self->{OGR}->{DataSource} ) {
	$self->{OGR}->{DataSource}->ReleaseResultSet( $self->{OGR}->{Layer} );
    }
    delete $self->{features};
}

## @method driver()
#
# @brief The driver of the object.
# @return The name of the OGR driver as a string. Returns 'Memory' if the
# object is not an OGR layer.
sub driver {
    my $self = shift;
    return $self->{OGR}->{Driver}->GetName if $self->{OGR} and $self->{OGR}->{Driver};
    return 'Memory';
}

## @method datasource()
#
# @brief The datasource of the object.
# @return The name of the OGR datasource as a string. Returns 'Memory' if the
# object is not an OGR layer.
sub data_source {
    my $self = shift;
    return $self->{OGR}->{DataSource}->GetName if $self->{OGR}->{DataSource};
    return 'Memory';
}

## @method dump(%parameters)
#
# @brief Print the contents of the layer.
sub dump {
    my $self = shift;
    my %params = ( filehandle => \*STDOUT );
    if (@_) {
	if (@_ == 1) {
	    $params{filehandle} = shift;
	} else {
	    %params = @_ if @_;
	}
    }
    my $fh = $params{filehandle};
    my $schema = $self->schema();
    my $i = 1;
    $self->init_iterate;
    while (my $feature = $self->next_feature()) {
	print $fh "Feature $i:\n";
	my $s = $schema;
	$s = $self->schema($i-1) unless $s;
	$i++;
	for my $name ($s->field_names) {
	    next if $name =~ /^\./;
	    my $v = $feature->GetField($name);
	    $v = decode($self->{encoding}, $v) if $v and $self->{encoding};
	    print $fh "$name: $v\n";
	}
	my $geom = $feature->GetGeometryRef();
	dump_geom($geom, $fh, $params{suppress_points});
    }
}

## @ignore
sub dump_geom {
    my($geom, $fh, $supp) = @_;
    my $type = $geom->GeometryType;
    my $dim = $geom->CoordinateDimension;
    my $count = $geom->GetPointCount;
    print $fh "Geometry type: $type, Dimension: $dim, Point count: $count\n";
    if ($geom->GetGeometryCount) {
	for (0..$geom->GetGeometryCount-1) {
	    dump_geom($geom->GetGeometryRef($_), $fh, $supp);
	}
    } else {
	return if $supp;
	for my $i (1..$count) {
	    my @point = $geom->GetPoint($i-1);
	    print $fh "Point $i: @point\n";
	}
    }
}

## @method init_iterate(%options)
# @brief Reset reading features from the object iteratively.
#
# For OGR layers uses GDAL filtering. Only filter_rect is implemented
# for feature collection and filtering is only preliminary, based on
# envelopes.
#
# @param options Named parameters, all are optional.
# - \a selected_features => reference to a list of features, which to
# iterate through.
# - \a filter => a spatial filter (geometry)
# - \a filter_rect => reference to an array defining a spatial
# rectangle filter (min_x, min_y, max_x, max_y)
sub init_iterate {
    my $self = shift;
    return unless $self->isa('Geo::Vector');
    my %options = @_ if @_;
    if ($options{filter_rect}) {
	$self->{_filter} = Geo::OGR::Geometry->create(
	    GeometryType => 'Polygon',
	    Points => 
	    [[[$options{filter_rect}->[0], $options{filter_rect}->[1]],
	      [$options{filter_rect}->[0], $options{filter_rect}->[3]],
	      [$options{filter_rect}->[2], $options{filter_rect}->[3]],
	      [$options{filter_rect}->[2], $options{filter_rect}->[1]],
	      [$options{filter_rect}->[0], $options{filter_rect}->[1]]]]);
    } elsif ($options{filter}) {
	$self->{_filter} = $options{filter};
    }
    if ($options{selected_features}) {
	$self->{_features} = $options{selected_features};
	$self->{_cursor} = 0;
    } elsif ($self->{features}) {
    } else {
	if ( exists $self->{_filter} ) {
	    $self->{OGR}->{Layer}->SetSpatialFilter( $self->{_filter} );
	} else {
	    $self->{OGR}->{Layer}->SetSpatialFilter(undef);
	}
	$self->{OGR}->{Layer}->ResetReading();
    }
}

## @method next_feature()
#
# @brief Return a feature iteratively or undef if no more features. 
#
sub next_feature {
    my $self = shift;
    return $self unless $self->isa('Geo::Vector');
    if ($self->{features}) {
	my $f;
	while (1) {
	    (undef, $f) = each %{$self->{features}};
	    last unless $f;
	    last unless $self->{_filter};
	    last if $self->{_filter}->Intersect($f->Geometry);
	}
	return $f if $f;
	delete $self->{_filter};
	return;
    } elsif ($self->{_features}) {
	my $f;
	while (1) {
	    $f = undef;
	    last if $self->{_cursor} > $#{$self->{_features}};
	    $f = $self->{_features}->[$self->{_cursor}++];
	    last unless $self->{_filter};
	    last if $self->{_filter}->Intersect($f->Geometry);
	}
	return $f if $f;
	delete $self->{_cursor};
	delete $self->{_features};
	delete $self->{_filter};
	return;
    } else {
	my $f;
	while (1) {
	    $f = $self->{OGR}->{Layer}->GetNextFeature();
	    last unless $f;
	    last unless $self->{_filter};
	    # can't trust that all OGR drivers are good filterers
	    last if $self->{_filter}->Intersect($f->Geometry);
	}
	return $f if $f;
	delete $self->{_filter};
	$self->{OGR}->{Layer}->SetSpatialFilter(undef);
    }
}
*get_next = *next_feature;

## @method $add($other, %params)
#
# @brief Add a feature or features from another layer to this layer.
# @param other A feature or a feature layer object
# @param params Named parameters, used for creating the new object,
# if one is created, and for iterating through the features of other.
# @return (If used in non-void context) A new Geo::Vector object, which
# contain features from both this and from the other.
sub add {
    my $self = shift;
    my $other = shift;
    my %params = @_ if @_;
    if (defined wantarray) {
	$params{schema} = $self->schema();
	$self = Geo::Vector->new(%params);
    }
    my %dst_schema;
    my $dst_geometry_type;
    if ($self->{features}) {
	$dst_geometry_type = 'Unknown';
    } else {
	my $dst_defn = $self->{OGR}->{Layer}->GetLayerDefn();
	$dst_geometry_type = $dst_defn->GeometryType;
	$dst_geometry_type =~ s/25D$//;
	my $n = $dst_defn->GetFieldCount();
	for my $i ( 0 .. $n - 1 ) {
	    my $fd   = $dst_defn->GetFieldDefn($i);
	    $dst_schema{$fd->GetName} = $fd->GetType;
	}
    }
    init_iterate($other, %params);
    while (my $feature = next_feature($other)) {
	my $geom = $feature->Geometry();

	# check for match of geometry types
	next unless $dst_geometry_type eq 'Unknown' or 
	    $dst_geometry_type =~ /$geom->GeometryType/;

	my $f = $self->feature();
	for my $field ( @{$feature->Schema->{Fields}} ) {
	    my $name = $field->{Name};
	    unless ($self->{features}) {
		# copy only those attributes which match
		next unless exists($dst_schema{$name}) and $dst_schema{$name} eq $field->{Type};
	    }
	    $f->SetField($name, $feature->GetField($name));
	}
	if ($params{transformation}) {
	    my $points = $geom->Points;
	    transform_points($points, $params{transformation});
	    $geom->Points($points);
	}
	$f->Geometry($geom);
	$self->feature($f);
    }
    return $self if defined wantarray;
}

## @method Geo::Vector copy(%params)
#
# @brief Copy selected or all features from the layer into a new layer.
#
# @param[in] params is a list of named parameters. They are forwarded
# to constructor (new) and init_iterate. If no value is given the
# defaults are taken from this layer.
# @return A Geo::Vector object.
sub copy {
    my($self, %params) = @_;
    $params{data_source} = $self->{data_source} unless $params{data_source};
    $params{driver} = $self->driver unless $params{driver};
    $params{schema} = $self->schema unless $params{schema};
    my $copy = Geo::Vector->new(%params);
    my $fd = Geo::OGR::FeatureDefn->new();
    $fd->GeometryType($params{schema}{GeometryType}) if $params{schema}{GeometryType};
    if ($params{schema}{Fields}) {
	for my $f (@{$params{schema}{Fields}}) {
	    if (ref($f) eq 'HASH') {
		$f = Geo::OGR::FieldDefn->create(%$f);
	    }
	    $fd->AddFieldDefn($f);
	}
    }
    my $i = 0;
    $self->init_iterate(%params);
    while (my $f = $self->next_feature()) {
	
	my $geometry = $f->GetGeometryRef();

	# transformation if that is wished
	if ($params{transformation}) {
	    my $points = $geometry->Points;
	    transform_points($points, $params{transformation});
	    $geometry->Points($points);
	}
	
	# make copies of the features and add them to copy
	
	my $feature = Geo::OGR::Feature->new($fd);
	$feature->SetGeometry($geometry); # makes a copy
	
	for my $i (0..$fd->GetFieldCount-1) {
	    my $v = $f->GetField($i);
	    $v = decode($self->{encoding}, $v) if $v and $self->{encoding};
	    $feature->SetField($i, $v) if defined $v;
	}

	$copy->feature($feature);
	
    }
    $copy->{OGR}->{Layer}->SyncToDisk if $copy->{OGR};
    return $copy;
}

## @ignore
sub transform_points {
    my($points, $ct) = @_;
    unless (ref($points->[0])) { # single point [x,y,z]
	@$points = $ct->TransformPoint(@$points);
	return;
    }
    $ct->TransformPoints($points), return 
	unless ref($points->[0]->[0]); # list of points [[x,y,z],[x,y,z],...]

    # list of list of points [[[x,y,z],[x,y,z],...],...]
    for my $p (@$points) {
	transform_points($p, $ct);
    }
}

## @method $feature_count()
#
# @brief Count the number of features in the layer.
# @todo Add $force parameter.
# @return The number of features in the layer. The valued may be approximate.
sub feature_count {
    my($self) = @_;
    if ( $self->{features} ) {
	my $count = keys %{ $self->{features} };
	return $count;
    }
    return unless $self->{OGR}->{Layer};
    my $count;
    eval { $count = $self->{OGR}->{Layer}->GetFeatureCount(); };
    croak "GetFeatureCount failed: $@" if $@;
    return $count;
}

## @method Geo::OSR::SpatialReference srs(%params)
#
# @brief Get or set (set is not yet implemented) the spatial reference system of
# the layer.
#
# SRS (Spatial reference system) is a geographic coordinate system code number
# in the EPSG database (European Petroleum Survey Group, http://www.epsg.org/).
# Default value is 4326, which is for WGS84.
# @param[in] params (optional) Named parameters:
# - format => string. Name of the wanted return format, like 'Wkt'. Wkt is for 
# Well-known text and is defined by the The OpenGIS Consortium specification for 
# the exchange (and easy persistance) of geometry data in ASCII format.
# @return Returns the current spatial reference system of the layer
# as a Geo::OSR::SpatialReference or wkt string.
sub srs {
    my ( $self, %params ) = @_;
    return unless $self->{OGR}->{Layer};
    my $srs;
    eval { $srs = $self->{OGR}->{Layer}->GetSpatialRef(); };
    croak "GetSpatialRef failed: $@" if $@;
    return unless $srs;
    if ( $params{format} ) {
	return $srs->ExportToWkt if $params{format} eq 'Wkt';
    }
    return $srs;
}

## @method $geometry_type()
#
# @brief Return the geometry type of the layer.
#
# @return The geometry type as a string.
sub geometry_type {
    my($self) = @_;
    return 'Unknown' if $self->{features};
    my $t = $self->{OGR}->{Layer}->GetLayerDefn()->GeometryType;
}

## @method hashref schema(hashref schema)
#
# @brief Get or set the schema of the layer.
#
# Schema is a hash whose keyes are GeometryType, FID, and
# Fields. Fields is a reference to a list of field schemas. A field
# schema is a hash whose keys are Name, Type, Justify, Width, and
# Precision. This is similar to schemas in Geo::OGR.
#
# @param[in] schema (optional) a reference to a hash specifying the schema.
# @return the schema.
sub schema {
    my $self = shift;
    my $o;
    if ($self->{features}) {
    } else {
	$o = $self->{OGR}->{Layer};
    }
    if (@_ > 0) {
	my %schema = @_ == 1 ? %{$_[0]} : @_;
	$o->Schema(%schema);
    }
    if ($o) {
	my $s = $o->Schema();
	return bless $s, 'Gtk2::Ex::Geo::Schema';
    } else {
	return Gtk2::Ex::Geo::Schema->new;
    }
}

## @ignore
sub feature_attribute {
    my($self, $f, $a) = @_;
    if ($a =~ /^\./) { # pseudo fields
	if ($a eq '.FID') {
	    return $f->GetFID;
	} elsif ($a eq '.Z') {
	    my $g = $f->Geometry;
	    return $g->GeometryType =~ /^Point/ ? $g->GetZ : undef;
	} elsif ($a eq '.GeometryType') {
	    my $g = $f->Geometry;
	    return $g->GeometryType if $g;
	}
    } else {
	my $v = $f->GetField($a);
	$v = decode($self->{encoding}, $v) if $v and $self->{encoding};
	return $v;
    }
}

## @method @value_range(%params)
#
# @brief Returns a list of the value range of the field.
# @param[in] params Named parameters:
# - field_name => string. The attribute whose min and max values are looked up.
# - filter => reference to a Geo::OGR::Geometry (optional). Used by 
# Geo::OGR::SetSpatialFilter() if the layer is an OGR layer.
# - filter_rect => reference to an array defining the rect (min_x, min_y, max_x, 
# max_y) (optional). Used by the Geo::OGR::SetSpatialFilterRect() if the layer 
# is an OGR layer.
# @return An array that has as it's first value the ranges minimum and as second
# the maximum -- array(min, max).

## @method @value_range($field_name)
#
# @brief Returns a list of the value range of the field.
# @param[in] field_name The name of the field, whose min and max values are 
# looked up.
# @return An array that has as it's first value the ranges minimum and as second
# the maximum -- array(min, max).
sub value_range {
    my $self = shift;
    my $field_name;
    my %params;
    if ( @_ == 1 ) {
	$field_name = shift;
    }
    else {
	%params      = @_;
	$field_name = $params{field_name};
    }    
    
    if ($field_name eq '.Z') {
	my($zmin, $zmax);
	$self->init_iterate(%params);
	while (my $f = $self->next_feature()) {
	    ($zmin, $zmax) = z_range($f->Geometry()->Points, $zmin, $zmax);
	}
	return ($zmin, $zmax);
    }

    if ($self->{features}) {
	my $n = keys %{$self->{features}};
	return (0, $n) if $field_name eq '.FID';
    } else {
	my $schema = $self->schema()->field($field_name);
	croak "value_range: field with name '$field_name' does not exist"
	    unless defined $schema;
	croak
	    "value_range: can't use value from field '$field_name' since its' type is '$schema->{Type}'"
	    unless $schema->{Type} eq 'Integer'
	    or $schema->{Type}     eq 'Real';
	
	return ( 0, $self->{OGR}->{Layer}->GetFeatureCount - 1 )
	    if $field_name eq '.FID';
    }
    
    my @range;
    
    $self->init_iterate(%params);
    while (my $f = $self->next_feature()) {
	my $value = $f->GetField($field_name);
	$range[0] =
	    defined $range[0]
	    ? ( $range[0] < $value ? $range[0] : $value )
	    : $value;
	$range[1] =
	    defined $range[1]
		  ? ( $range[1] > $value ? $range[1] : $value )
		  : $value;
    }
    return @range;
}

## @ignore
sub z_range {
    my($points, $zmin, $zmax) = @_;
    unless (ref($points->[0])) { # single point [x,y,z]
	if (@$points > 2) {
	    $zmin = $points->[2] if (!defined($zmin) or $points->[2] < $zmin);
	    $zmax = $points->[2] if (!defined($zmax) or $points->[2] > $zmax);
	}
	return ($zmin, $zmax);
    }
    for my $p (@$points) {
	($zmin, $zmax) = z_range($p, $zmin, $zmax);
    }
    return ($zmin, $zmax);
}

## @method hashref feature($fid, $feature)
#
# @brief Get, add, update, or create a new feature.
#
# Example of retrieving:
# @code
# $feature = $layer->feature($fid);
# @endcode
#
# Example of updating:
# @code
# $layer->feature($fid, $feature);
# @endcode
#
# Example of adding:
# @code $layer->feature($feature);
# @endcode
#
# Example of creating a new feature (note: the feature is not added to the layer):
# @code $feature = $layer->feature();
# @endcode
#
# @param[in] fid The ID of the feature
# @param[in] feature A feature object to add or to update.
# @return a feature object
sub feature {
    my($self, $fid, $feature) = @_;
    if ($feature) {
	
	# update at fid
	if ( $self->{features} ) {
	    $feature = $self->make_feature($feature) unless 
		blessed($feature) and $feature->isa('Geo::Vector::Feature');
	    $self->{features}{$fid} = $feature;
	    $feature->{FID} = $fid;
	} else {
	    $feature = $self->make_feature($feature) unless 
		blessed($feature) and $feature->isa('Geo::OGR::Feature');
	    $feature->SetFID($fid);
	    $self->{OGR}->{Layer}->SetFeature($feature);
	}
	# selected_features is a layer method, this is a bug perhaps
	#my $features = $self->selected_features();
	#if (@$features) {
	#    my @fids;
	#    for (@$features) {push @fids, $_->GetFID}
	#    $self->select( with_id => \@fids );
	#}
    } elsif (ref $fid) {

	# add
	$feature = $fid;
	if ($self->{features}) {
	    $feature = $self->make_feature($feature) unless 
		blessed($feature) and $feature->isa('Geo::Vector::Feature');
	    $fid = 0;
	    while (exists $self->{features}{$fid}) {$fid++}
	    $self->{features}{$fid} = $feature;
	    $feature->{FID} = $fid;
	} else {
	    $feature = $self->make_feature($feature) unless 
		blessed($feature) and $feature->isa('Geo::OGR::Feature');
	    $self->{OGR}->{Layer}->CreateFeature($feature);
	}
    } elsif (defined $fid) {

	# retrieve
	if ( $self->{features} ) {
	    return $self->{features}{$fid} if exists $self->{features}{$fid};
	    return;
	} else {
	    return $self->{OGR}->{Layer}->GetFeature($fid);
	}
    } else {

	# create new
	if ( $self->{features} ) {
	    return Geo::Vector::Feature->new();	    
	} else {
	    return Geo::OGR::Feature->new($self->{OGR}->{Layer}->GetLayerDefn());
	}
    }
}

sub add_feature {
    my $self = shift;
    my %params = @_ == 1 ? %{$_[0]} : @_;
    feature($self, \%params);
}

## @method Geo::OGR::Geometry geometry($fid, $geometry)
# @brief Get, set or add a geometry.
# @param $fid (optional) The feature id, whose geometry to set or get.
# @param $geometry (optional) The geometry, which to set or add.
# @return A geometry object.
sub geometry {
    my($self, $fid, $geometry) = @_;
    if ($geometry) {
	# update at fid
	my $feature = $self->feature($fid);
	$feature->Geometry($geometry) if $feature;
    }
    elsif (ref $fid) {
	# add
	$geometry = $fid;
	my $feature = $self->make_feature(Geometry => $geometry);
	if ($self->{features}) {
	    $fid = 0;
	    while (exists $self->{features}{$fid}) {$fid++}
	    $self->{features}{$fid} = $feature;
	    $feature->{FID} = $fid;
	} else {
	    $self->{OGR}->{Layer}->CreateFeature($feature);
	    $self->{OGR}->{Layer}->SyncToDisk;
	}
    }
    else {
	# retrieve
	my $f;
	if ( $self->{features} ) {
	    $f = $self->{features}{$fid} if exists $self->{features}{$fid};
	} else {
	    $f = $self->{OGR}->{Layer}->GetFeature($fid);
	}
	return $f->Geometry->Clone if $f;
    }
}

sub geometries {
    my $self = shift;
    my @g = ();
    if ( $self->{features} ) {
	for my $fid (@_) {
	    my $f = $self->{features}{$fid} if exists $self->{features}{$fid};
	    push @g, $f->Geometry->Clone if $f;
	}
    } else {
	for my $fid (@_) {
	    my $f = $self->{OGR}->{Layer}->GetFeature($fid);
	    push @g, $f->Geometry->Clone if $f;
	}
    }
    return @g;
}

sub make_geometry {
    my($input) = @_;
    my $geometry;
    if (blessed($input)) {
	if ($input->isa('Geo::OGR::Geometry')) {
	    return $input->Clone;
	} else {
	    $geometry = Geo::OGR::CreateGeometryFromWkt( $input->AsText );
	}
    } else {
	$geometry = Geo::OGR::CreateGeometryFromWkt( $input );
    }
    return $geometry;
}

## @method Geo::OGR::Feature make_feature(%params)
#
# @brief Creates a feature object for this layer from argument data.
#
# @param[in] feature a hash whose keys are field names (Geometry is
# recognized as a field) and values are field values, or, for the
# geometry, a geometry object or well-known text.
# @return A feature object.
sub make_feature {
    my $self = shift;
    my %params;
    if (@_ == 1) {
	my $feature = shift;
	if ($self->{features}) {
	    return $feature if blessed($feature) and $feature->isa('Geo::Vector::Feature');
	} else {
	    return $feature if blessed($feature) and $feature->isa('Geo::OGR::Feature');
	}
	%params = %$feature;
    } else {
	%params = @_;
    }
    my $feature;
    $params{Geometry} = $params{geometry} if exists $params{geometry};
    my $geometry = make_geometry($params{Geometry});
    delete $params{Geometry};
    delete $params{geometry};
    if ($self->{features}) {
	$feature = Geo::Vector::Feature->new();
	for (keys %params) {
	    next if /^FID$/;
	    $feature->Field($_, $params{$_});
	}
    } else {
	my $defn = $self->{OGR}->{Layer}->GetLayerDefn();
	$defn->DISOWN; # feature owns
	$feature = Geo::OGR::Feature->new($defn);
	my $n = $defn->GetFieldCount();
	for my $i ( 0 .. $n - 1 ) {
	    my $fd   = $defn->GetFieldDefn($i);
	    my $name = $fd->GetName;
	    $feature->SetField( $name, $params{$name} );
	}
    }
    $feature->Geometry($geometry);
    return $feature;
}

## @method listref features(%params)
#
# @brief Returns features satisfying the given requirement.
# @param[in] params is a list named parameters
# - \a that_contain => an Geo::OGR::Geometry. The returned
# features are such that the geometry is within them. If the geometry
# is a multigeometry, then the features that have at least one of the
# geometries within.
# - \a that_are_within => an Geo::OGR::Geometry. The returned
# features are those that are within the geometry. If the geometry is
# a multigeometry, then the features are within at least one of the
# geometries.
# - \a that_intersect => Geo::OGR::Geometry object. The returned
# features are those that intersect with the geometry. If the geometry
# is a multigeometry, then the features intersect with at least one of
# the geometries.
# - \a filter
# - \a filter_rect
# - \a with_id => Reference to an array of feature indexes (fids).
# - \a from => If defined, the number of features that are skipped + 1.
# - \a limit => If defined, maximum number of features returned.
# @return A reference to an array of features.
sub features {
    my($self, %params) = @_;
    my @features;
    my $i = 0;
    my $from = $params{from} || 1;
    my $limit = 0;
    $limit = $from + $params{limit} if exists $params{limit};
    my $is_all = 1;

    if ( exists $params{with_id} ) {

	for my $fid (@{$params{with_id}}) {
	    my $x;
	    if ($self->{features}) {
		$x = $self->{features}{$fid} if exists $self->{features}{$fid};
	    } else {
		$x = $self->{OGR}->{Layer}->GetFeature($fid);
	    }
	    next unless $x;
	    $i++;
	    next if $i < $from;
	    push @features, $x;
	    $is_all = 0, last if $limit and $i >= $limit-1;
	}

    } else {

	if ( exists $params{that_contain} ) 
	{
	    $self->init_iterate( filter => $params{that_contain} );
	    while ( my $f = $self->next_feature() ) {
		$i++;
		next if $i < $from;
		next unless $f->GetGeometry->Contains($params{that_contain});
		push @features, $f;
		$is_all = 0, last if $limit and $i >= $limit-1;
	    }
	}
	elsif ( exists $params{that_are_within} ) 
	{
	    $self->init_iterate( filter => $params{that_are_within} );
	    while ( my $f = $self->next_feature() ) {
		$i++;
		next if $i < $from;
		next unless $f->GetGeometry->Within($params{that_are_within});
		push @features, $f;
		$is_all = 0, last if $limit and $i >= $limit-1;
	    }
	}
	elsif ( exists $params{that_intersect} ) 
	{
	    $self->init_iterate( filter => $params{that_intersect} );
	    while ( my $f = $self->next_feature() ) {
		$i++;
		next if $i < $from;
		next unless $f->GetGeometry->Intersect($params{that_intersect});
		push @features, $f;
		$is_all = 0, last if $limit and $i >= $limit-1;
	    }
	}
	else {
	    my %options = %params;
	    $options{filter_rect} = $params{filter_with_rect} if $params{filter_with_rect};
	    $self->init_iterate(%options);
	    while ( my $f = $self->next_feature() ) {
		$i++;
		next if $i < $from;
		push @features, $f;
		$is_all = 0, last if $limit and $i >= $limit-1;
	    }
	}
    }
    return wantarray ? (\@features, $is_all) : \@features;
}

## @method @world($FID)
#
# @brief Get the bounding box (xmin, ymin, xmax, ymax) of the layer or some of
# its features.
#
# @param[in] FID ID or IDs of the features to take into account.
# @return Returns the bounding box (minX, minY, maxX, maxY) as an array.
sub world {
    my $self = shift;
    my %fids;
    if (@_ == 1) {
	my $ref = shift;
	if (ref $ref eq 'ARRAY') {
	    %fids = map {$_ => 1} @$ref;
	} else {
	    %fids = %$ref;
	}
    } elsif (@_ > 1) {
	%fids = map {$_ => 1} @_;
    }
    my $extent;
    if (%fids) {
	for my $fid (keys %fids) {
	    my $e = $self->feature($fid)->Geometry->GetEnvelope();
	    unless ($extent) {
		@$extent = @$e;
	    }
	    else {
		$extent->[0] = MIN( $extent->[0], $e->[0] );
		$extent->[2] = MIN( $extent->[2], $e->[2] );
		$extent->[1] = MAX( $extent->[1], $e->[1] );
		$extent->[3] = MAX( $extent->[3], $e->[3] );
	    }
	}
    } elsif ($self->{features}) {
	for my $feature(values %{$self->{features}}) {
	    my $e = $feature->Geometry->GetEnvelope();
	    unless ($extent) {
		@$extent = @$e;
	    }
	    else {
		$extent->[0] = MIN( $extent->[0], $e->[0] );
		$extent->[2] = MIN( $extent->[2], $e->[2] );
		$extent->[1] = MAX( $extent->[1], $e->[1] );
		$extent->[3] = MAX( $extent->[3], $e->[3] );
	    }
	}
    } elsif ($self->{OGR}->{Layer}->GetFeatureCount() > 0) {
	eval { $extent = $self->{OGR}->{Layer}->GetExtent(); };
	croak "GetExtent failed: $@" if $@;
    }
    
    return unless $extent;
    $extent->[1] = $extent->[0] + 1 if $extent->[1] <= $extent->[0];
    $extent->[3] = $extent->[2] + 1 if $extent->[3] <= $extent->[2];
    return ( $extent->[0], $extent->[2], $extent->[1], $extent->[3] );
}

## @method Geo::Raster rasterize(%params)
#
# @brief Creates a new Geo::Raster from this Geo::Vector object.
#
# The new Geo::Raster has the size and extent of the Geo::Raster $this and draws
# the layer on it. The raster is boolean integer raster unless value_field is
# given. If value_field is floating point value, the returned raster is a
# floating point raster. render_as hash is optional, but if given should be one of
# 'Native', 'Points', 'Lines', or 'Polygons'. $fid (optional) is the number of
# the feature to render.
#
# @param[in] params is a list of named parameters: 
# - \a like (optional). A Geo::Raster object, from which the resulting
# Geo::Raster object's size and extent are copied.
# - \a M (optional). Height of the resulting Geo::Raster object. Has to be
# given if hash like is not given. If like is given, then M will not be used.
# - \a N (optional). Width of the resulting Geo::Raster object. Has to be
# given if hash like is not given. If like is given, then N will not be used.
# - \a world (optional). The world (bounding box) of the resulting raster
# layer. Useless to give if parameter like is given, because then it's world
# will be used.
# - \a render_as (optional). Rendering mode, which should be 'Native',
# 'Points', 'Lines' or 'Polygons'.
# - \a feature (optional). Number of the feature to render.
# - \a value_field (optional). Value fields name.
# - \a nodata_value (optional). What value to use for nodata. Default
# is -9999 and to initialize the raster to nodata. Set to undef to not
# to use nodata values at all (and initialize to zero).
# @return A new Geo::Raster, which has the size and extent of the given as
# @todo make this work for schema free layers
# parameters and values
sub rasterize {
    my $self = shift;
    my %params;
    
    %params = @_ if @_;
    
    my %defaults = (
		    render_as => $self->{RENDER_AS} ? $self->{RENDER_AS} : 'Native',
		    feature => -1,
		    nodata_value => -9999,
		    datatype     => 'Integer'
		    );

    for ( keys %defaults ) {
	$params{$_} = $defaults{$_} unless exists $params{$_};
    }
    
    croak "Not a valid rendering mode: $params{render_as}" unless defined $RENDER_AS{$params{render_as}};
    
    croak "Geo::Vector->rasterize: only OGR layers can be currently rasterized" 
	unless $self->{OGR}->{Layer};
    my $handle = OGRLayerH( $self->{OGR}->{Layer} );
    
    ( $params{M}, $params{N} ) = $params{like}->size(of_GDAL=>1) if $params{like};
    $params{world} = [ $params{like}->world() ] if $params{like};
    
    croak "Geo::Vector->rasterize needs the raster size: M, N"
	unless $params{M} and $params{N};
    
    $params{world} = [ $self->world() ] unless $params{world};
    
    my $field = -1;
    if ( defined $params{value_field} and $params{value_field} ne '' ) {
	my $schema = $self->schema()->field($params{value_field});
	croak "rasterize: field with name '$params{value_field}' does not exist"
	    unless defined $schema;
		croak
		    "rasterize: can't use value from field ".
		    "'$params{value_field}' since its' type is '$schema->{Type}'"
		    unless $schema->{Type} eq 'Integer'
		    or $schema->{Type}     eq 'Real';
	$params{datatype} = $schema->{Type};
	$field = $schema->{Index};
    }
    
    my $gd = Geo::Raster->new(
			      datatype => $params{datatype},
			      M        => $params{M},
			      N        => $params{N},
			      world    => $params{world}
			      );
    if (defined($params{nodata_value})) {
	$gd->nodata_value( $params{nodata_value} );
	$gd->set('nodata');
    }
    
    xs_rasterize( $handle, $gd->{GRID},
		  $RENDER_AS{ $params{render_as} },
		  $params{feature}, $field );
    
    return $gd;
}

sub MIN {
    $_[0] > $_[1] ? $_[1] : $_[0];
}

sub MAX {
    $_[0] > $_[1] ? $_[0] : $_[1];
}

1;
__END__

=pod

=head1 SEE ALSO

Geo::GDAL

This module should be discussed in geo-perl@list.hut.fi.

The homepage of this module is http://libral.sf.net.

=head1 AUTHOR

Ari Jolma, E<lt>ari.jolma at tkk.fiE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by Ari Jolma

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
