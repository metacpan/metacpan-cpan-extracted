package GD::Graph::smoothlines;

use strict;
use warnings;

use GD;
use GD::Graph::lines;

@GD::Graph::smoothlines::ISA = qw( GD::Graph::lines );

use vars qw($VERSION);
$VERSION = '1.6';

# Bezier smoothed plottype
# http://homepages.borland.com/efg2lab/Graphics/Jean-YvesQueinecBezierCurves.htm - description of bezier curves

sub smoothFactor {
	$_[0]->{_smoothFactor} = $_[1] if ( defined $_[1] );
	return exists $_[0]->{_smoothFactor} ? $_[0]->{_smoothFactor} : 0.75;
}
sub bezierCurvePoints {
	$_[0]->{_bezierCurvePoints} = $_[1] if ( defined $_[1] );
	return exists $_[0]->{_bezierCurvePoints} ? $_[0]->{_bezierCurvePoints} : 50;
}

sub _mid
{
	my $self = shift;
	my ( $p1, $p2 ) = @_;
	return ( $p1 + $p2 ) / 2;
}
sub _mirror
{
	my $self = shift;
	my ( $p1, $p2, $factor ) = @_;
	$factor = 1 unless ( defined $factor );
	return $p2 + $factor * ( $p2 - $p1 );
}
sub _controlPoint
{
	my $self = shift;
	my ( $p1, $p2, $p3 ) = @_;
	
	my $sa = $self->_mirror( $p1, $p2, $self->smoothFactor );
	my $sb = $self->_mid( $p2, $sa );
	
	my $m  = $self->_mid( $p2, $p3 );
	
	my $pC = $self->_mid( $sb, $m );
	
	return $pC;
}
sub _bezier
{
	my $self = shift;
	my ( $t, $p1, $p2, $p3, $p4 ) = @_;
	return ((1 - $t)**3) * $p1 +3 * ((1 - $t)**2) * $t * $p2 +3 * (1 - $t) * (($t)**2) * $p3 +(($t)**3) * $p4;
}
sub _getPoints
{
	my $self = shift;
	my ( $ds, $_dataset, $bUseValues ) = @_;
	
	my ( $x_min, $x_max );# = $self->{_data}->get_min_max_x( $ds );
	my ( $y_min, $y_max );# = $self->{_data}->get_min_max_y( $ds );
	
	for ( @$_dataset ) {
		my $x = $_->{x};
		my $y = $_->{y};
		
		$x_min = $x if( ! defined $x_min || $x < $x_min );
		$y_min = $y if( ! defined $y_min || $y < $y_min );
		
		$x_max = $x if( ! defined $x_max || $x > $x_max );
		$y_max = $y if( ! defined $y_max || $y > $y_max );
	}
	
	unless ( $bUseValues ) {
		( $x_min, $y_min ) = $self->val_to_pixel( $x_min, $y_min, $ds );
		( $x_max, $y_max ) = $self->val_to_pixel( $x_max, $y_max, $ds );
	}
	
	my @plotarea = ();
	
	my $rightEdge = 0;
	
	my $_count = scalar( @$_dataset );
	for my $index ( 0 .. ( $_count - 1 ) )
	{
		my $p0 = $index < 1 ? undef : $_dataset->[ $index - 1 ];
		my $p1 = $_dataset->[ $index ];
		my $p2 = $_dataset->[ $index + 1 ];
		my $p3 = $_dataset->[ $index + 2 ];
		
		if ( ! defined $p0 && defined $p1 && defined $p2 ) {
			$p0->{x} = $p1->{x} - abs( $p2->{x} - $p1->{x} );
			$p0->{y} = $p1->{y};
		}
		elsif ( ! defined $p3 && defined $p2 && defined $p1 ) {
			$p3->{x} = $p2->{x} + abs( $p2->{x} - $p1->{x} );
			$p3->{y} = $p2->{y};
		} else {
			if ( ! defined $p2 ) {
				$p2 = { x => $p1->{x} + abs( $p1->{x} - $p0->{x} ), y => $p1->{y} };
			}
			if ( ! defined $p3 ) {
				$p3 = { x => $p1->{x} + 2 * abs( $p1->{x} - $p0->{x} ), y => $p1->{y} };
			}
		}
		
		my $pC1 = {};
		my $pC2 = {};
		
		$pC1->{x} = $self->_controlPoint( $p0->{x}, $p1->{x}, $p2->{x} );
		$pC1->{y} = $self->_controlPoint( $p0->{y}, $p1->{y}, $p2->{y} );
		$pC2->{x} = $self->_controlPoint( $p3->{x}, $p2->{x}, $p1->{x} );
		$pC2->{y} = $self->_controlPoint( $p3->{y}, $p2->{y}, $p1->{y} );
		
		$rightEdge = 0;
		for ( my $t = 0; $t <= 1; $t = $t +1 / $self->bezierCurvePoints ) {
			my $b = {};
			
			$b->{x} = $self->_bezier( $t, $p1->{x}, $pC1->{x}, $pC2->{x}, $p2->{x} );
			$b->{y} = $self->_bezier( $t, $p1->{y}, $pC1->{y}, $pC2->{y}, $p2->{y} );
			
			if (
				$b->{x} >= $x_min && $b->{x} <= $x_max 
			#	&& 
			#	$b->{y} >= $y_min && $b->{y} <= $y_max
			) {
				$rightEdge = $rightEdge >= $b->{x} ? $rightEdge : $b->{x};
				push( @plotarea, { x => $b->{x} , y => $b->{y} } );
			}
		}
		
		$index++;
	}
	
	return \@plotarea;
}

