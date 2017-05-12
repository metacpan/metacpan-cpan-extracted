package Image::Compare::EXACT;

use warnings;
use strict;

use base qw/Image::Compare::THRESHOLD/;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = Image::Compare::THRESHOLD->new(@_);
	$self->{args} = 0;
	bless($self, $class);
	return $self;
}

1;

__END__

=head1 NAME

Image::Compare::EXACT - Compare two images for exact equivalence.

=head1 OVERVIEW

See the docs for L<Image::Compare> for details on how to use this
module.  Further documentation is meant for those modifying or subclassing
this comparator.  See the documentation in L<Image::Compare::Comparator> for
general information about making your own comparator subclasses.

=head1 METHODS

=over 4

=item new(\@pixel1, \@pixel2, $x, $y)

Override's L<Image::Compare:THRESHOLD>'s constructor and forces the
threshold to be 0.  Otherwise, this comparator is exactly the same as
that.

=back

=head1 AUTHOR

Copyright 2008 Avi Finkel <F<avi@finkel.org>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
