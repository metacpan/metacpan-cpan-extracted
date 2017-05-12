# Declare our package
package Games::AssaultCube::Log::Line::Killed;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

with	'Games::AssaultCube::Log::Line::Base::NickIP';

# TODO improve validation for everything here, ha!

has 'victim' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'tk' => (
	isa		=> 'Bool',
	is		=> 'ro',
	required	=> 1,
);

has 'gib' => (
	isa		=> 'Bool',
	is		=> 'ro',
	required	=> 1,
);

has 'score' => (
	isa		=> 'Int',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		if ( $self->tk ) {
			if ( $self->gib ) {
				return -2;
			} else {
				return -1;
			}
		} else {
			if ( $self->gib ) {
				return 2;
			} else {
				return 1;
			}
		}
	},
);

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return $self->nick . ( $self->gib ? " gibbed " : " killed " ) . ( $self->tk ? "teammate " : "" ) . $self->victim;
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords gamemode gib gibbed tk ip

=head1 NAME

Games::AssaultCube::Log::Line::Killed - Describes the Killed event in a log line

=head1 ABSTRACT

Describes the Killed event in a log line

=head1 DESCRIPTION

This module holds the "Killed" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when a client kills somebody. ( frag/gib )

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 nick

The nick of the client who did the kill

=head3 victim

The nick who died

=head3 ip

The ip of the client who did the kill

=head3 tk

Boolean value indicating if the client killed somebody on his team or not.

=head3 gib

Boolean value indicating if the client gibbed the victim or not.

=head3 score

The AC-specific score for this kill. ( varies from gamemode to gamemode, this is the default )

	Gib = 2
	Frag = 1
	TK Frag = -1
	TK Gib = -2

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
