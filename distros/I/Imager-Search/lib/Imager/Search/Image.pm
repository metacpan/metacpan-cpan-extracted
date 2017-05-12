package Imager::Search::Image;

=pod

=head1 NAME

Imager::Search::Image - Generic interface for a searchable image

=head1 DESCRIPTION

L<Imager::Search::Image> is an abstract base class for objects that
implement an image to be searched.

=head1 METHODS

=cut

use 5.006;
use strict;
use Params::Util qw{ _IDENTIFIER _POSINT _INSTANCE _DRIVER };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.01';
}

use Object::Tiny::XS qw{
	name
	driver
	file
	image
	height
	width
	string
};





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check the driver
	if ( _IDENTIFIER($self->driver) ) {
		$self->{driver} = "Imager::Search::Driver::" . $self->driver;
	}
	if ( _DRIVER($self->driver, 'Imager::Search::Driver') ) {
		$self->{driver} = $self->driver->new;
	}
	unless ( _INSTANCE($self->driver, 'Imager::Search::Driver') ) {
		Carp::croak("Did not provide a valid driver");
	}
	if ( defined $self->file and not defined $self->image ) {
		# Load the image from a file
		$self->{image} = Imager->new;
		$self->{image}->read( file => $self->file );
	}
	if ( defined $self->image ) {
		unless( _INSTANCE($self->image, 'Imager') ) {
			Carp::croak("Did not provide a valid image");
		}
		$self->{height} = $self->image->getheight;
		$self->{width}  = $self->image->getwidth;
		$self->{string} = $self->driver->image_string($self->image);
	}
	unless ( _POSINT($self->height) ) {
		Carp::croak("Invalid or missing image height");
	}
	unless ( _POSINT($self->width) ) {
		Carp::croak("Invalid or missing image width");
	}

	return $self;
}





#####################################################################
# Search Methods

=pod

=head2 find

The C<find> method compiles the search and target images in memory, and
executes a single search, returning the position of the first match as a
L<Imager::Search::Match> object.

=cut

sub find {
	my $self    = shift;
        my $pattern = _INSTANCE(shift, 'Imager::Search::Pattern');
	unless ( $pattern ) {
		die "Did not pass a Pattern object to find";
	}

	# Run the search
	my @match  = ();
	my $string = $self->string;
	my $regexp = $pattern->regexp( $self );
	while ( scalar $$string =~ /$regexp/g ) {
		my $p = $-[0];
		push @match, $self->driver->match_object( $self, $pattern, $p );
		pos $$string = $p + 1;
	}

	return @match;
}

sub find_any {
	my $self    = shift;
        my $pattern = _INSTANCE(shift, 'Imager::Search::Pattern');
	unless ( $pattern ) {
		die "Did not pass a Pattern object to find";
	}

	# Run the search
	my $string = $self->string;
	my $regexp = $pattern->regexp( $self );
	while ( scalar $$string =~ /$regexp/gs ) {
		my $p = $-[0];
		if ( defined $self->driver->match_object( $self, $pattern, $p ) ) {
			return 1;
		}
		pos $$string = $p + 1;
	}
	return '';
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