sub draw_data_set
{
	my $self = shift;
	my $ds = shift;
	
	my @values = $self->{_data}->y_values($ds) or
		return $self->_set_error(
			"Impossible illegal data set: $ds",
			$self->{_data}->error
		)
	;
	
	my $dsci = $self->set_clr($self->pick_data_clr($ds) );
	my $type = $self->pick_line_type($ds);
	
	my ($xb, $yb);
	
	my @_points = ();
	
	for (my $i = 0; $i < @values; $i++)
	{
		if (!defined $values[$i])
		{
			($xb, $yb) = () if $self->{skip_undef};
			next;
		}
		
		my ($xe, $ye);
		
		if (defined($self->{x_min_value}) && defined($self->{x_max_value}))
		{
			($xe, $ye) = ( $self->{_data}->get_x($i), $values[$i] );
		}
		else
		{
			($xe, $ye) = ( $i+1, $values[$i] );
		}
		
		if (defined $xb)
		{
			my @asd = ( $xb, $yb );
			push @_points, { x => $asd[0], y => $asd[1] };
			
			# TODO: is this correct?!
			$self->{_hotspots}->[$ds]->[$i] = ['line', $xb, $yb, $xe, $ye, $self->{line_width}];
		}
		($xb, $yb) = ($xe, $ye);
	}
	
	my @asd = ( $xb, $yb );
	push @_points, { x => $asd[0], y => $asd[1] };
	
	if ( scalar( @_points ) > 2 ) {
		@_points = @{ $self->_getPoints( $ds, \@_points, 1 ) };
	}
	
	my $asd = shift @_points;
	( $xb, $yb ) = $self->val_to_pixel( $asd->{x}, $asd->{y} );
	for $asd ( @_points ) {
		my ( $xe, $ye ) = $self->val_to_pixel( $asd->{x}, $asd->{y} );
		$self->draw_line( $xb, $yb, $xe, $ye, $type, $dsci ) if defined $dsci;
		($xb, $yb) = ($xe, $ye);
	}
	
	return $ds;
}

1;

__END__

=head1 NAME

 GD::Graph::smoothlines

=head1 SYNOPSIS

=head1 DESCRIPTION

 This package is used for creation a smooth line chart.

=head1 EXAMPLES

 use GD::Graph::smoothlines;
 
 my $graph = GD::Graph::smoothlines->new();

=head1 MODULE STRUCTURE

=head1 METHODS

 Available public methods

=over 4

=item proto int smoothFactor ( [ int $number ] )

=item proto int bezierCurvePoints ( [ int $number ] )

=back

=head1 SEE ALSO

 GD::Graph

=head1 COPYRIGHT

 Copyright (c) 2007 Andrei Kozovski

=head1 AUTHORS

 This release was made by Andrei Kozovski

=cut
