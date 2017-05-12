package GD::Graph::smootharea;
 
use strict;
use warnings;

use GD;
use GD::Graph::smoothlines;

use GD::Graph::colour qw(:colours);
use GD::Graph::utils qw(:all);

@GD::Graph::smootharea::ISA = qw( GD::Graph::smoothlines );

use vars qw($VERSION);
$VERSION = '1.6';

sub enableGradient {
	$_[0]->{_enableGradient} = $_[1] if ( defined $_[1] );
	return exists $_[0]->{_enableGradient} ? $_[0]->{_enableGradient} : 0;
}
sub gradientStartColor {
	$_[0]->{_gradientStartColor} = $_[1] if ( defined $_[1] );
	return exists $_[0]->{_gradientStartColor} ? $_[0]->{_gradientStartColor} : 'white';
}
sub gradientEndColor {
	$_[0]->{_gradientEndColor} = $_[1] if ( defined $_[1] );
	return exists $_[0]->{_gradientEndColor} ? $_[0]->{_gradientEndColor} : 'green';
}

sub draw_data_set
{
	my $self = shift;
	my $ds   = shift;
	
	my @values = $self->{_data}->y_values( $ds ) or
		return $self->_set_error( "Impossible illegal data set: $ds", $self->{_data}->error )
	;
	
	# Select a data colour
	my $dsci = $self->set_clr( $self->pick_data_clr( $ds ) );
	my $brci = $self->set_clr( $self->pick_border_clr( $ds ));
	
	# Create a new polygon
	my $poly = GD::Polygon->new();
	
	my ( @top, @bottom );
	
	# Add the data points
	for ( my $i = 0; $i < @values; $i++ )
	{
		my $value = $values[$i];
		next unless defined $value;
		
		my $bottom = $self->_get_bottom( $ds, $i );
		$value = $self->{_data}->get_y_cumulative( $ds, $ i)
			if $self->{cumulate}
		;
		
		my ( $x, $y ) = $self->val_to_pixel( $i + 1, $value, $ds );
		push @top, [$x, $y];
		# Need to keep track of this stuff for hotspots, and because
		# it's the only reliable way of closing the polygon, without
		# making odd assumptions.
		push @bottom, [$x, $bottom];
		
		# Hotspot stuff
		# XXX needs fixing. Not used at the moment.
		next unless defined $self->{_hotspots}->[$ds]->[$i];
		if ( $i == 0 )
		{
			$self->{_hotspots}->[$ds]->[$i] = ["poly", 
				$x, $y,
				$x , $bottom,
				$x - 1, $bottom,
				$x - 1, $y,
				$x, $y
			];
		}
		else
		{
			$self->{_hotspots}->[$ds]->[$i] = ["poly", 
				$poly->getPt($i),
				@{$bottom[$i]},
				@{$bottom[$i-1]},
				$poly->getPt($i-1),
				$poly->getPt($i)
			];
		}
	}
	
	my @_points = @top;
	
	# little stupid, but this is the interface
	@_points = map { { x => $_->[0], y => $_->[1] } } @_points;
	@_points = @{ $self->_getPoints( $ds, \@_points, 1 ) };
	@_points = map { [ $_->{x}, $_->{y} ] } @_points;
	
	foreach my $pair ( @_points, reverse @bottom ) {
		$poly->addPt( @$pair );
	}
	
	if ( $self->enableGradient )
	{
		my $min_bottom = $bottom[0]->[1];
		my $max_bottom = $_points[0]->[1];
		for ( @_points ) {
			$max_bottom = $_->[1] if ( $_->[1] < $max_bottom );
		}
		my $image = $self->FillGradient( 
			$self->IMAGE_GRAPH_GRAD_VERTICAL, 
			$self->color_to_int( $self->gradientStartColor ),
			$self->color_to_int( $self->gradientEndColor ),
			int ( $min_bottom - $max_bottom )
		);
		
		my $last_w;
		for ( @_points ) {
			$self->{graph}->copy(
				$image,
				$_->[0] , $_->[1],
				0       , $_->[1] - $max_bottom ,
				defined $last_w ? int($_->[0] - $last_w + 1): $image->width,$min_bottom - $_->[1],
			);
			# $last_w = $_->[0];
		}
		$self->{graph}->polygon($poly, $brci)
			if defined $brci;
		# undef $dsci;
		# undef $brci;
	} else {
		# Draw a filled and a line polygon
		$self->{graph}->filledPolygon( $poly, $dsci )
			if defined $dsci;
		$self->{graph}->polygon( $poly, $brci )
			if defined $brci;
	}
	
	# Draw the accent lines
	if ( defined $brci &&
		( $self->{right} - $self->{left} ) / @values > $self->{accent_treshold} 
	) {
		for my $i ( 0 .. $#top ) {
			my ($x, $y) = @{$top[$i]};
			my $bottom = $bottom[$i]->[1];
			$self->{graph}->dashedLine( $x, $y, $x, $bottom, $brci );
		}
	}
	
	return $ds
}

