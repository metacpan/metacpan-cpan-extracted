package Geo::Vector::Layer;
# @brief A subclass of Gtk2::Ex::Geo::Layer

=pod

=head1 NAME

Geo::Vector::Layer - A geospatial vector layer class for Gtk2::Ex::Geo

=cut

use strict;
use warnings;
use Scalar::Util qw(blessed);
use POSIX;
POSIX::setlocale( &POSIX::LC_NUMERIC, "C" ); # http://www.remotesensing.org/gdal/faq.html nr. 11
use Carp;
use Encode;
use File::Spec;
use Glib qw/TRUE FALSE/;
use Gtk2;
use Gtk2::Ex::Geo::Layer qw/:all/;
use Geo::OGC::Geometry;
use Geo::Raster::Layer qw /:all/;
use Geo::Vector::Layer::Dialogs;
use Geo::Vector::Layer::Dialogs::New;
use Geo::Vector::Layer::Dialogs::Copy;
use Geo::Vector::Layer::Dialogs::Open;
use Geo::Vector::Layer::Dialogs::Rasterize;
use Geo::Vector::Layer::Dialogs::Vertices;
use Geo::Vector::Layer::Dialogs::Features;
use Geo::Vector::Layer::Dialogs::FeatureCollection;
use Geo::Vector::Layer::Dialogs::Properties;

BEGIN {
    if ($^O eq 'MSWin32') {
	require Win32::OLE;
	import Win32::OLE qw(in);
    }
}

use vars qw/%RENDER_AS2INDEX %INDEX2RENDER_AS $BORDER_COLOR/;

