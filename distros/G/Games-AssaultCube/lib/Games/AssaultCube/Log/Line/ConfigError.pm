# Declare our package
package Games::AssaultCube::Log::Line::ConfigError;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

# TODO improve validation for everything here, ha!

has 'errortype' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'what' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return "Config error in (" . $self->what . "): " . $self->errortype;
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords errortype mapname maprot
=head1 NAME

Games::AssaultCube::Log::Line::ConfigError - Describes the ConfigError event in a log line

=head1 ABSTRACT

Describes the ConfigError event in a log line

=head1 DESCRIPTION

This module holds the "ConfigError" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when the AC server encounters a config error.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 errortype

The type of configuration error ( maprot, "config read" )

=head3 what

The error string ( the mapname, or the config file, or etc depending on the errortype )

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
