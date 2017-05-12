# Declare our package
package Games::AssaultCube::Log::Line::CallVote;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

with	'Games::AssaultCube::Log::Line::Base::NickIP';

# TODO improve validation for everything here, ha!

has 'type' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'target' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'failure' => (
	isa		=> 'Bool',
	is		=> 'ro',
	default		=> 0,
);

has 'failure_reason' => (
	isa		=> 'Str',
	is		=> 'ro',
);

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return $self->nick . " called a vote: " . $self->type . " to: " . $self->target . ( $self->failure ? " FAILED(" . $self->failure_reason . ")" : "" );
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords mapname playername ip

=head1 NAME

Games::AssaultCube::Log::Line::CallVote - Describes the CallVote event in a log line

=head1 ABSTRACT

Describes the CallVote event in a log line

=head1 DESCRIPTION

This module holds the "CallVote" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when a client called a vote in the game.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 nick

The nick of the client who said something

=head3 ip

The ip of the client

=head3 type

The type of the vote

	ban [ nick ]
	kick [ nick ]
	force [ nick ]

	shuffle [ teams ]
	load [ mapname - mode ]

	enable [ autoteam ]
	disable [ autoteam ]

	stop [ demo ]
	change [ mastermode ]
	remove [ all bans ]
	set [ server description ]

	invalid [ invalid ]

=head3 target

The target of the vote ( playername, mapname, etc - depends on the type )

=head3 failure

Boolean indicating if the vote failed or succeeded?

=head3 failure_reason

The reason for failure if it was true

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
