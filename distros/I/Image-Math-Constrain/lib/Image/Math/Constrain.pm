package Image::Math::Constrain;

=pod

=head1 NAME

Image::Math::Constrain - Scaling math used in image size constraining (such
as thumbnails)

=head1 SYNOPSIS

  use Image::Math::Constrain;
  
  # Create the math object
  my $math = Image::Math::Constrain->new(64, 48);
  
  # Get the scaling values for an arbitrary image
  my $Image = My::Image->load("myimage.jpg");
  my $scaling = $math->constrain($Image->width, $Image->height);
  die "Don't need to scale" if $scaling->{scale} == 1;
  
  # Returns the three values as a list when called in array contect
  my ($width, $height, $scale) = $math->constrain(800, 600);

  # There are lots of different ways to specify the constrain
  
  # Constrain based on width only
  $math = Image::Math::Constrain->new(100, 0);
  
  # Constrain based on height only
  $math = Image::Math::Constrain->new(0, 100);

  # Or you can provide the two values by ARRAY ref
  $math = Image::Math::Constrain->new( [ 64, 48 ] );
  
  # Constrain height and width by the same value
  $math = Image::Math::Constrain->new(100);
  
  # Various string forms to do the same thing
  $math = Image::Math::Constrain->new('constrain(800x600)');
  $math = Image::Math::Constrain->new('300x200');
  $math = Image::Math::Constrain->new('300w200h');
  $math = Image::Math::Constrain->new('100w');
  $math = Image::Math::Constrain->new('100h');
  
  # Serialises back to 'constrain(800x600)'.
  # You can use this to store the object if you wish.
  my $string = $math->as_string;

=head1 DESCRIPTION

There are a number of different modules and systems that constrain image
sizes, such as thumbnailing. Every one of these independantly implement
the same logic. That is, given a width and/or height constraint, they
check to see if the image is bigger than the constraint, and if so scale
the image down proportionally so that it fits withint the constraints.

Of course, they all do it slightly differnetly, and some do it better
than others.

C<Image::Math::Constrain> has been created specifically to implement
this logic once, and implement it properly. Any module or script that
does image size constraining or thumbnailing should probably be using
this for its math.

=head1 METHODS

=cut

use 5.005;
use strict;
use overload 'bool' => sub () { 1 },
             '""'   => 'as_string';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.02';
}





#####################################################################
# Constructor

=pod

=head2 new $width, $height

-head2 new [ $width, $height ]

=head1 new $width_and_height

=head2 new $string

The C<new> constructor takes the dimentions to which you wish to
constrain and creates a new math object.

You can feed a number of different height/width pairs to this object, and
it will returns the scaling you will need to do to shrink the image down
to the constraints, and the final width and height of the image after
scaling, at least one of which should match the constraint.

A value of zero is used to indicate that a dimension should not be
constrained. Thus, C<-E<gt>new(400, 0)> would indicate to constrain the
width to 400 pixels, but to ignore the height (only changing it to keep
the image proportional).

The constraint dimensions can be provided in a number of different
formats. See the Synopsis for a quick list of these. To stay
compatible with automated constraint generators, you B<can> provide
constrains as zero width and zero height, and the math object will not
attempt to do any scaling, always returning the input width/height,
and a scaling value of 1.

Once created, the object is fully Storable and re-usable and does not
store any state information from a single calculation run.

Returns a new Image::Math::Constrain object, or C<undef> if the
constraints have been defined wrongly.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;

	# Expand a single argument
	if ( @_ == 1 ) {
		my $value = defined $_[0] ? shift : return undef;
		if ( ref $value eq 'ARRAY' and @$value == 2 ) {
			return $class->new(@$value);
		}
		return undef if ref $value;
		$value =~ s/\s//g;
		# constrain(800x600)
		return $class->new("$1", "$2") if $value =~ /^constrain\((\d+)x(\d+)\)$/;
		# 800x600
		return $class->new("$1", "$2") if $value =~ /^(\d+)x(\d+)$/;
		# 800w600h
		return $class->new("$1", "$2") if $value =~ /^(\d+)w(\d+)h$/;
		# 800w (width only)
		return $class->new("$1", 0)    if $value =~ /^(\d+)w$/;
		# 800h (height only)
		return $class->new(0, "$1")    if $value =~ /^(\d+)h$/;
		# 800 (meaning 800x800)
		if ( $class->_non_neg_int($value) ) {
			return $class->new($value, $value);
		}
		return undef;
	}

	# The two argument form
	return undef unless @_ == 2;
	my $self = bless {}, $class;
	$self->{width}  = $class->_non_neg_int($_[0]) ? shift : return undef;
	$self->{height} = $class->_non_neg_int($_[0]) ? shift : return undef;
	$self;
}

