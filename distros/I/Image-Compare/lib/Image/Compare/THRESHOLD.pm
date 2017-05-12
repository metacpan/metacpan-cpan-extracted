package Image::Compare::THRESHOLD;

use warnings;
use strict;

use base qw/Image::Compare::Comparator/;

sub setup {
	my $self = shift;
	$self->SUPER::setup(@_);
	# Default to true, we will return 0 if we run into trouble later.
	$self->{result} = 1;
}

sub accumulate {
	my $self = shift;
	my $diff = $self->color_distance(@_);
	if ($diff > $self->{args}) {
		$self->{result} = 0;
		return 1;
	}
	return undef;
}

sub get_result {
	my $self = shift;
	return $self->{result};
}

1;

__END__

=head1 NAME

Image::Compare::THRESHOLD - Compare two images by by a maximum per-pixel
color difference of their pixels.

=head1 OVERVIEW

See the docs for L<Image::Compare> for details on how to use this
module.  Further documentation is meant for those modifying or subclassing
this comparator.  See the documentation in L<Image::Compare::Comparator> for
general information about making your own comparator subclasses.

=head1 METHODS

=over 4

=item setup()

Initializes the return value.

=item accumulate(\@pixel1, \@pixel2, $x, $y)

This method is called for each pixel in the two images to be compared.  If
the two pixels' colors are within the threshold in color difference, then
the method allows processing to continue.  Otherwise, this returns a false
value, causing processing to cease and indicating that the two images do
not match.

=item $cmp->get_result()

If this method has been called, it means that accumulate() never
short-circuited and therefore none of the pixels in the two images
differ by more than the threshold, so this always returns a true value.

=back

=head1 AUTHOR

Copyright 2008 Avi Finkel <F<avi@finkel.org>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
