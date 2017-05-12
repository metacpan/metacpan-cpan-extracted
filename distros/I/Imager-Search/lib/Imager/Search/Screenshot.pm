package Imager::Search::Screenshot;

=pod

=head1 NAME

Imager::Search::Screenshot - An image captured from the screen

=head1 DESCRIPTION

B<Imager::Search::Screenshot> is a L<Imager::Search::Image> subclass
that allows you to capture images from the screen.

This provides a convenient mechanism to source the target images for
applications that need to (visually) monitor an existing graphical system.

=head1 METHODS

=cut

use 5.006;
use strict;
use Carp                  ();
use Params::Util          ();
use Imager::Screenshot    ();
use Imager::Search::Image ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.01';
	@ISA     = 'Imager::Search::Image';
}





#####################################################################
# Constructor and Accessors

=head2 new

  my $image = Imager::Search::Screenshot->new(
      [ id => 0 ],
      driver => 'BMP24',
  );

The C<new> constructor initates a screen capture and returns the image.

In addition to params inherited from L<Imager::Search::Image> it
additionally can take as the first parameter a reference to an ARRAY.

It provided, the contents of the ARRAY are passed through to the underlying
L<Imager::Screenshot> C<screenshot> method, which is used to do the actual
image capture.

Returns a new L<Imager::Search::Screenshot> object, or dies
on error.

=cut

sub new {
	my $class  = shift;
	my @params = ();
	@params = @{shift()} if Params::Util::_ARRAY0($_[0]);
	my $image = Imager::Screenshot::screenshot( @params );
	unless ( Params::Util::_INSTANCE($image, 'Imager') ) {
		Carp::croak('Failed to capture screenshot');
	}

	# Hand off to the parent class
	return $class->SUPER::new( image => $image, @_ );
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
