package Image::Compare::Comparator;

use warnings;
use strict;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{args} = shift;
	$self->{mask} = shift;
	bless($self, $class);
	return $self;
}

# This will do initial setup and throw an exception if there is something
# wrong.  We have some common behavior in here.  Subclasses may override this,
# or add to it.
sub setup {
	my $self = shift;
	my ($img1, $img2, $mask) = @_;
	unless (
		($img1->getwidth()  == $img2->getwidth() ) &&
		($img1->getheight() == $img2->getheight())
	) {
		die "Images must be the same size!";
	}
	if ($mask) {
		unless(ref($mask) && $mask->isa('Imager')) {
			die "Match mask must be an Imager image object!";
		}
		unless (
			($mask->getchannels() == 1) &&
			($mask->bits()     == 8)
		) {
			die "Match mask image must have one channel and 8 bits per channel!";
		}
		unless (
			($mask->getwidth()  == $img1->getwidth() ) &&
			($mask->getheight() == $img1->getheight())
		) {
			die "Match mask must be the same size as the test images!";
		}
	}
}

sub get_args {
	my $self = shift;
	return $self->{args};
}

# By default, just return the class name and the arguments.
sub get_representation {
	my $self = shift;
	return (
		method => $Image::Compare::reverse_class_map{ref($self)},
		args => $self->{args},
	);
}

sub compare_images {
	my $self = shift;
	my ($img1, $img2, $mask) = @_;
	# This will die if there's a problem.
	$self->setup($img1, $img2, $mask);
	# We spin over each pixel in img1.
	my $wid = $img1->getwidth();
	my $hig = $img1->getheight();
	OUTER: for my $x (0 .. $wid - 1) {
		for my $y (0 .. $hig - 1) {
			# If we've been given a match mask, then we skip any pixel whose
			# corresponding pixel in that mask is pure black.
			# This is the entirety of the comparison logic surrounding masks.  It is
			# all so simple, I should have done it long ago.
			if ($mask && (($mask->getpixel(x => $x, y => $y)->rgba())[0] == 255)) {
				next;
			}
			my @pix1 = $img1->getpixel(x => $x, y => $y)->rgba();
			my @pix2 = $self->get_second_pixel($img2, $x, $y)->rgba();
			# If this returns undef, then we keep going.  Otherwise, we stop.
			# It will die if there's an error.
			# This mechanism allows the subclass to short-circuit image examination
			# if it feels the need to do so.
			last OUTER if defined $self->accumulate(\@pix1, \@pix2, $x, $y);
		}
	}
	# And finally, the subclass will return the thing it wants to return.
	return $self->get_result();
}

# By default, this is pretty boring.
# Subclasses may want to override it though.
# On second thought, I can't think of a reason why they would want to.
# I guess I will leave this in anyways.
sub get_second_pixel {
	my $self = shift;
	my ($img2, $x, $y) = @_;
	return $img2->getpixel(x => $x, y => $y);
}

# Some day we might have multiple ways to do this.
sub color_distance {
	my $self = shift;
	my ($pix1, $pix2) = @_;
	# The sum of the squaws of the other two hides...
	return sqrt(
		( ($pix1->[0] - $pix2->[0]) ** 2 ) +
		( ($pix1->[1] - $pix2->[1]) ** 2 ) +
		( ($pix1->[2] - $pix2->[2]) ** 2 )
	);
}

sub accumulate {
	my $self = shift;
	my $class = ref($self) || $self;
	die "Subclass '$class' must implement accumulate()!";
}

sub get_result {
	my $self = shift;
	my $class = ref($self) || $self;
	die "Subclass '$class' must implement get_result()!";
}

