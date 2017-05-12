package Math::Geometry::Construction::Circle;
use Moose;

use 5.008008;

use Math::Geometry::Construction::Point;
use Math::Geometry::Construction::Types qw(Point);
use Carp;
use List::Util qw(max);

use overload 'x'    => '_intersect',
#             '.'    => '_point_on',
             'bool' => sub { return 1 };

=head1 NAME

C<Math::Geometry::Construction::Circle> - circle by center and point

=head1 VERSION

Version 0.024

=cut

our $VERSION = '0.024';


###########################################################################
#                                                                         #
#                      Class Variables and Methods                        # 
#                                                                         #
###########################################################################

our $ID_TEMPLATE = 'C%09d';

sub id_template { return $ID_TEMPLATE }

###########################################################################
#                                                                         #
#                               Accessors                                 # 
#                                                                         #
###########################################################################

with 'Math::Geometry::Construction::Role::Object';
with 'Math::Geometry::Construction::Role::PositionSelection';
with 'Math::Geometry::Construction::Role::Output';
with 'Math::Geometry::Construction::Role::PointSet';
with 'Math::Geometry::Construction::Role::Input';

has 'center'        => (isa      => Point,
			is       => 'ro',
			required => 1);

has 'support'       => (isa      => Point,
			is       => 'ro',
			required => 1);

has '_fixed_radius' => (isa      => 'Num',
			is       => 'rw',
			init_arg => 'radius',
			trigger  => \&_fixed_radius_trigger);

has 'partial_draw'  => (isa      => 'Bool',
			is       => 'rw',
			builder  => '_build_partial_draw',
			lazy     => 1);

has 'min_gap'       => (isa      => 'Num',
			is       => 'rw',
			builder  => '_build_min_gap',
			lazy     => 1);

sub BUILDARGS {
    my ($class, %args) = @_;
    
    # implicitly checks $args{construction}
    $args{center} = $class->import_point($args{construction},
					 $args{center});

    if(exists($args{support})) {
	if(exists($args{radius})) {
	    warn sprintf("Ignoring ircle init parameter radius.\n");
	    delete $args{radius};
	}

	$args{support} = $class->import_point($args{construction},
					      $args{support});
    }
    elsif(exists($args{radius})) {
	$args{support} = $args{construction}->add_derived_point
	    ('TranslatedPoint',
	     {input      => [$args{center}],
	      translator => [$args{radius}, 0]},
	     {hidden     => 1});
    }
    
    return \%args;
}

sub BUILD {
    my ($self, $args) = @_;

    $self->style('stroke', 'black') unless($self->style('stroke'));
    $self->style('fill',   'none')  unless($self->style('fill'));

    # The following call also makes sure that the support has been
    # set or can be built.
    $self->register_point($self->support);
}

sub _build_partial_draw {
    my ($self) = @_;

    return $self->construction->partial_circles;
}

sub _build_min_gap {
    my ($self) = @_;

    return $self->construction->min_circle_gap;
}

sub _fixed_radius_trigger {
    my ($self, $new, $old) = @_;

    if(@_ > 2) {
	# change of value, not init
	$self->support->derivate->translator([$new, 0]);
    }
}

###########################################################################
#                                                                         #
#                             Retrieve Data                               #
#                                                                         #
###########################################################################

sub positions {
    my ($self) = @_;

    return map { $_->position } $self->points;
}

sub radius {
    my ($self, @args) = @_;

    if(@args) {
	if(defined($self->_fixed_radius)) {
	    $self->_fixed_radius($args[0]);
	}
	else {
	    croak sprintf('Refusing to set radius on circle %s without '.
			  'fixed radius', $self->id);
	}
    }

    my $center_p  = $self->center->position;
    my $support_p = $self->support->position;

    return if(!$center_p or !$support_p);
    return(abs($support_p - $center_p));
}