require Exporter;
our @ISA = qw(Exporter Geo::Vector Gtk2::Ex::Geo::Layer);
our @EXPORT = qw();
our %EXPORT_TAGS = ( 'all' => [ qw(%RENDER_AS2INDEX %INDEX2RENDER_AS $BORDER_COLOR) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION = 0.03;

%RENDER_AS2INDEX = (Native => 0, Points => 1, Lines => 2, Polygons => 3);
for (keys %RENDER_AS2INDEX) {
    $INDEX2RENDER_AS{$RENDER_AS2INDEX{$_}} = $_;
}

# default values for new objects:

$BORDER_COLOR = [255, 255, 255];

## @ignore
sub registration {
    my $dialogs = Geo::Vector::Layer::Dialogs->new();
    my $commands = [
	tag => 'vector',
	label => 'Vector',
	tip => 'Create new or open a vector dataset.',
	{
	    label => 'New...',
	    tip => 'Create a new vector layer.',
	    sub => sub {
		my(undef, $gui) = @_;
		Geo::Vector::Layer::Dialogs::New::open($gui);
	    }
	},
	{
	    label => 'Open...',
	    tip => 'Add a new vector layer from a data source.',
	    sub => sub {
		my(undef, $gui) = @_;
		$gui->{history}->enter(''); # open_vector dialog uses the same history
		Geo::Vector::Layer::Dialogs::Open::open($gui);
	    }
	}
	];
    return { dialogs => $dialogs, commands => $commands };
}

## @cmethod $upgrade($object)
#
# @brief Upgrade Geo::Vector, feature and geometry objects to Geo::Vector::Layers
sub upgrade {
    my($object) = @_;
    return 0 unless blessed($object);
    if ($object->isa('Geo::Vector') and !$object->isa('Geo::Vector::Layer')) {
	bless($object, 'Geo::Vector::Layer');
	$object->defaults();
	return 1;
    } elsif ($object->isa('Geo::OGR::Feature') or $object->isa('Geo::Vector::Feature')) {
	my $layer = Geo::Vector->new(features => [$object]);
	bless($layer, 'Geo::Vector::Layer');
	$layer->defaults();
	return $layer;
    } elsif ($object->isa('Geo::OGR::Geometry')) {
	my $layer = Geo::Vector->new(geometries => [$object]);
	bless($layer, 'Geo::Vector::Layer');
	$layer->defaults();
	return $layer;
    }
    return 0;
}

## @ignore
sub new {
    my($package, %params) = @_;
    my $self = Geo::Vector::new($package, %params);
    Gtk2::Ex::Geo::Layer::new($package, self => $self, %params);
    return $self;
}

## @ignore
sub DESTROY {
}

## @ignore
sub defaults {
    my($self, %params) = @_;
    # these can still be overridden with params:
    $self->name($self->{OGR}->{Layer}->GetName()) if $self->{OGR}->{Layer};
    my $gt = $self->geometry_type;
    @{$self->{BORDER_COLOR}} = @$BORDER_COLOR if $gt and $gt =~ /Polygon/;    
    $self->{RENDER_AS} = 'Native' unless exists $self->{RENDER_AS};
    $self->{RENDER_AS} = $params{render_as} if exists $params{render_as};
    $self->{LINE_WIDTH} = 1;
    # set inherited from params:
    $self->SUPER::defaults(%params);
}

## @method $type()
#
# @brief Returns the type of the layer.
# @return A string ('V'== vector layer, 'Coll' == feature collection
# layer, 'OGR'== ogr layer, 'U' == updateable layer) representing the
# type of the layer.
sub type {
    my($self, $format) = @_;
    my $type;
    if ( $self->{features} ) {
	$type = ($format and $format eq 'long') ? 'Feature collection' : 'FC';
    } else {
	$type = ($format and $format eq 'long') ? 'OGR layer' : 'OGR';
	$type .= ($format and $format eq 'long') ? ', updateable' : ' U' if $self->{update};
    }
    return $type;
}

## @ignore
# convert the values of the params hash from OGC to OGR
sub features {
    my($self, %params) = @_;
    my %new_params;
    for my $key (keys %params) {
	if (blessed($params{$key}) and $params{$key}->isa('Geo::OGC::Geometry')) {
	    $new_params{$key} = Geo::OGR::CreateGeometryFromWkt($params{$key}->AsText);
	} else {
	    $new_params{$key} = $params{$key};
	}
    }
    return Geo::Vector::features($self, %new_params);
}

## @method void properties_dialog($gui)
#
# @brief If the layer is an ogr layer then the method opens trough the given GUI
# a dialog with layer's properties.
#
# The method calls for example the Gtk2::Ex::Geo::OGRDialog of the
# Gtk2::Ex::Geo::Glue.
# @param[in] gui A reference to a GUI object, like for example Gtk2::Ex::Geo::Glue.
# @todo Support for feature layer.
sub open_properties_dialog {
    my($self, $gui) = @_;
    Geo::Vector::Layer::Dialogs::Properties::open($self, $gui);
}

## @ignore
sub menu_items {
    my($self) = @_;
    my @items;
    if ( $self->{features} ) {
	push @items, ( 
	    '_Features...' => sub {
		my($self, $gui) = @{$_[1]};
		Geo::Vector::Layer::Dialogs::FeatureCollection::open($self, $gui);
	    });	
    } elsif ( $self->{OGR}->{Layer} ) {
	push @items, ( 
	    'C_opy...' => sub {
		my($self, $gui) = @{$_[1]};
		Geo::Vector::Layer::Dialogs::Copy::open($self, $gui);
	    },
	    '_Features...' => sub {
		my($self, $gui) = @{$_[1]};
		Geo::Vector::Layer::Dialogs::Features::open($self, $gui);
	    },
	    '_Vertices...' => sub {
		open_vertices_dialog(@{$_[1]});
	    },
	    'R_asterize...' => sub {
		my($self, $gui) = @{$_[1]};
		Geo::Vector::Layer::Dialogs::Rasterize::open($self, $gui);
	    } );
    }
    push @items, ( 1 => 0 );
    push @items, $self->SUPER::menu_items();
    return @items;
}

## @ignore
sub open_features_dialog {
    my($self) = @_;
    if ( $self->{features} ) {
	Geo::Vector::Layer::Dialogs::FeatureCollection::open(@_);
    }
    elsif ( $self->{OGR}->{Layer} ) {
	Geo::Vector::Layer::Dialogs::Features::open(@_);
    }
}

## @ignore
sub open_vertices_dialog {
    Geo::Vector::Layer::Dialogs::Vertices::open(@_);
}

## @ignore
sub open_rasterize_dialog {
}

## @method $render_as($render_as)
#
# @brief Get or set the rendering mode.
# @param[in] render_as (optional) Mode of how to render the layers vector data.
# Has to be one of the modes given by render_as_modes().
# @return The current rendering mode as a string.
sub render_as {
    my($self, $render_as) = @_;
    if (defined $render_as) {
	croak "Unknown rendering mode: $render_as"
	    unless defined $Geo::Vector::RENDER_AS{$render_as};
	$self->{RENDER_AS} = $render_as;
    } else {
	return $self->{RENDER_AS};
    }
}

## @method @supported_palette_types()
#
# @brief Returns a list of supported palette types.
# @return A list (strings) of supported palette types.
sub supported_palette_types {
    my($self)  = @_;
    my $schema  = $self->schema;
    my $has_int = 0;
    for my $field ( $schema->fields ) {
	$has_int = 1, next if $field->{Type} eq 'Integer';
    }
    if ($has_int) {
	return (
	    'Single color',
	    'Grayscale',
	    'Rainbow',
	    'Color table',
	    'Color bins'
	    );
    }
    else {
	return ( 'Single color', 'Grayscale', 'Rainbow', 'Color bins' );
    }
}

## @method @supported_symbol_types()
#
# @brief Returns a list of supported symbol types.
# @return A list (strings) of supported symbol types.
sub supported_symbol_types {
    my($self) = @_;
    
    # symbol if rendered as points or as a point (centroid of a polygon)
    return ( 'No symbol', 'Square', 'Dot', 'Cross', 'Wind rose' );
    my $t = $self->geometry_type;
    if ( $t =~ /Point/ ) {
	return ( 'Square', 'Dot', 'Cross' );
    }
    elsif ( $t =~ /Polygon/ ) {
	return ( 'No symbol', 'Square', 'Dot', 'Cross' );
    }
    else {
	return ();
    }
}

## @ignore
sub ohoh {
    for my $x (@_) {
	return $x if defined $x;
    }
}

## @ignore
sub has_features_with_borders {
    my($self) = @_;
    my $gt = $self->geometry_type;
    return 1 unless $gt =~ /Point/ or $gt =~ /LineString/;
    return 0;
}

## @method void render($pb)
#
# @brief Renders the vector layer onto a memory image.
#
# @param[in,out] pb Pixel buffer into which the vector layer is rendered.
# @note The layer has to be visible while using the method!
sub render {
    my($self, $pb, $cr, $overlay, $viewport) = @_;
    return if !$self->visible();
    
    $self->{PALETTE_VALUE} = $PALETTE_TYPE{$self->{PALETTE_TYPE}};
    $self->{SYMBOL_VALUE} = $SYMBOL_TYPE{$self->{SYMBOL_TYPE}};
    if ($self->{SYMBOL_FIELD} eq 'Fixed size') {
		$self->{SYMBOL_SCALE_MIN} = 0; # similar to grayscale scale
		$self->{SYMBOL_SCALE_MAX} = 0;
    }
    my $schema = $self->schema();
    $self->{COLOR_FIELD_VALUE} = ohoh(Geo::Vector::field_index($self->{COLOR_FIELD}),
				      $schema->field_index($self->{COLOR_FIELD}),
				      Geo::Vector::undefined_field_index());
    $self->{SYMBOL_FIELD_VALUE} = ohoh(Geo::Vector::field_index($self->{SYMBOL_FIELD}),
				       $schema->field_index($self->{SYMBOL_FIELD}),
				       Geo::Vector::undefined_field_index());
    
    $self->{RENDER_AS}       = 'Native' unless defined $self->{RENDER_AS};
    $self->{RENDER_AS_VALUE} = $Geo::Vector::RENDER_AS{ $self->{RENDER_AS} };
    my @border;
    if ( @{$self->{BORDER_COLOR}} and 
	 ($self->{RENDER_AS} eq 'Native' or $self->{RENDER_AS} eq 'Polygons')) {
	@border = @{$self->{BORDER_COLOR}};
	push @border, 255;
    }
    
    if ($self->{features}) {
	for my $feature (values %{$self->{features}}) {
	    $self->render_feature($overlay, $cr, $feature);
	}
    } else {
	my $handle = Geo::Vector::OGRLayerH($self->{OGR}->{Layer});
        if ( not $self->{RENDERER} ) {	    
            my $layer = Geo::Vector::ral_visual_layer_create($self, $handle);
            if ($layer) {
                Geo::Vector::ral_visual_layer_render( $layer, $pb ) if $pb;
                Geo::Vector::ral_visual_layer_destroy($layer);
            }
        }
	if (@border) {
	    my $border = Geo::Vector::Layer->new( alpha => $self->{ALPHA}, single_color => \@border );
	    $border->{RENDER_AS_VALUE} = $Geo::Vector::RENDER_AS{Lines};
	    my $layer = Geo::Vector::ral_visual_layer_create($border, $handle);
	    if ($layer) {
		Geo::Vector::ral_visual_layer_render( $layer, $pb ) if $pb;
		Geo::Vector::ral_visual_layer_destroy($layer);
	    }
	}
	$self->render_labels($cr, $overlay, $viewport);
    }
}

sub render_labels {
    my($self, $cr, $overlay, $viewport) = @_;
    my $labeling = $self->labeling;
    return unless $labeling->{field} ne 'No Labels';

    my @label_color = @{$labeling->{color}};
    $label_color[3] = int($self->{ALPHA}*$label_color[3]/255);
    for (@label_color) {
	$_ /= 255;
    }
    
    my $wc = -0.5;
    my $hc = -0.5;
    my $dw = 0;
    for ($labeling->{placement}) {
	$hc = -1 - $self->{LABEL_VERT_NUDGE} if /Top/;
	$hc = $self->{LABEL_VERT_NUDGE} if /Bottom/;
	if (/left/) {$wc = -1; $dw = -1*$self->{LABEL_HORIZ_NUDGE_LEFT}};
	if (/right/) {$wc = 0; $dw = $self->{LABEL_HORIZ_NUDGE_RIGHT}};
    }
    my $font_desc = Gtk2::Pango::FontDescription->from_string($labeling->{font});
    
    $self->{OGR}->{Layer}->SetSpatialFilterRect(@$viewport);
    $self->{OGR}->{Layer}->ResetReading();
    
    my %geohash;
    my $f;
    
    # later this should be as in libral, color may be a function
    my @color = @{$self->{SINGLE_COLOR}};
    $label_color[3] = int($self->{ALPHA}*$color[3]/255);
    for (@color) {
	$_ /= 255;
    }
    
    while ($f = $self->{OGR}->{Layer}->GetNextFeature()) {
	
	my $geometry = $f->GetGeometryRef();
	
	my @placements = label_placement($geometry, $overlay->{pixel_size}, @$viewport, $f->GetFID);
	
	for (@placements) {
	    
	    my ($size, @point) = @$_;
	    
	    last unless (@point and defined($point[0]) and defined($point[1]));
	    
	    next if ($labeling->{min_size} > 0 and $size < $labeling->{min_size});
	    
	    next if 
		$point[0] < $viewport->[0] or 
		$point[0] > $viewport->[2] or
		$point[1] < $viewport->[1] or
		$point[1] > $viewport->[3];
	    
	    my @pixel = $overlay->point2pixmap_pixel(@point);
	    if ($self->{INCREMENTAL_LABELS}) {
		# this is fast but not very good
		my $geokey = int($pixel[0]/120) .'-'. int($pixel[1]/50);
		next if $geohash{$geokey};
		$geohash{$geokey} = 1;
	    }
	    
	    if ($self->{RENDERER} eq 'Cairo') {
		my $points = $geometry->Points;
		# now only for points
		my @p = $overlay->point2pixmap_pixel(@{$points->[0]});
		my $d = $self->{SYMBOL_SIZE}/2;
		$cr->move_to($p[0]-$d, $p[1]);
		$cr->line_to($p[0]+$d, $p[1]);
		$cr->move_to($p[0], $p[1]-$d);
		$cr->line_to($p[0], $p[1]+$d);
		$cr->set_line_width($self->{LINE_WIDTH});
		$cr->set_source_rgba(@color);
		$cr->stroke();
	    }
	    
	    my $str = Geo::Vector::feature_attribute($self, $f, $labeling->{field});
	    next unless defined $str or $str eq '';
	    
	    my $layout = Gtk2::Pango::Cairo::create_layout($cr);
	    $layout->set_font_description($font_desc);    
	    $layout->set_text($str);
	    my($width, $height) = $layout->get_pixel_size;
	    $cr->move_to($pixel[0]+$wc*$width+$dw, $pixel[1]+$hc*$height);
	    $cr->set_source_rgba(@label_color);
	    Gtk2::Pango::Cairo::show_layout($cr, $layout);
	    
	}
	
    }
}

sub render_feature {
    my($self, $overlay, $cr, $feature, $geometry) = @_;
    $geometry = $feature->Geometry unless $geometry;
    my $t = $geometry->GeometryType;
    my $a = $self->alpha/255.0;
    my @color = $self->single_color;
    for (@color) {
	$_ /= 255.0;
	$_ *= $a;
    }
    if ($t =~ /^Point/) {
	render_point($overlay, $cr, $geometry, \@color);
    } elsif ($t =~ /^Line/) {
	render_linestring($overlay, $cr, $geometry, 1, \@color);
    } elsif ($t =~ /^Poly/) {
	my @border = $self->border_color;
	@border = (0,0,0) unless @border;
	for (@border) {
	    $_ /= 255.0;
	    $_ *= $a;
	}
	push @border, $color[3];
	render_polygon($overlay, $cr, $geometry, 1, \@border, \@color);
    } elsif ($geometry->GetGeometryCount > 0) {
	for my $i (0..$geometry->GetGeometryCount-1) {
	    render_feature($self, $overlay, $cr, $feature, $geometry->GetGeometryRef($i));
	}
    }
}

sub render_polygon {
    my($overlay, $cr, $geometry, $line_width, $border, $fill) = @_;
    paths($overlay, $cr, $geometry->Points);
    $cr->set_line_width($line_width);
    $cr->set_source_rgba(@$fill);
    $cr->set_fill_rule('even-odd');
    $cr->fill_preserve;
    $cr->set_source_rgba(@$border);
    $cr->stroke;
}

sub render_linestring {
    my($overlay, $cr, $geometry, $line_width, $color) = @_;
    $cr->set_line_width($line_width);
    $cr->set_source_rgba(@$color);
    geometry_path($overlay, $cr, $geometry);
    $cr->stroke;
}

sub render_point {
    my($overlay, $cr, $geometry, $color) = @_;
    $cr->set_line_width(1);
    $cr->set_source_rgba(@$color);
    my @p = $overlay->point2surface($geometry->GetPoint);
    for (@p) {
	$_ = bounds($_, -10000, 10000);
    }
    $p[0] -= 3;
    $cr->move_to(@p);
    $p[0] += 6;
    $cr->line_to(@p);
    $p[0] -= 3;
    $p[1] -= 3;
    $cr->move_to(@p);
    $p[1] += 6;
    $cr->line_to(@p);
    $cr->stroke;
}

sub geometry_path {
    my($overlay, $cr, $geometry) = @_;
    if ($geometry->GetGeometryCount > 0) {
	for my $i (0..$geometry->GetGeometryCount-1) {
	    geometry_path($overlay, $cr, $geometry->GetGeometryRef($i));
	}
    } else {
	path($overlay, $cr, $geometry->Points);
    }
}

sub paths {
    my($overlay, $cr, $points) = @_;
    if (ref $points->[0]->[0]) {
	for my $i (0..$#$points) {
	    paths($overlay, $cr, $points->[$i]);
	}
    } else {
	path($overlay, $cr, $points);
    }
}

sub path {
    my($overlay, $cr, $points) = @_;
    my @p = $overlay->point2surface(@{$points->[0]});
    for (@p) {
	$_ = bounds($_, -10000, 10000);
    }
    $cr->move_to(@p);
    for my $i (1..$#$points) {
	@p = $overlay->point2surface(@{$points->[$i]});
	for (@p) {
	    $_ = bounds($_, -10000, 10000);
	}
	$cr->line_to(@p);
    }
}

sub bounds {
    $_[0] < $_[1] ? $_[1] : ($_[0] > $_[2] ? $_[2] : $_[0]);
}

##@ignore
sub piece_of_line_string {
    my($geom, $i0, $minx, $miny, $maxx, $maxy) = @_;
    my($x, $y);
    while(1) {
	$x = $geom->GetX($i0);
	$y = $geom->GetY($i0);
	last if $x >= $minx and $y >= $miny and $x <= $maxx and $y <= $maxy;
	$i0++;
	return if $i0 >= $geom->GetPointCount-1;
    }
    my $l = 0;
    my $i1 = $i0+1;
    my $x0 = $x;
    my $y0 = $y;
    while (1) {
	$x = $geom->GetX($i1);
	$y = $geom->GetY($i1);
	$l += sqrt(($x0-$x)*($x0-$x)+($y0-$y)*($y0-$y));
	last if $x < $minx or $y < $miny or $x > $maxx or $y > $maxy;
	$i1++;
	last if $i1 >= $geom->GetPointCount;
	$x0 = $x;
	$y0 = $y;
    }
    return ($i0, $i1, $l);
}

##@ignore
sub label_placement {
    my($geom, $scale, $minx, $miny, $maxx, $maxy, $fid) = @_;
    my $type = $geom->GetGeometryType & ~0x80000000;
    if ($type == $Geo::OGR::wkbPoint) {
	return ([0, $geom->GetX(0), $geom->GetY(0)]);
    } 
    elsif ($type == $Geo::OGR::wkbLineString) {

	my $i0 = 0;
	my $i1;
	my $len;
	my @placements;
	while (1) {
	    ($i0, $i1, $len) = piece_of_line_string($geom, $i0, $minx, $miny, $maxx, $maxy);
	    last unless defined $i0;
	    # a label between i0 and i1

	    my $h = $len/2;
	    my $x0 = $geom->GetX($i0);
	    my $y0 = $geom->GetY($i0);
	    if ($len == 0 or $scale == 0) {
		push @placements, [0, $x0, $y0];
	    } 
	    else {
		for ($i0+1..$i1) {
		    my $x1 = $geom->GetX($_);
		    my $y1 = $geom->GetY($_);
		    my $l = sqrt(($x1-$x0)*($x1-$x0)+($y1-$y0)*($y1-$y0));
		    if ($h > $l) {
			$h -= $l;
		    } else {
			$x0 += $l == 0 ? 0 : ($x1-$x0)*$h/$l;
			$y0 += $l == 0 ? 0 : ($y1-$y0)*$h/$l;
		       
			push @placements, [$len/$scale, $x0, $y0];
			last;
		    }
		    $x0 = $x1;
		    $y0 = $y1;
		}
	    }

	    last if $i1 >= $geom->GetPointCount;
	    $i0 = $i1;
	}
	return @placements;
	
    } 
    elsif ($type == $Geo::OGR::wkbPolygon) {
	my $c = $geom->Centroid;
	return ([$geom->GetArea/($scale*$scale), $c->GetX, $c->GetY]);
    } 
    elsif ($type == $Geo::OGR::wkbMultiLineString or $type == $Geo::OGR::wkbMultiLineString25D) {
	my $len = 0;
	my $longest = -1;
	for my $i (0..$geom->GetGeometryCount()-1) {
	    my $a = line_string_length($geom->GetGeometryRef($i));
	    if ($a > $len) {
		$len = $a;
		$longest = $i;
	    }
	}
	return label_placement($geom->GetGeometryRef($longest), $scale) if $longest >= 0;
    } 
    elsif ($type == $Geo::OGR::wkbMultiPolygon or $type == $Geo::OGR::wkbGeometryCollection) {
	my $size = 0;
	my $largest = -1;
	for my $i (0..$geom->GetGeometryCount()-1) {
	    my $a = $geom->GetGeometryRef($i)->GetArea;
	    if ($a > $size) {
		$size = $a;
		$largest = $i;
	    }
	}
	return label_placement($geom->GetGeometryRef($largest), $scale) if $largest >= 0;
    } else {
	my $t = Geo::OGR::Geometry::TYPE_INT2STRING{$type};
	print STDERR "label placement not defined for geometry type $t\n";
	return ();
    }
    print STDERR "couldn't compute label placement\n";
    return ();
}

##@ignore
sub line_string_length {
    my $line = shift;
    my $l = 0;
    my $x0 = $line->GetX(0);
    my $y0 = $line->GetY(0);
    for (1..$line->GetPointCount-1) {
	my $x1 = $line->GetX($_);
	my $y1 = $line->GetY($_);
	$l += sqrt(($x1-$x0)*($x1-$x0)+($y1-$y0)*($y1-$y0));
	$x0 = $x1;
	$y0 = $y1;
    }
    return $l;
}

## @ignore
sub render_selection {
    my($self, $gc, $overlay) = @_;

    my $features = $self->selected_features();
    
    for my $f (@$features) {
	
	next unless $f; # should not happen
	
	my $geom = $f->GetGeometryRef();
	next unless $geom;
	
	# this could be a bit faster without conversion
	$overlay->render_geometry($gc, Geo::OGC::Geometry->new(Text => $geom->ExportToWkt));
	
    }
}

# this piece should probably go into GDAL:
package Geo::OGR::Driver;

use vars qw /%FormatNames/;

%FormatNames = (
    'AVCBin' => 'Arc/Info Binary Coverage',
    'AVCE00' => 'Arc/Info .E00 (ASCII) Coverage',
    'BNA' => 'Atlas BNA',
    'DXF' => 'AutoCAD DXF',
    'CSV' => 'Comma Separated Value (.csv)',
    'DODS' => 'DODS/OPeNDAP',
    'PGeo' => 'ESRI Personal GeoDatabase',
    'SDE' => 'ESRI ArcSDE',
    'ESRI Shapefile' => 'ESRI Shapefile',
    'FMEObjects Gateway' => 'FMEObjects Gateway',
    'GeoJSON' => 'GeoJSON',
    'Geoconcept' => 'Geoconcept Export',
    'GeoRSS' => 'GeoRSS',
    'GML' => 'GML',
    'GMT' => 'GMT',
    'GPX' => 'GPX',
    'GRASS' => 'GRASS',
    'GPSTrackMaker' => 'GPSTrackMaker (.gtm, .gtz)',
    'IDB' => 'Informix DataBlade',
    'Interlis 1' => 'INTERLIS',
    'Interlis 2' => 'INTERLIS',
    'INGRES' => 'INGRES',
    'KML' => 'KML',
    'MapInfo File' => 'Mapinfo File',
    'DGN' => 'Microstation DGN',
    'Memory' => 'Memory',
    'MySQL' => 'MySQL',
    'OCI' => 'Oracle Spatial',
    'ODBC' => 'ODBC',
    'OGDI' => 'OGDI Vectors',
    'PCIDSK' => 'PCI Geomatics Database File',
    'PostgreSQL' => 'PostgreSQL',
    'REC' => 'EPIInfo .REC',
    'S57' => 'S-57 (ENC)',
    'SDTS' => 'SDTS',
    'SQLite' => 'SQLite/SpatiaLite',
    'UK. NTF' => 'UK .NTF',
    'TIGER' => 'U.S. Census TIGER/Line',
    'VFK' => 'VFK data',
    'VRT' => 'VRT - Virtual Datasource',
    'XPLANE' => 'X-Plane/Flightgear aeronautical data',
    );

## @ignore
sub DataSourceTemplate {
    my($self) = @_;
    my $n = $self->GetName;
    # return simplified BNF and tell more in help string
    if ($n eq 'DODS') {
	return ('DODS:<URL>','');
    } elsif ($n eq 'SDE') {
	return ('SDE:<server>,<instance>,<database>,<username>,<password>,<layer>[,<parentversion>][,<childversion>]','');
    } elsif ($n eq 'GeoJSON') {
	return ('<URL>','');
    } elsif ($n eq 'IDB') {
	return ('IDB:dbname=<database> server=<host> user=<username> pass=<password> table=<tablename>','');
    } elsif ($n eq 'INGRES') {
	return ('@driver=ingres,dbname=<database>[,userid=<username>][,password=<password>][,tables=<tables>]','');
    } elsif ($n eq 'MySQL') {
	return ('MYSQL:<database>[,user=<username>][,password=<password>][,host=<host>][,port=<port>][,tables=<tables>]','');
    } elsif ($n eq 'OCI') {
	return ('OCI:<username>/<password>@<database>[:<tables>]','');
    } elsif ($n eq 'PostgreSQL') {
	return ('PG:dbname=<database>[ user=<username>][ password=<password>][ host=<host>][ port=<port>][ tables=<tables>][ schemas=<schemas>][ active_schema=<active_schema>]',
		"tables is a comma separated list of [schema.]table[(geometry_column)]");
    } else {
	return ('<filename>','');
    }
}

## @ignore
sub FormatName {
    my($self) = @_;
    my $n = $self->GetName;
    return $FormatNames{$n};
}

1;
