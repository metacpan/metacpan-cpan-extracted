package Image::Compare::THRESHOLD_COUNT;

use warnings;
use strict;

use base qw/Image::Compare::THRESHOLD/;

sub setup {
	my $self = shift;
	$self->{count} = 0;
}

sub accumulate {
	my $self = shift;
	# The superclass returns 0 if it's over the threshold and undef otherwise.
	# Not really optimal return values, but we're kind of cheating by looking
	# at it in this context, so hey.
	if (defined($self->SUPER::accumulate(@_))) {
		$self->{count}++;
	}
	# Always continue.
	return undef;
}

sub get_result {
	my $self = shift;
	return $self->{count} || 0;
}

1;

__END__

=head1 NAME

Image::Compare::THRESHOLD_COUNT - Count the number of pixel pairs in two images
that differ by more than a given threshold.

=head1 OVERVIEW

See the docs for L<Image::Compare> for details on how to use this
module.  Further documentation is meant for those modifying or subclassing
this comparator.  See the documentation in L<Image::Compare::Comparator> for
general information about making your own comparator subclasses.

=head1 METHODS

=over 4

=item accumulate(\@pixel1, \@pixel2, $x, $y)

Calls the superclass accumulate to determine if a given pair of pixels are
within the disance threshold or not.  If they are not, increments a counter.

=item get_result()

Returns the count of pixels pairs whose difference exceeded the threshold.

=item setup($img1, $img2)

Sets up the collection variable for the count to be returned.

=back

=head1 AUTHOR

Copyright 2008 Avi Finkel <F<avi@finkel.org>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
