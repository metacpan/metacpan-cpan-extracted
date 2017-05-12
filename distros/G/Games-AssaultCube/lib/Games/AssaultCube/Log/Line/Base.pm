# Declare our package
package Games::AssaultCube::Log::Line::Base;

# import the Moose stuff
use Moose;
use MooseX::StrictConstructor;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

# TODO improve validation for everything here, ha!

has 'line' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'event' => (
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
		return $self->line;
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords tostr

=head1 NAME

Games::AssaultCube::Log::Line::Base - The base log line object

=head1 ABSTRACT

This module provides the base log line descriptions all other subclasses inherit from.

=head1 DESCRIPTION

This module provides the base log line descriptions all other subclasses inherit from.

=head2 Attributes

Those attributes are the "generic" ones you can access. Please see the subclasses for additional attributes
you can use.

=head3 line

The raw log line

=head3 event

The event specified by the line ( see subclasses for all possible event types )

=head3 tostr

A convenience attribute returning a nice string representing this event ( might differ from the line! )

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
