package GD::Cairo;

use 5.006;
use strict;
use warnings;

require Exporter;
use Encode;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use GD::Cairo ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'gd' => [ qw(
	gdBrushed
	gdDashSize
	gdMaxColors
	gdStyled
	gdStyledBrushed
	gdTiled
	gdTransparent
	gdAntiAliased
	gdArc
	gdChord
	gdPie
	gdNoFill
	gdEdged
	gdAlphaMax
	gdAlphaOpaque
	gdAlphaTransparent
	gdTinyFont
	gdSmallFont
	gdMediumBoldFont
	gdLargeFont
	gdGiantFont
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'gd'} } );

our @EXPORT = qw(
);

our $VERSION = '0.01';

use constant PI => 4 * atan2 1, 1;
use constant PI_2 => 8 * atan2 1, 1;

use constant GC_FONT_SLANT_NORMAL => 'normal';
use constant GC_FONT_SLANT_ITALIC => 'italic';
use constant GC_FONT_SLANT_OBLIQUE => 'oblique';

use constant GC_FONT_WEIGHT_NORMAL => 'normal';
use constant GC_FONT_WEIGHT_BOLD => 'bold';

use constant {
	'gdAntiAliased' => -7,
	'gdTransparent' => -6,
	'gdTiled' => -5,
	'gdStyledBrushed' => -4,
	'gdBrushed' => -3,
	'gdStyled' => -2,
	'gdDashSize' => 4,
	'gdMaxColors' => 256,
	'gdArc' => 0,
	'gdPie' => 0,
	'gdChord' => 1,
	'gdNoFill' => 2,
	'gdEdged' => 4,
	'gdAlphaMax' => 127,
	'gdAlphaOpaque' => 0,
	'gdAlphaTransparent' => 127,
};

use Cairo;
use Data::Dumper;

our $EXTENTS_SELF;
our $TRUECOLOR = 0;
our $ANTIALIAS = 0;

use vars qw( $AUTOLOAD );

# Preloaded methods go here.

sub _new
{
	my( $class, @opts ) = @_;

	my $self = bless {
		background_color => undef,
		colors => [],
		operations => [],
		transparent => undef,
		thickness => 1,
		brush => undef,
		style => {},
	}, $class;
}

sub newFromSurface
{
	my( $class, $surface ) = @_;

	my $self = $class->_new();

	$self->{surface} = $surface;

	$self->{context} = Cairo::Context->create( $surface );
	$self->{context}->set_line_width( $self->{thickness} );

	$self->{width} = $surface->get_width;
	$self->{height} = $surface->get_height;

	$EXTENTS_SELF = $self;

	return $self;
}

sub new
{
	my( $class, $w, $h, $truecolor ) = @_;

	$truecolor = $TRUECOLOR if scalar(@_) == 3;
	my $format = $truecolor ? 'argb32' : 'a8';
	$format = 'argb32';

	my $surface = Cairo::ImageSurface->create( $format, $w, $h );

	return $class->newFromSurface( $surface );
}

sub newFromPngData
{
	my( $class, $data, $truecolor ) = @_;

	pos($data) = 0;
	my $surface = Cairo::ImageSurface->create_from_png_stream(sub {
		my( $closure, $length ) = @_;
		use bytes;
		my $buffer = substr($data,pos($data),$length);
		pos($data) += $length;
		return $buffer;
	});

	return $class->newFromSurface( $surface );
}

sub getCairoContext
{
	$_[0]->{context};
}

sub getCairoImageSurface
{
	$_[0]->{surface};
}

sub getCairoPattern
{
	$_[0]->{brush};
}

sub trueColor
{
	my( $self, $truecolor ) = @_;

	$TRUECOLOR = $truecolor;
}

sub newPalette
{
	my( $class, $w, $h ) = @_;

#	my $surface = Cairo::ImageSurface->create( 'a8', $w, $h );
	my $surface = Cairo::ImageSurface->create( 'argb32', $w, $h );

	return $class->newFromSurface( $surface );
}

sub newTrueColor
{
	my( $class, $w, $h ) = @_;

	my $surface = Cairo::ImageSurface->create( 'argb32', $w, $h );

	return $class->newFromSurface( $surface );
}

sub ignoreMissing
{
	my( $warn ) = @_;

	if( $warn )
	{
		*AUTOLOAD = sub {
			$AUTOLOAD =~ s/^.*:://;
			return if $AUTOLOAD =~ /^[A-Z]/;
			Carp::carp "I don't know how to '$AUTOLOAD' - it may be supported in GD but isn't in the GD::Cairo wrapper. You may need to fix this";
		};
	}
	else
	{
		*AUTOLOAD = sub {}
	}
}

