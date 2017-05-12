package Imager::Search::Pattern;

=pod

=head1 NAME

Imager::Search::Pattern - Search object for an image

=head1 SYNOPSIS

  my $pattern = Imager::Search::Pattern->new(
          driver => 'Imager::Search::Driver::HTML24',
          image  => $Imager,
  );
  
  my $regexp = $pattern->regexp;

=head1 DESCRIPTION

B<Imager::Search::Pattern> takes an L<Imager> object, and converts it
into a partially-compiled regular expression.

This partial regexp can then be quickly turned into the final L<Regexp>
once the widget of the target image is known, as well as being able to
be cached.

This allows a single B<Imager::Search::Pattern> object to be quickly
applied to many different sizes of target images.

=head1 METHODS

=cut

use 5.006;
use strict;
use Carp         ();
use IO::File     ();
use Params::Util ();
use Imager       ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.01';
}

use Object::Tiny::XS qw{
	name
	driver
	cache
	file
	image
	height
	width
	lines
};





#####################################################################
# Constructors

=pod

=head2 new

  $pattern = Imager::Search::Pattern->new(
      driver => 'Imager::Search::Driver::HTML24',
      file   => 'search/image.gif',
      cache  => 1,
  );

=cut

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	if ( Params::Util::_IDENTIFIER($self->driver) ) {
		$self->{driver} = "Imager::Search::Driver::" . $self->driver;
	}
	if ( Params::Util::_DRIVER($self->driver, 'Imager::Search::Driver') ) {
		unless ( Params::Util::_INSTANCE($self->driver, 'Imager::Search::Driver') ) {
			$self->{driver} = $self->driver->new;
		}
	}
	unless ( Params::Util::_INSTANCE($self->driver, 'Imager::Search::Driver') ) {
		Carp::croak("Did not provide a valid driver");
	}
	if ( defined $self->file and not defined $self->image ) {
		# Load the image from a file
		$self->{image} = Imager->new;
		$self->{image}->read( file => $self->file );
	}
	if ( defined $self->image ) {
		unless( Params::Util::_INSTANCE($self->image, 'Imager') ) {
			Carp::croak("Did not provide a valid image");
		}
		$self->{height} = $self->image->getheight;
		$self->{width}  = $self->image->getwidth;
		$self->{lines}  = $self->driver->pattern_lines($self->image);
	}
	unless ( Params::Util::_POSINT($self->height) ) {
		Carp::croak("Invalid or missing image height");
	}
	unless ( Params::Util::_POSINT($self->width) ) {
		Carp::croak("Invalid or missing image width");
	}
	unless ( Params::Util::_ARRAY($self->lines) ) {
		Carp::croak("Did not provide an ARRAY of line patterns");
	}

	# Normalise caching behaviour
	$self->{cache} = !! $self->cache;
	if ( $self->cache ) {
		$self->{regexp} = {};
	}

	return $self;
}

sub write {
	my $self = shift;
	my $io   = undef;
	if ( Params::Util::_INSTANCE($_[0], 'IO::Handle') ) {
		$io = $_[0];
	} elsif ( Params::Util::_STRING($_[0]) ) {
		$io = IO::File->new( $_[0], 'w' );
		unless ( Params::Util::_INSTANCE($io, 'IO::File') ) {
			Carp::croak("Failed to open $_[0] to write");
		}
	} else {
		Carp::croak("Did not provide a file or handle to write");
	}

	# The first line is the class of this object
	$io->print( "class: " . ref($self) . "\n" );

	# Next, a series of key: value pairs of the main properties
	foreach my $key ( qw{ driver width height } ) {
		$io->print( $key . ': ' . $self->$key() . "\n" );
	}

	# Ending with a blank newline to indicate the end of the headers
	$io->print("\n");

	# And now we print all of the pattern lines
	my $lines = $self->lines;
	foreach ( 0 .. $#$lines ) {
		$io->print( $lines->[0] . "\n" );
	}

	# Return without closing.
	# Any file we opened will auto-close,
	# and anyone passing a handle should close it themselves.
	return 1;
}





#####################################################################
# Main Methods

sub regexp {
	my $self = shift;

	# Get the width param
	my $width = undef;
	if ( Params::Util::_INSTANCE($_[0], 'Imager') ) {
		$width = $_[0]->getwidth;
	} elsif ( Params::Util::_INSTANCE($_[0], 'Imager::Search::Image') ) {
		$width = $_[0]->width;
	} elsif ( Params::Util::_POSINT($_[0]) ) {
		$width = $_[0];
	} else {
		Carp::croak("Did not provide a width to Imager::Search::Pattern::regexp");
	}

	# Return the cached version if possible
	if ( $self->cache and $self->{regexp}->{$width} ) {
		return $self->{regexp}->{$width};
	}

	# Hand off to the driver to build the regexp
	my $regexp = $self->driver->pattern_regexp( $self, $width );

	# Cache if needed
	if ( $self->cache ) {
		$self->{regexp}->{$width} = $regexp;
	}

	return $regexp;
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