sub import {
	my $cmp_pkg = shift;
	my %args = @_;
	unless (UNIVERSAL::isa($cmp_pkg, __PACKAGE__)) {
		die "Comparaters must subclass __PACKAGE__!";
	}
	my $name = $cmp_pkg;
	unless (
		($name =~ s/^Image::Compare:://) ||
		($name = $args{name})
	) {
		die (
			"Comparator must either be in the Image::Compare namespace, " .
			"or you must provide a method name to import."
		);
	}
	{
		no strict qw/refs/;
		# We are essentially "exporting" this for backwards compatibility.  We
		# don't really want to use constants like this any more, but we have
		# to.  Shucks.
		my $name_const = $name;
		*{"Image::Compare::$name"} = sub () { $name_const };
		$Image::Compare::class_map{$name} = $cmp_pkg;
		$Image::Compare::reverse_class_map{$cmp_pkg} = $name;
	}
}

# We will read in the list of packages to load from the documentation.
while (<Image::Compare::Comparator::DATA>) {
	if (/^=item \* L<([^>]+)>/) {
		eval "use $1";
		die "Failed loading module '$1': $@" if $@;
	}
}

close Image::Compare::Comparator::DATA;

1;

__DATA__

=pod

=head1 NAME

Image::Compare::Comparator - Base class for comparison methods used by Image::Compare

=head1 OVERVIEW

This is essentially an abstract class which defines some basic functionality
and outlines some patterns for use of subclasses which will each define a
different process for comparing two images. The documentation here is aimed
more for those wishing to write their own comparators.

=head1 COMPARATORS

See each submodule's documentation for information about how it works.

=over 4

=item * L<Image::Compare::AVG_THRESHOLD>

=item * L<Image::Compare::EXACT>

=item * L<Image::Compare::THRESHOLD>

=item * L<Image::Compare::THRESHOLD_COUNT>

=item * L<Image::Compare::IMAGE>

=back

=head1 CREATING CUSTOM COMPARATORS

=over 4

=item OVERVIEW

There are 5 methods that can be overriden by comparator subclasses, and two
that must be.  Most of the work in creating your owm comparator is in the
implementation of your comparison logic, which is out of the purview of
this document, so it will be pretty short.

=item IMPORT

It is optional to override the import() method.  If you do, you must call the
superclass import().  If your comparator is not in the Image::Compare::
namespace, then you must be sure that the superclass import() is called with
an argument called "name", containing a unique name by which the comparator
will be referred in the system.  If the comparator B<is> in the
Image::Compare:: namespace, then the name will be assumed to be the class
name, but that can be overriden using the name argument to import().  For
example:

 package My::Comparator::FOO

 use base qw/Image::Compare::Comparator/;

 sub import {
	 my $class = shift;
	 $class->SUPER::import(name => 'FOO');
	 # ... Whatever
 }

You should override import if:

=over 4

=item *

You need to do some special logic at class initialization time.

=item *

Your class isn't in the Image::Compare:: namespace and you need to provide the
comparator name.

=item *

You want to provide a different comparator name, even though your comparator
is in the Image::Compare:: namespace.

=back

=item SETUP

It is optional to override the setup() method.  If left alone, it will do some
very basic input checking.  If you have any logic which must run before each
comparison run begins, this is where you'd put it.  You should put any pre-run
sanity checking code here, and die() if there's a problem.  You need not call
the superclass version of this method if you don't want to, but you may in
order to leverage the error checking logic there.

=item ACCUMULATE

This method must be overriden and it will contain most of your subclass's
logic.  Its inputs will be:

=over 4

=item *

A reference to an array containing the red, green and blue values of a certain
pixel in the first image.

=item *

A reference to an array containing the red, green and blue values of a certain
pixel in the second image.

=item *

The X coordinate whence came the color values from the first image.  In most
cases, this will be the same as the X coordinate for the second image, but if
you've overriden get_second_pixel(), then this may not be true.

=item *

The Y coordinate whence came the color values from the first image.  The same
caveat applies here as for X.

Your logic should do whatever calculations are neccessary with this data and
store whatever information must be stored for further processing.  If you
can determine at any point that further processing is wasteful, you can return
any non-undef value from this method and processing will cease.  In the usual
case, you should simply return undef to allow processing to continue.  die()
from this method if there's a problem.

=back

=item GET_RESULT

This method will be called at the end of the comparison run, and must be
override by the subclass.  This should do any final work that needs to be
done for the comparison, and should then return whatever value should be
returned to the end user.

=item GET_SECOND_PIXEL

Overriding this method is optional.  By default, if the XxY pixel is read
from the first image then the XxY pixel is also read from the second image, and
they are then compared.  By overriding this method, one can cause the
application to compare the XxY pixel from the first image with the X'xY' pixel
from the second image.

Note: This functionality is experimental and is subject to change as its use
case becomes more clear.

=back

=head1 METHODS

=over 4

=item new

Constructs a new instance of a comparator.  Should not be overridden by
subclasses.  All this does is the basic perl OO stuff, and copies the second
argument for later usage by the subclass.

=item setup($img1, $img2)

Subclasses should override this method to do input checking of their arguments
and die if there are any problems.  By default, this method only verifies that
both images are the same dimensions.

=item accumulate(\@pixel1, \@pixel2, $x, $y)

This method will be called once for each pair of pixels in the two images.
The RGB color values for those pixels will be passed in, along with the X and
Y coordinates of those pixels.  The return value should be undef if processing
should continue; this means that the comparator has recorded what it needs to
record and sees no reason for things to stop.  If, however, the comparator has
decided at this point (for whatever reason) that further processing would not
change its answer, it can return any non-undef value, and that value will be
returned as the result of the comparison.  This short-circuiting can be very
helpful in speeding up processing for certain types of comparison.

This method must be overridden by subclasses of this class.

=item color_distance(\@pixel1, \@pixel2)

Returns the magnitude of the linear (pythagorean) distance between two pixels
in color-space.  In the future, this method may be modifiable to use
different color distance methodologies, but for now only the simplest is
available.

=item compare_images($img1, $img2)

The main entrypoint method for consumers of instances of subclasses of this
class.  This handles all the "wrapping" for comparing two images.  Generally
should not be subclassed.

=item get_args()

Returns the arguments that had been passed to this instance of this
comparator at construction.  The same as get_representation()->{args}.
Included for backwards compatibility.

=item get_representation()

Returns a hash-representation of the current comparator instance.  The
hash currently contains two keys: I<method>, which maps to a constant
which could be used to construct more instances of this comparator, and
I<args>, which maps to the arguments as described in the documentation for
get_args().

=item get_result()

If all of the images' pixels are processed without accumulate() returning
a defined value, then this method will be called and its return value will
be used as the result of the comparison.

This method must be overridden by subclasses of this class.

=item get_second_pixel()

Given the second image and the current x, y coordinates on which processing
of the first image is currently at, returns the x and y coordinates at which
to process the second image.  By default, simply returns x and y.  Subclasses
may override this method in order to change this behavior.

=back

=head1 AUTHOR

Copyright 2008 Avi Finkel <F<avi@finkel.org>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
