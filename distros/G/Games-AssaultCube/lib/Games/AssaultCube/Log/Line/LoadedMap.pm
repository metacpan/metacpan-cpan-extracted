# Declare our package
package Games::AssaultCube::Log::Line::LoadedMap;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

# TODO improve validation for everything here, ha!

has 'map' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'mapsize' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'cfgsize' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'cfgzsize' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return "Loaded map " . $self->map . " (" . $self->mapsize . " bytes)";
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords cfg cfgsize cfgzsize mapsize
=head1 NAME

Games::AssaultCube::Log::Line::LoadedMap - Describes the LoadedMap event in a log line

=head1 ABSTRACT

Describes the LoadedMap event in a log line

=head1 DESCRIPTION

This module holds the "LoadedMap" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when the AC server successfully loads a map.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 map

The name of the map loaded

=head3 mapsize

The size of the map ( in bytes )

=head3 cfgsize

The size of the cfg file ( in bytes )

=head3 cfgzsize

The size of the cfg file - gzipped ( in bytes )

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