sub _color
{
	my( $self, $index ) = @_;

	my $color;

	if( $index == gdAntiAliased )
	{
		Carp::croak "You must call setAntiAliased before using gdAntiAliased"
			unless defined $self->{antialiased};
		$color = $self->{antialiased};
	}
	else
	{
		$color = $self->{colors}->[$index]
			or Carp::croak "Invalid color $index - perhaps you need to call colorAllocate";
	}

	return $color;
}

sub _color_to_index
{
	my( $self, $color ) = @_;

	my $i = 0;
	for(@{$self->{colors}})
	{
		return $i if( _color_eq( $color, $_ ) );
		++$i;
	}

	die "No color allocated for [".join(',',@$color)."]";
}

sub _color_index_to_role
{
	my( $self, $index, $x, $y ) = @_;

	if( $index == gdBrushed or $index == gdTiled )
	{
		$x ||= 0;
		$y ||= 0;
		unless( defined $self->{brush} )
		{
			Carp::croak "Can't use gdBrushed without first calling setBrush";
		}
		my $w = $self->{brush}->width;
		my $h = $self->{brush}->height;
		my $thickness = $w > $h ? $w : $h;
		my $style = gdBrushed == $index ? 'repeat' : 'repeat';
		return
			set_source_surface => [$self->{brush}->{surface}, $x, $y],
			set_line_width => [$thickness],
				sub {
					my( $cr ) = @_;
					my $pattern = $cr->get_source;
					$pattern->set_filter( 'bilinear' );
					$pattern->set_extend( $style );
				} => [];
	}
	elsif( $index == gdStyled )
	{
		Carp::croak "Can only apply gdStyled to lines";
	}
	elsif( $index == gdAntiAliased )
	{
		return
			set_source_rgba => $self->_color( $index ),
			set_antialias => ['default'],
			set_line_width => [$self->{thickness}];
	}
	else
	{
		return
			set_source_rgba => $self->_color( $index ),
			set_antialias => ['none'],
			set_line_width => [$self->{thickness}];
	}
}

sub _color_eq
{
	for(0..3) { return 0 if $_[0]->[$_] != $_[1]->[$_] };
	return 1;
}

sub _shape_color
{
	my( $self, $shape ) = @_;

	for(my $i = 0; $i < @$shape; $i+=2)
	{
		if( $shape->[$i] eq 'set_source_rgba' )
		{
			return $shape->[$i+1];
		}
	}

	return undef;
}

*GD::Cairo::colorAllocateAlpha = \&colorAllocate;
*GD::Cairo::colorClosest = \&colorAllocate;
*GD::Cairo::colorExact = \&colorAllocate;
*GD::Cairo::colorResolve = \&colorAllocate;
sub colorAllocate
{
	my( $self, $red, $green, $blue, $alpha ) = @_;

	$red /= 255;
	$green /= 255;
	$blue /= 255;
	$alpha = @_ == 4 ? 1 : (1 - $alpha / 127);

	for(my $i = 0; $i < @{$self->{colors}}; ++$i)
	{
		my @color = @{$self->{colors}->[$i]};
		if( $color[0] == $red and $color[1] == $green and $color[2] == $blue and $color[3] == $alpha )
		{
			return $i;
		}
	}

	push @{$self->{colors}}, [$red, $green, $blue, $alpha];

	return $#{$self->{colors}};
}

sub colorDeallocate
{
	my( $self, $color ) = @_;

	# Unimplemented
}

sub colorsTotal
{
	my( $self ) = @_;

	if( $self->isTrueColor )
	{
		return undef;
	}
	else
	{
		return scalar(@{$self->{colors}});
	}
}

