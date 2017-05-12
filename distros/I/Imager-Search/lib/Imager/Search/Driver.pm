package Imager::Search::Driver;

=pod

=head1 NAME

Imager::Search::Driver - Abstract imlementation of a Imager::Search driver

=head1 SYNOPSIS

  # Create the search
  my $search = Imager::Search::Driver->new(
      driver => 'HTML24',
      big    => $large_imager_object,
      small  => $small_imager_object,
  );
  
  # Run the search
  my $found = $search->find_first;
  
  # Handle the result
  print "Found at row " . $found->top . " and column " . $found->left;

=head1 DESCRIPTION

Given two images (we'll call them Big and Small), where Small is
contained within Big zero or more times, determine the pixel locations
of Small within Big.

For example, given a screen shot or a rendered webpage, locate the
position of a known icon or picture within the larger image.

The intent is to provide functionality for use in various testing
scenarios, or desktop gui automation, and so on.

=head1 METHODS

=cut

use 5.006;
use strict;
use Carp         ();
use Params::Util qw{ _STRING _CODELIKE _SCALAR _INSTANCE };
use Imager       ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.01';
}

use Imager::Search::Match ();





#####################################################################
# Constructor and Accessors

=pod

=head2 new

  my $driver = Imager::Search::Driver->new;

The C<new> constructor takes a new search driver object.

Returns a new B<Imager::Search::Driver> object, or croaks on error.

=cut

sub new {
	my $class = shift;

	# Apply the default driver
	if ( $class eq 'Imager::Search::Driver' ) {
		require Imager::Search::Driver::HTML24;
		return  Imager::Search::Driver::HTML24->new(@_);
	}

	# Create the object
	my $self = bless { @_ }, $class;

	return $self;
}





#####################################################################
# Driver API Methods

=pod

=head2 image_string

The C<image_string> method takes a L<Imager::Search::Image> object, and
generates the search string for the image.

Returns a reference to a scalar, or dies on error.

=cut

sub image_string {
	my $class = ref($_[0]) || $_[0];
	die "Illegal driver $class does not implement image_string";
}

=pod

=head2 pattern_lines

Because of the way the regular expression spans scanlines, it requires
the width of the target image in order to be fully generated. However,
the sub-regexp for each scanline can be (and are) generated in advance.

When a L<Imager::Search::Pattern> object is created, the driver method
C<pattern_lines> is called to generate the scanline regexp for the
search pattern.

Returns a reference to an ARRAY containing the regexp in string form,
or dies on error.

=cut

sub pattern_lines {
	my $class = ref($_[0]) || $_[0];
	die "Illegal driver $class does not implement pattern_lines";
}

=pod

=head2 pattern_regexp

The C<pattern_regexp> method takes a pattern and an image is retruns a
fully-generated search regexp for the pattern, when used on that image.

Returns a Regexp object, or dies on error.

=cut

sub pattern_regexp {
	my $class = ref($_[0] || $_[0]);
	die "Illegal driver $class does not implement pattern_regexp";
}

=pod

=head2 match_object

Once the regexp engine has located a potential match, the pattern, image
and character position are provided to the C<match_object> method.

The C<match_object> will take the raw character position, validate that
the character position is at a legimate pixel position, and then return
the fully-described match.

Returns a L<Imager::Search::Match> object if the position is valid, or
false (undef in scalar context or a null string in list context) if the
position is not valid.

=cut

sub match_object {
	my $class = ref($_[0] || $_[0]);
	die "Illegal driver $class does not implement match_object";
}

1;

=pod

=head1 SUPPORT

See the SUPPORT section of the main L<Imager::Search> module.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
