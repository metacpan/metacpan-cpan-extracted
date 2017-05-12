# Comparator for the "average threshold" comparison method.

package Image::Compare::AVG_THRESHOLD;

use warnings;
use strict;

use constant MEAN => 0;
use constant MEDIAN => 1;

use base qw/Image::Compare::Comparator/;

sub accumulate {
	my $self = shift;
	my $diff = $self->color_distance(@_);
	if ($self->{args}{type} == &MEAN) {
		$self->{count}++;
		$self->{sum} += $diff;
	}
	elsif ($self->{args}{type} == &MEDIAN) {
		push(@{$self->{scores}}, $diff);
	}
	else {
		die "Unrecognized average type: '$self->{args}{type}'";
	}
	return undef;
}

sub get_result {
	my $self = shift;
	my $val = 0;
	if ($self->{args}{type} == &MEAN) {
		$val = $self->{sum} / $self->{count};
	}
	elsif ($self->{args}{type} == &MEDIAN) {
		my @vals = sort @{$self->{scores}};
		if (@vals % 2) {
			# Return the middle value
			$val = $vals[(@vals / 2)];
		}
		else {
			# Return the mean of the middle two values
			$val  = $vals[ @vals / 2     ];
			$val += $vals[(@vals / 2) - 1];
			$val /= 2;
		}
	}
	return $val <= $self->{args}{value};
}

1;

__END__

=head1 NAME

Image::Compare::AVG_THRESHOLD - Compare two images by the overall average
color difference of their pixels.

=head1 OVERVIEW

See the docs for L<Image::Compare> for details on how to use this
module.  Further documentation is meant for those modifying or subclassing
this comparator.  See the documentation in L<Image::Compare::Comparator> for
general information about making your own comparator subclasses.

=head1 METHODS

=over 4

=item accumulate(\@pixel1, \@pixel2, $x, $y)

This method is called for each pixel in the two images to be compared.  The
difference between each pair of pictures is collected and stored for later use
by get_result().  This method never short-circuits; when this comparator is
used, all pixels are compared, every time.

=item $cmp->get_result()

Returns either the median or the arithmetic mean of the values collected
by accumulate(), depending on the average type provided when this object
was constructed.

=back

=head1 AUTHOR

Copyright 2008 Avi Finkel <F<avi@finkel.org>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