# used only for gradient option
sub color_to_int
{
	my $self = shift;
	my ( $r, $g, $b ) = _rgb( shift );
	return $r * ( 256 ** 2 ) + $g * ( 256 ) + $b;
}

use GD::Image;
use GD::Polygon;

sub IMAGE_GRAPH_GRAD_HORIZONTAL { 'IMAGE_GRAPH_GRAD_HORIZONTAL' }
sub IMAGE_GRAPH_GRAD_VERTICAL   { 'IMAGE_GRAPH_GRAD_VERTICAL' }
sub IMAGE_GRAPH_GRAD_HORIZONTAL_MIRRORED { 'IMAGE_GRAPH_GRAD_HORIZONTAL_MIRRORED' }
sub IMAGE_GRAPH_GRAD_VERTICAL_MIRRORED   { 'IMAGE_GRAPH_GRAD_VERTICAL_MIRRORED' }
sub IMAGE_GRAPH_GRAD_DIAGONALLY_TL_BR { 'IMAGE_GRAPH_GRAD_DIAGONALLY_TL_BR' }
sub IMAGE_GRAPH_GRAD_DIAGONALLY_BL_TR { 'IMAGE_GRAPH_GRAD_DIAGONALLY_BL_TR' }
sub IMAGE_GRAPH_GRAD_RADIAL { 'IMAGE_GRAPH_GRAD_RADIAL' }

