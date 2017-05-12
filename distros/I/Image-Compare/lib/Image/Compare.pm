# Image::Compare, a module based on the great Imager, used to determine if
# two images differ greatly from one another.

package Image::Compare;

use strict;
use warnings;

use Imager;

# This is the base class for all comparators, and will also do the work of
# loading all supplied implementations.
use Image::Compare::Comparator;

our %class_map;

my $loaded_lwp;

BEGIN {
	$loaded_lwp = 0;
	eval "require LWP;";
	unless ($@) { $loaded_lwp = 1; }
}

our $VERSION = "1.03";

# If people don't want to deal with OO, we export the main "work" method
# so they can call it in a simpler way.  We'll see below where we handle this.
use base qw/Exporter/;
our @EXPORT_OK = qw/compare/;

##   Public methods begin here

# The constructor method.
# Takes a hash of arguments:  (all are optional)
#   image1 =>
#     Data representing the first image, either as an Imager object, file
#     name or a URL.
#   type1  => Type of image provided.
#   image2 => Like image1.
#   type2  => Like type1.
#   method =>
#     Either the numeric constant representing the comparator, or an
#     instance of a comparator.
#   args  => Arguments to pass to the comparator.
# See the documentation on the relevant option setters for more details
sub new {
	my $proto = shift;
	my %args = @_;
	my $class = ref($proto) || $proto;  # Bite me, Randal.
	my $self = {};
	bless($self, $class);
	# These are default values
	if ($args{image1}) {
		$self->set_image1(
			img  => $args{image1},
			type => $args{type1}
		);
	}
	if ($args{image2}) {
		$self->set_image2(
			img  => $args{image2},
			type => $args{type2}
		);
	}
	if ($args{method}) {
		$self->set_method(
			method => $args{method},
			args => $args{args}
		);
	}
	if ($args{mask}) {
		$self->set_mask(mask => $args{mask});
	}
	return $self;
}

# The next two just use the input to fetch image data and store it as an
# Imager object.  Currently supported image types:
#   Imager object
#   File name
#   URL
sub set_image1 {
	my $self = shift;
	my %args = @_;
	$self->{_IMG1} = _get_image($args{img}, $args{type});
}

sub set_image2 {
	my $self = shift;
	my %args = @_;
	$self->{_IMG2} = _get_image($args{img}, $args{type});
}

# Get back the Imager objects created by the preceding two methods.
sub get_image1 {
	my $self = shift;
	return $self->{_IMG1};
}
sub get_image2 {
	my $self = shift;
	return $self->{_IMG2};
}

# How to set the matching mask parameter for this compaison instance.
sub set_mask {
	my $self = shift;
	my %args = @_;
	$self->{_MASK} = $args{mask};
}
sub get_mask {
	my $self = shift;
	return $self->{_MASK};
}

