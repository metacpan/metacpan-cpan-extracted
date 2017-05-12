package Math::Geometry::Construction::Draw::SVG;
use Moose;
extends 'Math::Geometry::Construction::Draw';

use 5.008008;

use Carp;

=head1 NAME

C<Math::Geometry::Construction::Draw::SVG> - SVG output

=head1 VERSION

Version 0.021

=cut

our $VERSION = '0.021';


###########################################################################
#                                                                         #
#                            Generate Output                              #
#                                                                         #
###########################################################################

sub BUILD {
    my ($self, $args) = @_;

    my $bg = delete $args->{background};  # modifies given hash!
    delete $args->{transform};
    $self->_output(SVG->new(%$args));
    $self->_set_background($bg, %$args);
}

sub _set_background {
    my ($self, $color, %args) = @_;

    return if(!$color);
    if(ref($color) eq 'ARRAY' and @$color == 3) {
	$color = sprintf('rgb(%d, %d, %d)', @$color);
    }

    my $x = 0;
    my $y = 0;
    my $w = $args{width};
    my $h = $args{height};
    if($args{viewBox}) {
	my $wsp = qr/\s+|\s*\,\s*/;
	if($args{viewBox} =~ /^\s*(.*)$wsp(.*)$wsp(.*)$wsp(.*?)\s*$/) {
	    ($x, $y, $w, $h) = ($1, $2, $3, $4);
	}
	else { warn "Failed to parse viewBox attribute.\n" }
    }

    $self->output->rect('x'    => $x,
			'y'    => $y,
			width  => $w,
			height => $h,
			stroke => 'none',
			fill   => $color);

}

sub process_style {
    my ($self, $element, %style) = @_;

    while(my ($key, $value) = each(%style)) {
	if($value and ref($value) eq 'ARRAY' and @$value == 3) {
	    $style{$key} = sprintf('rgb(%d, %d, %d)', @$value);
	}
    }

    return %style;
}

sub line {
    my ($self, %args) = @_;

    $args{style} = {$self->process_style('line', %{$args{style}})}
	if($args{style});

    ($args{x1}, $args{y1}) = $self->transform_coordinates
	($args{x1}, $args{y1});
    ($args{x2}, $args{y2}) = $self->transform_coordinates
	($args{x2}, $args{y2});

    $self->output->line(%args);
}

sub circle {
    my ($self, %args) = @_;

    $args{style} = {$self->process_style('circle', %{$args{style}})}
	if($args{style});

    ($args{cx}, $args{cy}) = $self->transform_coordinates
	($args{cx}, $args{cy});
    $args{rx} = $self->transform_x_length($args{r});
    $args{ry} = $self->transform_y_length($args{r});
    delete $args{r};

    if(defined($args{x1}) and defined($args{y1}) and
       defined($args{x2}) and defined($args{y2}))
    {
	my @boundary = $self->is_flipped
	    ? ([$self->transform_coordinates($args{x2}, $args{y2})],
	       [$self->transform_coordinates($args{x1}, $args{y1})])
	    : ([$self->transform_coordinates($args{x1}, $args{y1})],
	       [$self->transform_coordinates($args{x2}, $args{y2})]);

	my @phi = map { atan2($boundary[$_]->[1] - $args{cy},
			      $boundary[$_]->[0] - $args{cx}) }
	          (0, 1);

	my $delta_phi = $phi[1] - $phi[0];
	$delta_phi += 6.28318530717959 if($delta_phi < 0);
	my $large = $delta_phi > 3.14159265358979 ? 1 : 0;

	$args{d} = sprintf('M%f %f A%f %f %d %d %f %f',
			   @{$boundary[0]},
			   $args{rx}, $args{ry},
			   $large, 1,
			   @{$boundary[1]});

	delete(@args{'cx', 'cy', 'rx', 'ry', 'x1', 'y1', 'x2', 'y2'});
	$self->output->path(%args);
    }
    else {
	delete(@args{'x1', 'y1', 'x2', 'y2'});
	$self->output->ellipse(%args);
    }
}

sub text {
    my ($self, %args) = @_;

    $args{style} = {$self->process_style('text', %{$args{style}})}
	if($args{style});

    ($args{x}, $args{y}) = $self->transform_coordinates
	($args{x}, $args{y});

    my $data = delete $args{text};
    my $text = $self->output->text(%args);
    $text->cdata($data);
}


1;


__END__

=pod

=head1 SYNOPSIS

  use Math::Geometry::Construction;

  my $construction = Math::Geometry::Construction->new;
  my $p1 = $construction->add_point('x' => 100, 'y' => 150);
  my $p2 = $construction->add_point('x' => 130, 'y' => 110);

  my $l1 = $construction->add_line(extend  => 10,
				   support => [$p1, $p2]);

  my $tikz = $construction->as_tikz(width    => 8,
                                    height   => 3,
                                    view_box => [0, 0, 800, 300],
                                    svg_mode => 1);

  print $construction->as_svg(width => 800, height => 300)->xmlify;


=head1 DESCRIPTION

This class implements the
L<Math::Geometry::Construction::Draw|Math::Geometry::Construction::Draw>
interface in order to generate C<SVG> output. It is instantiated by
the L<draw method|Math::Geometry::Construction/draw> in
C<Math::Geometry::Construction>.

The output created by this class will be an L<SVG|SVG> object. See
C<SYNOPSIS>.

Key/value pairs in the style settings of lines, circles etc. are
passed unchanged to the respective C<SVG> element.


=head1 INTERFACE

=head2 Public Attributes

=head2 Methods


=head1 SEE ALSO

=over 4

=item * L<SVG|SVG>

=item * L<http://www.w3.org/TR/SVG11/>

=back


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011, 2013 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