=pod

=head2 width

The C<width> method gets the width constraint for the object.

Returns a positive integer, or zero if there is no width constraint.

=cut

sub width  { $_[0]->{width} }

=pod

=head2 height

The C<height> method gets the height constrain for the object.

Returns a positive integer, or zero if there is no height constraint.

=cut

sub height { $_[0]->{height} }

=pod

=head2 as_string

The C<as_string> method returns the constrain rule as a string in the
format 'constrain(123x123)'. This string form is also supported by the
constructor and so it provides a good way to serialise the constrain
rule, should you ever need to do so.

As this value is not localisable, it should never really be shown to the
user directly, unless you are sure you will never add i18n to your app.

=cut

sub as_string {
	"constrain($_[0]->{width}x$_[0]->{height})";
}

=pod

=head2 constrain $width, $height

The C<constrain> method takes the height and width of an image and
applies the constrain math to them to get the final width, height
and the scaling value needed in order to get the your image from
it's current size to the final size.

The resulting size will be in proportion to the original (it will have
the same aspect ratio) and will never be larger than the original.

When called in array context, returns the new dimensions and scaling value
as a list, as in the following.

  my ($width, $height, $scale) = $math->constrain(800, 600);

When called in scalar context, it returns a reference to a hash containing
the keys 'width', 'height', and 'scale'.

  my $hash = $math->constrain(800, 600);
  
  print "New Width  : $hash->{width}\n";
  print "New Height : $hash->{height}\n";
  print "Scaling By : $hash->{scalar}\n";

Having been created correctly, the object will only return an error if the
width and height arguments are not correct (are not positive integers).

In list context, returns a null list, so all three values will be C<undef>.

In scalar context, just returns C<undef>.

=cut

sub constrain {
	my $self   = shift;
	my $width  = $self->_pos_int($_[0]) ? shift : return;
	my $height = $self->_pos_int($_[0]) ? shift : return;
	unless ( $self->{width} or $self->{height} ) {
		return $self->_ret_val(wantarray, $width, $height, 1);
	}

	# Determine the prefered scaling in both dimensions
	my $w_scale = ($self->{width} and $self->{width} < $width)
		? ($self->{width} / $width) : 1;
	my $h_scale = ($self->{height} and $self->{height} < $height)
		? ($self->{height} / $height) : 1;

	# Do we need to scale?
	if ( $w_scale == 1 and $h_scale == 1 ) {
		return $self->_ret_val(wantarray, $width, $height, 1);
	}

	# Use the smaller scaling value to scale the dimentions
	my $scale = $w_scale < $h_scale ? $w_scale : $h_scale;
	$width  *= $scale;
	$height *= $scale;

	$self->_ret_val(wantarray, $width, $height, $scale);
}





#####################################################################
# Support Methods

# Validate a non-negative integer
sub _non_neg_int {
	my $value = defined $_[1] ? $_[1] : return '';
	return '' if ref $value;
	return 1  if $value eq '0';
	!! $value =~ /^[1-9]\d*$/;
}

# Validate a positive integer
sub _pos_int {
	my $value = defined $_[1] ? $_[1] : return '';
	return '' if ref $value;
	!! $value =~ /^[1-9]\d*$/;
}

# Return as either a list or HASH reference
sub _ret_val {
	my $self = shift;
	shift(@_) ? @_ # wantarray
	: { width => shift, height => shift, scale  => shift };
}

1;

=pod

=head1 TO DO

- Write more special-case unit tests

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Image-Math-Constrain>

For other issues, contact the maintainer

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Thank you to Phase N (L<http://phase-n.com/>) for permitting
the open sourcing and release of this distribution.

=head1 COPYRIGHT

Copyright 2004 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