sub _in_shape
{
	my( $self, $x, $y ) = @_;

	my $cr = $self->{context};

	my $i = -1;
	my $shape;
	my $color;

	for($i = $#{$self->{operations}}; $i > -1; --$i, undef $color)
	{
		$shape = $self->{operations}->[$i];
		$cr->save;
		for(my $j = 0; $j < @$shape; $j+=2)
		{
			my( $f, $opts ) = @$shape[$j,$j+1];
			if( $f eq 'fill' or $f eq 'stroke' or $f eq 'paint' )
			{
			}
			elsif( $f eq 'set_source_rgba' )
			{
				$color = $opts;
			}
			elsif( ref($f) eq 'CODE' )
			{
			}
			else
			{
				$cr->$f( @$opts );
			}
		}
		my $in_fill = $cr->in_fill( $x, $y );
		$cr->restore;
		last if $in_fill;
	}

	if( $i != -1 )
	{
		return $i, $shape, $color;
	}
	else
	{
		return ();
	}
}

sub _convert_style_to_dashes
{
	my( $self, @colors ) = @_;

	my %lines;
	my %components = map({ ($_ == gdTransparent) ? () : ($_ => 1) } @colors);

	foreach my $color (keys %components)
	{
		my $dash_map = join '', map({ $_ == $color ? 1 : 0 } @colors);
		my @opts = (0); # dash offset
		while(length($dash_map))
		{
			if( $dash_map =~ s/^(1+)// )
			{
				push @opts, length($1);
			}
			if( $dash_map =~ s/^(0+)// )
			{
				push @opts, length($1);
			}
		}
		unshift @opts, 0 if $colors[0] != $color; # gap or color first

		$lines{$color} = \@opts;
	}

	return %lines;
}

sub _set_brush
{
	my( $self, $shape, $index, %opts ) = @_;

	my $x = exists($opts{x}) ? $opts{x} : 0;
	my $y = exists($opts{y}) ? $opts{y} : 0;
	unless( defined $self->{brush} )
	{
		Carp::croak "Can't use gdBrushed without first calling setBrush";
	}
	my $w = $self->{brush}->width;
	my $h = $self->{brush}->height;
	my $thickness = $w > $h ? $w : $h;
	my $style = gdBrushed == $index ? 'repeat' : 'repeat';
	unshift @$shape,
		set_source_surface => [$self->{brush}->{surface}, $x, $y],
		set_line_width => [$thickness],
		sub {
			my( $cr ) = @_;
			my $pattern = $cr->get_source;
			$pattern->set_filter( 'bilinear' );
			$pattern->set_extend( $style );
		} => [];
}

sub _stroke_shape
{
	my( $self, $shape, $index, %opts ) = @_;

	my $antialias = defined($opts{'antialias'}) ?
		$opts{'antialias'} :
		($index == gdAntiAliased or $ANTIALIAS) ? 'default' : 'none';

	if( $index == gdBrushed or $index == gdTiled )
	{
		$self->_set_brush( $shape, $index, %opts );
	}
	elsif( $index == gdStyled )
	{
		unless( scalar(keys %{$self->{style}}) > 0 )
		{
			Carp::croak "Can't use gdStyled without first calling setStyle";
		}

		while(my( $color, $dashes ) = each %{$self->{style}})
		{
			my @new_shape = @$shape;
			unshift @new_shape,
				set_source_rgba => $self->_color( $color ),
				set_dash => $dashes,
				set_line_width => [$self->{thickness}],
				set_antialias => [$antialias];
			push @new_shape, stroke => [];

			push @{$self->{operations}}, \@new_shape;
		}

		return; # Don't add $shape
	}
	else
	{
		unshift @$shape,
			set_source_rgba => $self->_color( $index ),
			set_antialias => [$antialias],
			set_line_width => [$self->{thickness}];
	}

	push @$shape, stroke => [];

	push @{$self->{operations}}, $shape;
}

sub _fill_shape
{
	my( $self, $shape, $index, %opts ) = @_;

	my $antialias = defined($opts{'antialias'}) ?
		$opts{'antialias'} :
		($index == gdAntiAliased or $ANTIALIAS) ? 'default' : 'none';

	if( $index == gdBrushed or $index == gdTiled )
	{
		$self->_set_brush( $shape, $index, %opts );
	}
	elsif( $index == gdStyled )
	{
		Carp::croak "Can only apply gdStyled to lines";
	}
	else
	{
		unshift @$shape,
			set_source_rgba => $self->_color( $index ),
			set_antialias => [$antialias];
	}

	push @$shape, fill => [];

	push @{$self->{operations}}, $shape;
}

sub _paint_shape
{
	my( $self, $shape, $index, %opts ) = @_;

	if( $index == gdBrushed or $index == gdTiled )
	{
		$self->_set_brush( $shape, $index, %opts );
	}
	elsif( $index == gdStyled )
	{
		Carp::croak "Can only apply gdStyled to lines";
	}
	else
	{
		unshift @$shape, set_source_rgba => $self->_color( $index );
	}

	push @$shape, paint => [];

	push @{$self->{operations}}, $shape;
}

sub fill
{
	my( $self, $x, $y, $color ) = @_;

	my $cr = $self->{context};

	# Background
	if( 0 == scalar @{$self->{operations}} )
	{
		$self->{background_color} = $self->_color( $color );
	}
	# Find the first shape that contains $x,$y
	# If it's a stroke then 'fill' it by adding the fill behind, otherwise
	# replace it with the new color
	elsif( my( $i, $shape, $shape_color ) = $self->_in_shape( $x, $y ) )
	{
		my @new_shape;
		my $stroked = 0;
		for(my $j = 0; $j < @$shape; $j+=2)
		{
			my( $f, $opts ) = @$shape[$j,$j+1];
			if( $f eq 'stroke' )
			{
				$stroked = 1;
			}
			elsif(
				$f eq 'stroke' or
				$f eq 'fill' or
				$f eq 'set_source_rgba' or
				$f eq 'set_source_surface' )
			{
			}
			else
			{
				push @new_shape, $f => $opts;
			}
		}
		$self->_fill_shape( \@new_shape, $color );
		if( $stroked )
		{
			splice(@{$self->{operations}},$i,0,pop @{$self->{operations}});
		}
		else
		{
			splice(@{$self->{operations}},$i,1,pop @{$self->{operations}});
		}
	}
}

sub getPixel
{
	my( $self, $x, $y ) = @_;

	my $color;

# Try finding the pixel in a shape
	if( my( $i, $shape, $c ) = $self->_in_shape( $x, $y ) )
	{
		$color = $c;
	}
# See if they setPixel this pixel
	elsif( exists $self->{pixels}->{"${x}x${y}"} )
	{
		return $self->{pixels}->{"${x}x${y}"};
	}
# Or the background
	elsif( defined $self->{background_color} )
	{
		$color = $self->{background_color};
	}
# GetPixel must return something
	else
	{
		$color = $self->{colors}->[0];
	}

	return $self->_color_to_index( $color );
}

sub setPixel
{
	my( $self, $x, $y, $color ) = @_;

	if( $color == gdBrushed )
	{
		my $w = $self->{brush}->width;
		my $h = $self->{brush}->height;
		$self->copy( $self->{brush}, $x - $w/2, $y - $h/2, 0, 0, $w, $h );
	}
	else
	{
		$self->{pixels}->{"${x}x${y}"} = $color;
		push @{$self->{operations}}, [
			set_source_rgba => $self->_color( $color ),
			set_line_width => [1],
			set_antialias => ['none'],
			move_to => [$x-1,$y],
			line_to => [$x,$y],
			stroke => []
		];
	}
}

sub rgb
{
	my( $self, $index ) = @_;

	return map { sprintf("%.0f", $_ * 255) } @{$self->{colors}->[$index]}[0..2];
}

sub transparent
{
	my( $self, $index ) = @_;

	if( 1 == @_ )
	{
		return defined $self->{transparent} ?
			$self->_color_to_index( $self->{transparent} ) :
			-1;
	}

	return $self->{transparent} = $index > -1 ?
		$self->{colors}->[$index] :
		-1;
}

*setTile = \&setBrush;
sub setBrush
{
	my( $self, $image ) = @_;

	unless( $image->isa( 'GD::Cairo' ) )
	{
		$image = GD::Cairo->newFromPngData( $image->png );
	}
	$self->{brush} = $image;
}

sub setStyle
{
	my( $self, @colors ) = @_;

	my %lines = $self->_convert_style_to_dashes( @colors );

	$self->{style} = \%lines;
}

sub setThickness
{
	my( $self, $thickness ) = @_;

	$self->{thickness} = $thickness;
}

sub setAntiAliased
{
	my( $self, $color ) = @_;

	$self->{antialiased} = $self->_color( $color );
}

sub rectangle
{
	my( $self, $x, $y, $x2, $y2, $color ) = @_;

	my $shape = [
		rectangle => [$x, $y, $x2-$x, $y2-$y],
	];

	$self->_stroke_shape( $shape, $color,
		x => $x,
		y => $y,
		antialias => 'none'
	);
}

sub filledRectangle
{
	my( $self, $x, $y, $x2, $y2, $color ) = @_;

	my $shape = [
		rectangle => [$x, $y, $x2-$x, $y2-$y],
	];

	$self->_fill_shape( $shape, $color,
		x => $x,
		y => $y,
		antialias => 'none'
	);
}

sub _polygon
{
	my( $self, $polygon, $color ) = @_;

	my @shape = (move_to => [$polygon->getPt(0)]);
	
	my(undef, @vertices) = $polygon->vertices;
	push @shape, line_to => $_ for @vertices;

	return \@shape;
}

# I think polygon is a synonym of openPolygon?
*polygon = \&openPolygon;
sub openPolygon
{
	my( $self, $polygon, $color ) = @_;

	my $shape = _polygon( @_ );

	push @$shape, close_path => [];

	$self->_stroke_shape( $shape, $color );
}

sub unclosedPolygon
{
	my( $self, $polygon, $color ) = @_;

	my $shape = _polygon( @_ );

	$self->_stroke_shape( $shape, $color );
}

sub filledPolygon
{
	my( $self, $polygon, $color ) = @_;

	my $shape = _polygon( @_ );

	push @$shape, close_path => [];

	$self->_fill_shape( $shape, $color );
}

sub line
{
	my( $self, $x, $y, $x2, $y2, $color ) = @_;

	if( abs($x2-$x) < 1 and abs($y2-$y) < 1 )
	{
		return $self->setPixel( $x, $y, $color );
	}

	my $shape = [
		new_path => [],
		move_to => [$x, $y],
		line_to => [$x2, $y2]
	];

	my $antialias = ($x == $x2 or $y == $y2) ? 'none' : undef;

	$self->_stroke_shape( $shape, $color,
		x => $x,
		y => $y,
		antialias => $antialias
	);
}

sub _ellipse
{
	my( $self, $x, $y, $w, $h, $color ) = @_;

	my $s = 0;
	my $e = PI_2;

	[
		save => [],
		translate => [$x - .5, $y],
		scale => [$w/2 - .5, $h/2],
		arc => [0, 0, 1, $s, $e ],
		close_path => [],
		restore => [],
	];
}

sub ellipse
{
	my( $self, $x, $y, $w, $h, $color ) = @_;

	return unless $w > 0 and $h > 0;

	my $shape = _ellipse( @_ );

	$self->_stroke_shape( $shape, $color,
		x => $x,
		y => $y
	);
}

sub filledEllipse
{
	my( $self, $x, $y, $w, $h, $color ) = @_;

	return unless $w > 0 and $h > 0;

	my $shape = _ellipse( @_ );

	$self->_fill_shape( $shape, $color,
		x => $x,
		y => $y
	);
}

sub _arc
{
	my( $self, $x, $y, $w, $h, $s, $e, $color ) = @_;

	$s = $s/180*PI;
	$e = $e/180*PI;

	[
		save => [],
		translate => [$x - .5, $y],
		scale => [$w/2 - .5, $h/2],
		arc => [0, 0, 1, $s, $e ],
		restore => [],
	];
}

sub arc
{
	my( $self, $x, $y, $w, $h, $s, $e, $color ) = @_;

	return unless $w > 0 and $h > 0;

	my $shape = _arc( @_ );

	$self->_stroke_shape( $shape, $color,
		x => $x,
		y => $y,
	);
}

sub filledArc
{
	my( $self, $x, $y, $w, $h, $s, $e, $color, $arc_style ) = @_;

	return unless $w > 0 and $h > 0;

	$arc_style ||= 0;

	my $shape = [];

	# Cairo doesn't support chords
	if( $arc_style & gdChord )
	{
		$s = $s/180*PI;
		$e = $e/180*PI;

		my $x1 = $x + ($w/2) * cos($s);
		my $y1 = $y + ($h/2) * sin($s);

		my $x2 = $x + ($w/2) * cos($e);
		my $y2 = $y + ($h/2) * sin($e);

		push @$shape,
			move_to => [$x1,$y1],
			line_to => [$x2,$y2];
	}
	else
	{
		$shape = _arc( @_ );
	}

	push @$shape,
		line_to => [$x, $y],
		close_path => [];

	if( $arc_style & gdNoFill )
	{
		$self->_stroke_shape( $shape, $color );
	}
	else
	{
		$self->_fill_shape( $shape, $color );
	}
}

sub copy
{
	my( $self, $sourceImage, $dstX, $dstY, $srcX, $srcY, $width, $height ) = @_;

	unless( $sourceImage->isa( 'GD::Cairo' ) )
	{
		$sourceImage = GD::Cairo->newFromPngData( $sourceImage->png );
	}

	push @{$self->{operations}}, [
		set_source_surface => [$sourceImage->{surface}, $dstX-$srcX, $dstY-$srcY],
		rectangle => [$dstX,$dstY,$width,$height],
		fill => []
	];
}

*copyResampled = \&copyResized;
sub copyResized
{
	my( $self, $sourceImage, $dstX, $dstY, $srcX, $srcY, $destW, $destH, $srcW, $srcH ) = @_;

	unless( $sourceImage->isa( 'GD::Cairo' ) )
	{
		$sourceImage = GD::Cairo->newFromPngData( $sourceImage->png );
	}

	my $scaleX = $destW / $srcW;
	my $scaleY = $destH / $srcH;

	push @{$self->{operations}}, [
		set_source_surface => [$sourceImage->{surface}, 0, 0],
		sub {
			my( $cr ) = @_;
			my $pattern = $cr->get_source;
			$pattern->set_filter( 'bilinear' );
			my $matrix = $pattern->get_matrix;
			$matrix->translate( $srcX, $srcY );
			$matrix->scale( 1/$scaleX, 1/$scaleY );
			$matrix->translate( -1*$dstX, -1*$dstY );
			$pattern->set_matrix( $matrix );
		} => [],
		translate => [$dstX,$dstY],
		scale => [$scaleX,$scaleY],
		rectangle => [0,0,$srcW,$srcH],
		fill => [],
	];
}

sub copyRotated
{
	my( $self, $sourceImage, $dstX, $dstY, $srcX, $srcY, $width, $height, $angle ) = @_;

	$angle = $angle/180*PI;

	unless( $sourceImage->isa( 'GD::Cairo' ) )
	{
		$sourceImage = GD::Cairo->newFromPngData( $sourceImage->png );
	}

	my $w = $sourceImage->width;
	my $h = $sourceImage->height;

	push @{$self->{operations}}, [
		set_source_surface => [$sourceImage->{surface}, 0, 0],
		sub {
			my( $cr ) = @_;
			my $pattern = $cr->get_source;
			$pattern->set_filter( 'bilinear' );
			my $matrix = $pattern->get_matrix;
			$matrix->translate( $w/2, $h/2 );
			$matrix->rotate( $angle );
			$matrix->translate( -1*$dstX, -1*$dstY );
			$pattern->set_matrix( $matrix );
		} => [],
		translate => [$dstX, $dstY],
		rotate => [$angle],
		rectangle => [$width/-2,$height/-2,$width,$height],
		fill => [],
	];
}

sub _rotate_point
{
	my( $x, $y, $ox, $oy, $angle ) = @_;

	$x -= $ox;
	$y -= $oy;

	my $xx = $x * cos($angle) + $y * sin($angle);
	my $yy = -1 * $x * sin($angle) + $y * cos($angle);

	return( $xx + $ox, $yy + $oy );
}

sub _extents
{
	my( $self, $font, $ptsize, $angle, $x, $y, $string ) = @_;

	my $cr = $self->{context};

	$cr->save;
	$cr->select_font_face( $font, GC_FONT_SLANT_NORMAL, GC_FONT_SLANT_NORMAL );
	$cr->set_font_size( $ptsize );
#	$cr->rotate( $angle );
	my $extents = $cr->text_extents( $string );
	$cr->restore;

	return (
		_rotate_point( $x + $extents->{x_bearing},
		$y + $extents->{y_bearing}, $x, $y, $angle ),
		_rotate_point( $x + $extents->{x_bearing} + $extents->{width},
		$y + $extents->{y_bearing}, $x, $y, $angle ),
		_rotate_point( $x + $extents->{x_bearing} + $extents->{width},
		$y + $extents->{y_bearing} + $extents->{height}, $x, $y, $angle ),
		_rotate_point( $x + $extents->{x_bearing},
		$y + $extents->{y_bearing} + $extents->{height}, $x, $y, $angle ),
	);
}

sub gdTinyFont
{
	GD::Cairo::Font->load( 'gdTinyFont' );
}
sub gdSmallFont
{
	GD::Cairo::Font->load( 'gdSmallFont' );
}
sub gdMediumBoldFont
{
	GD::Cairo::Font->load( 'gdMediumBoldFont' );
}
sub gdLargeFont
{
	GD::Cairo::Font->load( 'gdLargeFont' );
}
sub gdGiantFont
{
	GD::Cairo::Font->load( 'gdGiantFont' );
}

*char = \&string;
sub string
{
	my( $self, $font, $x, $y, $string, $color, $angle ) = @_;

	$string = Encode::decode("iso-8859-1", $string) unless utf8::is_utf8($string);

	$color = $self->_color( $color );
	$angle ||= 0;

	my $ptsize = $font->width * 1.7;
	my $weight = GC_FONT_WEIGHT_NORMAL;
	if( $font->width == 7 ) # gdMediumBoldFont
	{
		$weight = GC_FONT_WEIGHT_BOLD;
	}

	my @bounds = $self->_extents( 'Monospace', $ptsize, 0, 0, 0, $string );

	if( $angle > 0 )
	{
		$x += $bounds[7]-$bounds[1];
	}
	else
	{
		$y += $bounds[7]-$bounds[1];
	}

	push @{$self->{operations}}, [
		set_source_rgba => $color,
		select_font_face => [ 'Monospace', GC_FONT_SLANT_NORMAL, $weight ],
		set_font_size => [$ptsize],
		move_to => [$x, $y],
		rotate => [$angle],
		show_text => [$string],
	];
}

*charUp = \&stringUp;
sub stringUp
{
	$_[0]->string(@_[1..5],PI*1.5);
}

sub stringFT
{
	my( $self, $color, $fontname, $ptsize, $angle, $x, $y, $string ) = @_;

	$string = Encode::decode("iso-8859-1", $string) unless utf8::is_utf8($string);

	$color = $self->_color( $color );

	$angle *= -1; # Already in radians, but in reverse

	my @bounds = $EXTENTS_SELF->_extents( 'Sans-Serif', @_[3..7] );
	
	return @bounds unless ref($self);

	push @{$self->{operations}}, [
		set_source_rgba => $color,
		select_font_face => [ 'Sans-Serif', GC_FONT_SLANT_NORMAL, GC_FONT_WEIGHT_NORMAL ],
		set_font_size => [$ptsize],
		move_to => [$x,$y],
		rotate => [$angle],
		show_text => [$string],
	];

	return @bounds;
}

sub interlaced {}

sub getBounds
{
	my( $self ) = @_;

	($self->width, $self->height);
}

sub width { $_[0]->{width} }
sub height { $_[0]->{height} }

sub isTrueColor
{
	my( $self ) = @_;

	my $format = $self->{surface}->get_format;

	return $format eq 'argb32' ? 1 : 0;
}

sub _render_operations
{
	my( $self ) = @_;

	my $cr = $self->{context};

	if( defined($self->{background_color}) )
	{
		my @color = @{$self->{background_color}};
		if( defined($self->{transparent}) and
			_color_eq( \@color, $self->{transparent} ) )
		{
			$color[3] = 0;
		}
		$cr->save;
		$cr->set_operator( 'source' );
		$cr->set_source_rgba( @color );
		$cr->paint;
		$cr->restore;
	}

	foreach my $shape (@{$self->{operations}})
	{
		$cr->save;
		for(my $i = 0; $i < @$shape; $i+=2)
		{
			my( $f, $opts ) = @$shape[$i,$i+1];
			if( ref($f) eq 'CODE' )
			{
				&$f( $cr, @$opts );
			}
			else
			{
				$cr->$f( @$opts );
			}
		}
		$cr->restore;
	}

	$cr->show_page;
}

sub _write_buffer
{
	my( $self, $class ) = @_;

	my $buffer = '';
	my $surface = $class->create_from_stream( sub { $buffer .= $_[1] }, '', $self->width, $self->height );
	my $context = Cairo::Context->create( $surface );

	$self->{context} = $context;
	$self->_render_operations;

	return $buffer;
}

sub _write_file
{
	my( $self, $filename, $class ) = @_;

	my $surface = $class->create( $filename, $self->width, $self->height );
	my $context = Cairo::Context->create( $surface );

	$self->{context} = $context;
	$self->_render_operations;
}

sub png
{
	my( $self ) = @_;

	$self->_render_operations;

	my $buffer = '';
	$self->{surface}->write_to_png_stream(sub { $buffer .= $_[1] }, '');

	return $buffer;
}
sub writePng
{
	my( $self, $filename ) = @_;

	open(my $fh, ">", $filename) or die "Error writing to $filename: $!";
	binmode($fh);
	print $fh $self->png;
	close($fh);
}

sub pdf
{
	_write_buffer( $_[0], 'Cairo::PdfSurface' );
}
sub writePdf
{
	_write_file( $_[0], $_[1], 'Cairo::PdfSurface' );
}

sub svg
{
	_write_buffer( $_[0], 'Cairo::SvgSurface' );
}
sub writeSvg
{
	_write_file( $_[0], $_[1], 'Cairo::SvgSurface' );
}

package GD::Cairo::Font;

# Utility class to create GD::Font stub classes that work with GD::Cairo

use strict;

our %GD_FONTS = (
gdTinyFont => {
        nchars => 256,
        offset => 0,
        width => 5,
        height => 8
},
gdSmallFont => {
        nchars => 256,
        offset => 0,
        width => 6,
        height => 13
},
gdMediumBoldFont => {
        nchars => 256,
        offset => 0,
        width => 7,
        height => 13
},
gdLargeFont => {
        nchars => 256,
        offset => 0,
        width => 8,
        height => 16
},
gdGiantFont => {
        nchars => 256,
        offset => 0,
        width => 9,
        height => 15
},
);

our %FONT_CACHE;

sub load
{
	my( $class, $font ) = @_;

	$class = "${class}::$font";

	return $FONT_CACHE{$font} ||= bless $GD_FONTS{$font}, $class;
}

sub nchars { $_[0]->{nchars} }
sub offset { $_[0]->{offset} }
sub width { $_[0]->{width} }
sub height { $_[0]->{height} }

package GD::Cairo::Font::gdTinyFont;

our @ISA = qw( GD::Cairo::Font );

package GD::Cairo::Font::gdSmallFont;

our @ISA = qw( GD::Cairo::Font );

package GD::Cairo::Font::gdMediumBoldFont;

our @ISA = qw( GD::Cairo::Font );

package GD::Cairo::Font::gdLargeFont;

our @ISA = qw( GD::Cairo::Font );

package GD::Cairo::Font::gdGiantFont;

our @ISA = qw( GD::Cairo::Font );

1;

# Autoload methods go after =cut, and are processed by the autosplit program.

__END__

=head1 NAME

GD::Cairo - GD API wrapper around Cairo

=head1 SYNOPSIS

  use GD; # Needed for constants and GD::Polygon
  use GD::Cairo;

  # use GD;
  use GD::Cairo qw( :gd ); # Import GD constants and fonts

  # my $img = GD::Image->new( 400, 300, 1 );
  my $img = GD::Cairo->new( 400, 300, 1 );

  print $fh $img->svg;

=head1 DESCRIPTION

This module provides a GD API emulation for the Cairo graphics library. Cairo is a vector-based drawing package that aims to provide consistent output to many graphics contexts/formats.

=head1 METHODS

See <GD>.

=head2 GD::Cairo-specific methods

=over 4

=item GD::Cairo->new( WIDTH, HEIGHT [, TRUECOLOR ] )

Create a new image of WIDTH by HEIGHT. WIDTH and HEIGHT are in user-space units (e.g. pixels for PNG or points for PDF).

=item GD::Cairo::ignoreMissing( [ WARN ] )

Ignore any missing functionality in GD::Cairo that may be in GD.

=item $data = $img->png

Return the image in PNG format.

=item $data = $img->pdf

Return the image in PDF format.

=item $data = $img->svg

Return the image in SVG format.

=back

=head1 TODO

=over 4

=item new(*FILEHANDLE)

=item new($filename)

=item new($data)

=item newFrom*

(newFromPngData implemented.)

=item colorClosestHWB

=item setAntiAliasedDontBlend($color [,$flag])

=item dashedLine

This is deprecated anyway.

=item fillToBorder

Unlikely to ever work.

=item clone

=item trueColorToPalette

=item alphaBlending

=item saveAlpha

=item interlaced

Ignored.

=item compare($image2)

=item clip($x1,$y1,$x2,$y2)

=item boundsSafe($x,$y)

=item GD::Polygon, GD::Polyline

=item GD::Simple

=head1 BUGS

Patches/suggestions are welcome.

=head2 Images are always true colour

I don't think Cairo supports paletted images, see http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-format-t.

=head2 Alignment in PNG Output

PngSurface doesn't appear to reliably translate coordinates onto the surface e.g. a point at 0,0 doesn't get rendered at all.

=head2 StringFT/String/StringUp

StringFT* will always render using 'Sans-Serif' and String* using 'Monospace' (which depend on fontconfig). I need an example for loading fonts with Cairo.

=head2 SetBrush

GD renders brushes by repeatedly rendering the brush (an image) along the path the given shape provides. This isn't practically achievable with Cairo (AFAIK), so instead I repeat the image along the path/fill.

=head2 SetStyle

Does not support gdStyledBrushed.

=head2 Memory Usage

In order to support GD::Image::fill GD::Cairo builds a stack of operations, which makes it memory inefficient compared to writing direct to a GD::Image surface.

GD::Cairo also stores a hash entry for every pixel set with setPixel to support getPixel.

=head1 SEE ALSO

L<Cairo>, L<GD>, L<GD::SVG> (includes extensive discussion of why translating GD to a vector library is difficult).

http://cairographics.org/manual/

=head1 AUTHOR

Tim D Brody, E<lt>tdb01r@ecs.soton.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Tim D Brody

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
