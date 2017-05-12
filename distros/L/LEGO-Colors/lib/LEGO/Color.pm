package LEGO::Color;

require 5;
use strict;
use warnings;

our $VERSION = '0.4';

## Class methods

# The constructor method.  It's very simple.
sub new {
	my($proto) = shift;
	my(%options) = @_;
	my($class) = ref($proto) || $proto;
	my($self) = {};
	bless($self, $class);
	if ($options{name}) {
		$self->{name} = $options{name};
	}
	else {
		warn("Argument 'name' missing from parameters in construction");
	}
	for my $color (qw/red blue green/) {
		unless ($options{$color}) {
			warn("Argument '$color' missing from parameters in construction");
			return undef;
		}
		unless (_is_numeric($options{$color})) {
			warn("Argument '$color' non-numeric in construction");
			return undef;
		}
		unless ($options{$color} < 256) {
			warn("Argument '$color' too large (must be 255 or less) in construction");
			return undef;
		}
		$self->{$color} = $options{$color};
	}
	return $self;
}

## Object methods

# Frankly, these are all so simple that I'm not going to explain what they
# do.

sub get_name {
	my $self = shift;
	return $self->{name};
}

sub get_red {
	my $self = shift;
	return $self->{red};
}

sub get_green {
	my $self = shift;
	return $self->{green};
}

sub get_blue {
	my $self = shift;
	return $self->{blue};
}

sub get_rgb {
	my $self = shift;
	return map {$self->{$_}} (qw/red green blue/);
}

sub get_html_code {
	my $self = shift;
	# Yeah, this is dead sexy.
	# I wonder if I could have used %v or something
	return sprintf("#%0.2X%0.2X%0.2X", @{$self}{qw/red green blue/});
}

## Private methods

# All we want here are integers
sub _is_numeric {
	return $_[0] !~ /^\D/;
}

1;

__END__

=head1 NAME

LEGO::Colors - Access to LEGO color information.

=head1 SYNOPSIS

 use LEGO::Color;
 use strict;

 my $green = LEGO::Color->new(
   name  => 'green',
   red   => 0,
   green => 255,
   blue  => 0,
 );

 # Or, more likely...
 my $green = LEGO::Colors->get_color('green');

=head1 DESCRIPTION

This is a simple accessor class, used to store information about various
different colors that LEGO pieces can have.  Generally, you won't be
creating these yourself -- they're just convenient ways to pass information
back from the LEGO::Colors module.  Please see that documentation for more
information.

=head1 METHODS

=over 4

=item new

Constructs a new Color object.  Takes 4 named parameters, all required.
They are: name, red, blue and green, and hopefully self-explanatory.  Returns
undef if any parameters are missing or invalid.

=item get_name

Returns the name of this color object.

=item get_red

Returns the red value of this color object.

=item get_blue

Returns the blue value of this color object.

=item get_green

Returns the green value of this color object.

=item get_rgb

A convenience method that returns all 3 red, green and blue values in a
single hashref.

=item get_html_code

Returns an HTML color code, of the form "#XXYYZZ" that represents the
RGB values of this color object.

=back

=head1 Future Work

=over 4

=item * None at this time.

=back

=head1 Known Issues

=over 4

=item * None at this time.

=back

=head1 AUTHOR

Copyright 2007 Avi Finkel <F<avi@finkel.org>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

LEGO® is a trademark of the LEGO Group of companies which does
not sponsor, authorize or endorse this software.
The official LEGO website is at L<http://www.lego.com/>
=cut