sub _calculate_boundary_positions {
    my ($self, %args) = @_;

    my @positions = grep { defined($_) } $self->positions;
    return([undef, undef], [undef, undef]) if(@positions < 2);

    # sort positions around the circle; note that @sorted_positions
    # contains arrayrefs with position and angle
    my $center_position = $self->center->position; # known to be def
    my @rich_positions  = ();
    foreach(@positions) {
	my $relative = $_ - $center_position;
	my $angle    = atan2($relative->[1], $relative->[0]);
	$angle += 6.28318530717959 if($angle < 0);
	push(@rich_positions, [$_, $angle]);
    }
    my @sorted_positions = sort { $a->[1] <=> $b->[1] } @rich_positions;

    my $n   = @sorted_positions;
    my @max = (undef, undef);
    for(my $i=0;$i<$n;$i++) {
	my $diff;
	if($i + 1 < $n) {
	    $diff = $sorted_positions[$i + 1]->[1]
		- $sorted_positions[$i]->[1];
	}
	else {
	    $diff = $sorted_positions[0]->[1] + 6.28318530717959
		- $sorted_positions[$i]->[1];
	}
	@max = ($i, $diff) if(!defined($max[1]) or $diff > $max[1]);
    }

    my $extend = $self->extend;
    my $radius = $self->radius;  # known to be non-zero

    # if the gap is two small we return nothing
    if($max[1] - ($extend->[0] + $extend->[1]) / $radius
       < $self->min_gap)
    {
	return([undef, undef], [undef, undef]);
    }

    # calculate the boundary positions; note that the order needs to
    # be reversed because we now deal with the part that needs to be
    # drawn, not the gap
    my @boundary_positions = ();
    my $j                  = $max[0];
    my $i                  = ($j + 1) % $n;
    if($extend->[0] == 0) {
	push(@boundary_positions, $sorted_positions[$i]->[0]);
    }
    else {
	my $phi      = $sorted_positions[$i]->[1] - $extend->[0] / $radius;
	my $boundary = $center_position +
	    [$radius * cos($phi), $radius * sin($phi)];
	push(@boundary_positions, $boundary);
    }
    if($extend->[1] == 0) {
	push(@boundary_positions, $sorted_positions[$j]->[0]);
    }
    else {
	my $phi      = $sorted_positions[$j]->[1] + $extend->[1] / $radius;
	my $boundary = $center_position +
	    [$radius * cos($phi), $radius * sin($phi)];
	push(@boundary_positions, $boundary);
    }

    return @boundary_positions;
}

sub draw {
    my ($self, %args) = @_;
    return undef if $self->hidden;

    my $center_position  = $self->center->position;
    my $support_position = $self->support->position;

    if(!$center_position) {
	warn sprintf("Undefined center of circle %s, ".
		     "nothing to draw.\n", $self->id);
	return undef;
    }
    if(!$support_position) {
	warn sprintf("Undefined support of circle %s, ".
		     "nothing to draw.\n", $self->id);
	return undef;
    }

    my $radius = $self->radius;
    if(!$radius) {
	warn sprintf("Radius of circle %s vanishes, ".
		     "nothing to draw.\n", $self->id);
	return undef;
    }

    my @boundary_positions = $self->partial_draw
	? $self->_calculate_boundary_positions(%args)
	: ([undef, undef], [undef, undef]);

    # currently, we just draw the full circle
    $self->construction->draw_circle
	(cx    => $center_position->[0],
	 cy    => $center_position->[1],
	 r     => $radius,
	 x1    => $boundary_positions[0]->[0],
	 y1    => $boundary_positions[0]->[1],
	 x2    => $boundary_positions[1]->[0],
	 y2    => $boundary_positions[1]->[1],
	 style => $self->style_hash,
	 id    => $self->id);

    $self->draw_label('x' => $support_position->[0],
		      'y' => $support_position->[1]);
}

###########################################################################
#                                                                         #
#                              Overloading                                # 
#                                                                         #
###########################################################################

sub _intersect {
    my ($self, $intersector) = @_;
    my $class;
	 
    $class = 'Math::Geometry::Construction::Circle';
    if(eval { $intersector->isa($class) }) {
	return $self->construction->add_derived_point
	    ('IntersectionCircleCircle', {input => [$self, $intersector]});
    }

    $class = 'Math::Geometry::Construction::Line';
    if(eval { $intersector->isa($class) }) {
	return $self->construction->add_derived_point
	    ('IntersectionCircleLine', {input => [$self, $intersector]});
    }
}

1;


__END__

=pod

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 INTERFACE

=head2 Public Attributes

=head2 Methods for Users

=head2 radius

=head2 Methods for Subclass Developers

=head3 as_svg

=head3 id_template


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011-2013 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