sub FillGradient
{
	my $self = shift;
	my ( $direction, $startColor, $endColor, $count, $alpha ) = @_;
	$count = 100 unless ( defined $count );
	$alpha = 0   unless ( defined $alpha );
	
	my $this = $self->{FillGradient} = {};
	
	$this->{_direction} = $direction;

	$this->{_startColor}->{RED}   = ($startColor >> 16) & 0xff;
	$this->{_startColor}->{GREEN} = ($startColor >> 8 ) & 0xff;
	$this->{_startColor}->{BLUE}  = ($startColor      ) & 0xff;
	
	$this->{_endColor}->{RED}   = ($endColor >> 16) & 0xff;
	$this->{_endColor}->{GREEN} = ($endColor >> 8 ) & 0xff;
	$this->{_endColor}->{BLUE}  = ($endColor      ) & 0xff;
	
	$this->{_count} = $count;
	
	my ( $width, $height );
	if ( $this->{_direction} eq $self->IMAGE_GRAPH_GRAD_HORIZONTAL ) {
		$width  = $this->{_count};
		$height = 1;
	} elsif ( $this->{_direction} eq $self->IMAGE_GRAPH_GRAD_VERTICAL ) {
		$width  = 1;
		$height = $this->{_count};
	} elsif ( $this->{_direction} eq $self->IMAGE_GRAPH_GRAD_HORIZONTAL_MIRRORED ) {
		$width  = 2 * $this->{_count};
		$height = 1;
	} elsif ( $this->{_direction} eq $self->IMAGE_GRAPH_GRAD_VERTICAL_MIRRORED ) {
		$width  = 1;
		$height = 2 * $this->{_count};
	} elsif ( $this->{_direction} eq $self->IMAGE_GRAPH_GRAD_DIAGONALLY_TL_BR || $this->{_direction} eq $self->IMAGE_GRAPH_GRAD_DIAGONALLY_BL_TR ) {
		$width = $height = $this->{_count} / 2;
	} elsif ( $this->{_direction} eq $self->IMAGE_GRAPH_GRAD_RADIAL ) {
		$width = $height = sqrt($this->{_count} * $this->{_count} / 2);
	}
	
	$this->{_image} = GD::Image->newTrueColor( $width, $height );
	
	my $redIncrement   = ($this->{_endColor}->{RED}   - $this->{_startColor}->{RED}  ) / $this->{_count};
	my $greenIncrement = ($this->{_endColor}->{GREEN} - $this->{_startColor}->{GREEN}) / $this->{_count};
	my $blueIncrement  = ($this->{_endColor}->{BLUE}  - $this->{_startColor}->{BLUE} ) / $this->{_count};
	
	for ( my $i = 0; $i <= $this->{_count}; $i++ ) {
		my ( $red, $green, $blue );
		if ($i == 0) {
			$red   = $this->{_startColor}->{RED};
			$green = $this->{_startColor}->{GREEN};
			$blue  = $this->{_startColor}->{BLUE};
		} else {
			$red   = int(($redIncrement * $i)   + $redIncrement   + $this->{_startColor}->{RED});
			$green = int(($greenIncrement * $i) + $greenIncrement + $this->{_startColor}->{GREEN});
			$blue  = int(($blueIncrement * $i)  + $blueIncrement  + $this->{_startColor}->{BLUE});
		}
		my $color = $this->{_image}->colorAllocateAlpha( $red, $green, $blue, $alpha );
		#warn "$red, $green, $blue => $color";
		
		if ( $this->{_direction} eq $self->IMAGE_GRAPH_GRAD_HORIZONTAL ) {
			$this->{_image}->setPixel( $i, 0, $color );
		} elsif ( $this->{_direction} eq $self->IMAGE_GRAPH_GRAD_VERTICAL ) {
			$this->{_image}->setPixel( 0, $height - $i, $color );
		} elsif ( $this->{_direction} eq $self->IMAGE_GRAPH_GRAD_HORIZONTAL_MIRRORED ) {
			$this->{_image}->setPixel( $i, 0, $color );
			$this->{_image}->setPixel( $width - $i, 0, $color );
		} elsif ( $this->{_direction} eq $self->IMAGE_GRAPH_GRAD_VERTICAL_MIRRORED ) {
			$this->{_image}->setPixel( 0, $i, $color );
			$this->{_image}->setPixel( 0, $height - $i, $color );
		} elsif ( $this->{_direction} eq $self->IMAGE_GRAPH_GRAD_DIAGONALLY_TL_BR || $this->{_direction} eq $self->IMAGE_GRAPH_GRAD_DIAGONALLY_BL_TR ) {
			my $polygon = new GD::Polygon;
			if ($i > $width) {
				$polygon->addPt( $width, $i - $width );
				$polygon->addPt( $width, $height );
				$polygon->addPt( $i - $width, $height );
			} else {
				$polygon->addPt( 0, $i );
				$polygon->addPt( 0, $height );
				$polygon->addPt( $width, $height );
				$polygon->addPt( $width, 0 );
				$polygon->addPt( $i, 0 );
			}
			$this->{_image}->filledPolygon( $polygon, $color );
		} elsif ( $this->{_direction} eq $self->IMAGE_GRAPH_GRAD_RADIAL ) {
			if ( $i < $this->{_count} ) {
				$this->{_image}->filledEllipse( $width / 2, $height / 2, $this->{_count} - $i, $this->{_count} - $i, $color );
			}
		}
	}
	
	return $this->{_image};
}

1;

__END__

=head1 NAME

 GD::Graph::smootharea

=head1 SYNOPSIS

=head1 DESCRIPTION

 This package is used for creation a smooth area chart.

=head1 EXAMPLES

 use GD::Graph::smootharea;
 
 my $graph = GD::Graph::smootharea->new();

=head1 MODULE STRUCTURE

=head1 METHODS

 Available public methods

=over 4

=item proto bool enableGradient ( [ bool $enable ] )

=item proto string gradientStartColor ( [ string $color ] )

=item proto string gradientEndColor ( [ string $color ] )

=back

=head1 SEE ALSO

 GD::Graph
 GD::Graph::smoothlines

=head1 COPYRIGHT

 Copyright (c) 2007 Andrei Kozovski

=head1 AUTHORS

 This release was made by Andrei Kozovski

=cut