# Given input as defined above, returns an Imager object representing the
# image.
sub _get_image {
	my($img, $type) = @_;
	unless ($img) {
		die "Missing 'img' parameter";
	}

	# If we've been given an Imager object, we need only store it.
	if (ref($img)) {
		if ($img->isa('Imager')) {
			return $img;
		}
		# If it wasn't an Imager, but it's still some kind of reference, then
		# we have to give up.
		die "Unrecognized input type: '" . ref($img) . "'";
	}

	# Otherwse, we need to construct an Imager object, and to do that, we
	# need to build up an arguments hash for the Imager constructor.
	my %args;
	if ($type) {
		# Provide the type argument to image, if it was provided.
		$args{type} = $type;
	}
	# This is the base error message.
	my $errmsg = "Unable to read image data from ";
	# If $img looks like a URL, and if we were able to load LWP, then we might
	# be able to fetch an image via a URL.
	if ($loaded_lwp && ($img =~ /^https?:\/\//)) {
		$errmsg .= "URL '$img'";
		my $ua = LWP::UserAgent->new();
		$ua->agent("Image::Compare/v$VERSION ");
		my $res = $ua->request(HTTP::Request->new(GET => $img));
		$args{data} = $res->content();
		if (!$type) {
			$args{type} = $res->content_type();
			$args{type} =~ s!^image/!!;
		}
	}
	else {
		# Otherwise, we have to think it's a file path.
		$errmsg .= "file '$img'";
		$args{file} = $img;
	}
	my $newimg = Imager->new();
	$newimg->read(%args) || die($errmsg . ": '" . $newimg->{ERRSTR} . "'");
	return $newimg;
}

# Sets the comparison method.  Either takes the numeric constant that
# identifies the method and any arguments needed by the method, or an instance
# of the comparator.  See the documentation for Image::Compare::Comparator or
# it subclasses for more details.
sub set_method {
	my $self = shift;
	my %args = @_;
	unless ($args{method}) {
		die "Missing required argument 'method'";
	}
	if (ref($args{method})) {
		if ($args{method}->isa('Image::Compare::Comparator')) {
			$self->{_CMP} = $args{method};
		}
		else {
			die (
				"Unrecognized type for 'method' argument: '" .
				ref($args{method}) . "'"
			);
		}
	}
	else {
		unless ($class_map{$args{method}}) {
			die "Unrecognized method identifier: '$args{method}'";
		}
		$self->{_CMP} = $class_map{$args{method}}->new($args{args});
	}
}

# Returns information describing the comparison method set into this instance
# of an Image::Compare.
sub get_method {
	my $self = shift;
	unless ($self->{_CMP}) {
		return wantarray ? () : undef;
	}
	return $self->{_CMP}->get_representation();
}

# Compares two images and returns a result.
sub compare {
	my $self;
	# This can be called as an instance method
	if (ref($_[0]) eq 'Image::Compare') {
		$self = shift;
	}
	else {
		# Or, as a class method, if you swing that way...
		if ($_[0] eq 'Image::Compare') {
			shift;
		}
		# Or just as a plain method.  In either case, we just need to construct
		# a $self so we can get on with life.
		$self = Image::Compare->new(@_);
	}
	# Sanity checking
	for my $ref (
		['IMG1', 'Image 1'], ['IMG2', 'Image 2'], ['CMP', 'Comparison method'],
	) {
		die "$ref->[1] not specified" unless $self->{"_$ref->[0]"};
	}

	# Give the images to the comparator and let them compare them.
	# The comparator will raise an exception if anything's wrong.
	return $self->{_CMP}->compare_images(
		@{$self}{qw/_IMG1 _IMG2 _MASK/}
	);
}

1;

__END__

=head1 NAME

Image::Compare - Compare two images in a variety of ways.

=head1 USAGE

 use Image::Compare;
 use warnings;
 use strict;

 my($cmp) = Image::Compare->new();
 $cmp->set_image1(
     img  => '/path/to/some/file.jpg',
     type => 'jpg',
 );
 $cmp->set_image2(
     img  => 'http://somesite.com/someimage.gif',
 );
 $cmp->set_method(
     method => &Image::Compare::THRESHOLD,
     args   => 25,
 );
 if ($cmp->compare()) {
     # The images are the same, within the threshold
 }
 else {
     # The images differ beyond the threshold
 }

=head1 OVERVIEW

This library implements a system by which 2 image files can be compared,
using a variety of comparison methods.  In general, those methods operate
on the images on a pixel-by-pixel basis and reporting statistics or data
based on color value comparisons.

C<Image::Compare> makes heavy use of the C<Imager> module, although it's not
neccessary to know anything about it in order to make use of the compare
functions.  However, C<Imager> must be installed in order to use this
module, and file import types will be limited to those supported by your
installed C<Imager> library.

In general, to do a comparison, you need to provide 3 pieces of information:
the first image to compare, the second image to compare, and a comparison
method.  Some comparison methods also require extra arguments -- in some cases
a boolean value, some a number and some require a hash reference with
structured data.  See the documentation below for information on how to use
each comparison method.

C<Image::Compare> provides 3 different ways to invoke its comparison
functionality -- you can construct an C<Image::Compare> object and call
C<set_*> methods on it to give it the information, then call C<compare()> on
that object, or you can construct the Image::Compare with all of the
appropriate data right off the bat, or you can simply call C<compare()>
with all of the information.  In this third case, you can call C<compare()>
as a class method, or you can simply invoke the method directly from the
C<Image::Compare> namespace.  If you'd like, you can also pass the word
C<compare> to the module when you C<use> it and the method will be
imported to your local namespace.

=head1 COMPARISON METHODS

=over 4

=item EXACT

The EXACT method simply returns true if every single pixel of one image
is exactly the same as every corresponding pixel in the other image, or false
otherwise.  It takes no arguments.

 $cmp->set_method(
     method => &Image::Compare::EXACT,
 );

=item THRESHOLD

The THRESHOLD method returns true if no pixel difference between the two images
exceeds a certain threshold, and false if even one does.  Note that differences
are measured in a sum of squares fashion (vector distance), so the maximum
difference is C<255 * sqrt(3)>, or roughly 441.7.  Its argument is the
difference threshold.  (Note:  EXACT is the same as THRESHOLD with an
argument of 0.)

 $cmp->set_method(
     method => &Image::Compare::THRESHOLD,
     args   => 50,
 );

=item THRESHOLD_COUNT

The THRESHOLD_COUNT method works similarly to the THRESHOLD method, but instead
of immediately returning a false value as soon as it finds a pixel pair whose
difference exceeds the threshold, it simply counts the number of pixels pairs
that exceed that threshold in the image pair. It returns that count.

 $cmp->set_method(
     method => &Image::Compare::THRESHOLD_COUNT,
     args   => 50,
 );

=item AVG_THRESHOLD

The AVG_THRESHOLD method returns true if the average difference over all pixel
pairings between the two images is under a given threshold value.  Two
different average types are available: MEDIAN and MEAN.  Its argument is a
hash reference, contains keys "type", indicating the average type, and
"value", indicating the threshold value.

 $cmp->set_method(
     method => &Image::Compare::AVG_THRESHOLD,
     args   => {
         type  => &Image::Compare::AVG_THRESHOLD::MEAN,
         value => 35,
     },
 );

=item IMAGE

The IMAGE method returns an C<Imager> object of the same dimensions as your
input images, with each pixel colored to represent the pixel color difference
between the corresponding pixels in the input.

Its only argument accepts 0, 1, or an L<Imager::Fountain>.  If the
argument is omitted or false, then the output image will be grayscale,
with black meaning no change and white meaning maximum change.  If the
argument is a true value other than an L<Imager::Fountain>, the output
will be in color, ramping from pure red at 0 change to pure green at
50% of maximum change, and then to pure blue at maximum change.

 $cmp->set_method(
     method => &Image::Compare::IMAGE,
     args   => 1,   # Output in color
 );

You may also pass an L<Imager::Fountain> to choose your own color scale.

 use Imager qw/:handy/; # for the NC subroutine
 use Imager::Fountain;

 $cmp->set_method(
     method => &Image::Compare::IMAGE,
     args   => Imager::Fountain->simple(
         positions => [              0.0,            1.0],
         colors    => [NC(255, 255, 255), NC(240,18,190)]
     )     # scale from white (no change) to fuschia (100% change)
 );

=back

=head1 MATCHMASKS

In addition to providing the two images which are to be compared, you may
also provide a "mask" image which will define a subset of those images to
compare.  A mask must be an Imager object, with one channel and 8 bit color
depth per channel.  Image processing will not occur for any pixel in the
test images which correspond to any pixel in the mask image with a color
value of (255, 255, 255), that is, black.

Put another way, the pure black section of the mask image effectively "hide"
that section of the test images, and those pixels will be ignored during
processing.  What that means will differ from comparator to comparator, but
should be obviously predictable in nature.

=head1 METHODS

=over 4

=item new()

=item new(image1 => { .. }, image2 => { .. }, method => { .. }, ..)

This is the constructor method for the class.  You may optionally pass it
any of 3 arguments, each of which takes a hash reference as data, which
corresponds exactly to the semantics of the C<set_*> methods, as described
below.  You may optionally pass in a match mask argument using the "mask"
argument, which must be an Imager object, as described above.

=item $cmp->set_image1(img => $data, type => $type)
=item $cmp->set_image2(img => $data, type => $type)

Sets the data for the appropriate image based on the input parameters.
The C<img> parameter can either be an C<Imager> object, a file path or a URL.
If a URL, it must be of a scheme supported by your C<LWP> install.  The C<type>
argument is optional, and will be used to override the image type deduced
from the input.  Again, the image type used must be one supported by your
C<Imager> install, and its format is determined entirely by C<Imager>.  See
the documentation on C<Imager::Files> for a list of image types.

Note that providing images as URLs requires that both LWP and Regexp::Common
be available in your kit.

=item $cmp->get_image1()
=item $cmp->get_image2()

Returns the underlying Imager object for the appropriate image, as created
inside of $cmp by either of the previous two methods.

=item $cmp->set_method(method => $method, args => $args)

Sets the comparison method for the object.  See the section above for details
on different comparison methods.

=item $cmp->get_method()

Returns a hash describing the method as set by the call previous.  In this
hash, the key "method" will map to the method, and the key "args" will map
to the arguments (if any).

=item $cmp->set_mask(mask => $mask)

Sets the match mask parameter as described above.

=item $cmp->get_mask()

Returns the match mask (if any) currently set in this object.

=item $cmp->compare()

=item compare(image1 => { .. }, image2 => { .. }, method => { .. })

Actually does the comparison.  The return value is determined by the comparison
method described in the previous section, so look there to see the details.
As described above, this can be called as an instance method, in which case
the values set at construction time or through the C<set_*> methods will be
used, or it can be called as a class method or as a simple subroutine.

In the latter case, all of the information must be provided as arguments to
the function call.  Those argument have exactly the same semantics as the
arguments for C<new()>, so see that section for details.

=back

=head1 Future Work

=over 4

=item *

I would like to implement more comparison methods.  I will have to use the
module myself somewhat before I know which ones would be useful to add, so
I'm releasing this initial version now with a limited set of comparisons.

I also more than welcome suggestions from users as to comparison methods
they would find useful, so please let me know if there's anything you'd like to
see the module be able to do.  This module is meant more to be a framework
for image comparison and a collection of systems working within that
framework, so the process of adding new comparison methods is reasonably
simple and painless.

=item *

I bet the input processing could be more bulletproof.  I am pretty certain of
it, in fact.

=item *

Maybe I could be more lenient with the format for masks.  I'll leave it up
to user request to see how I could extend that interface.

=back

=head1 Known Issues

=over 4

=item *

None at this time.

=back

=head1 AUTHOR

Avi Finkel <F<avi@finkel.org>>

=head1 LICENSE AND COPYRIGHT

Copyright 2008 Avi Finkel <F<avi@finkel.org>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut
