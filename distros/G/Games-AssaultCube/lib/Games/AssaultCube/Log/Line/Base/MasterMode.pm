# the mastermode role
package Games::AssaultCube::Log::Line::Base::MasterMode;
use Moose::Role;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

use Games::AssaultCube::Utils qw( get_mastermode_from_name get_mastermode_name );

has 'mastermode' => (
	isa		=> 'Int',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return get_mastermode_from_name( $self->mastermode_name );
	},
);

has 'mastermode_name' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return get_mastermode_name( $self->mastermode );
	},
);

sub BUILD {
	my $self = shift;

	# check role
	if ( ! exists $self->{'mastermode'} and ! exists $self->{'mastermode_name'} ) {
		die "Mastermode information is missing";
	}
	return;
}

1;
__END__

=for stopwords NUM mastermode
=head1 NAME

Games::AssaultCube::Log::Line::Base::MasterMode - The MasterMode role for subclasses

=head1 ABSTRACT

This module provides the MasterMode role for subclasses.

=head1 DESCRIPTION

This module provides the MasterMode role for subclasses. This is the AssaultCube server status.

=head2 Attributes

Those attributes are part of the role, and will be applied to subclasses that use this.

=head3 mastermode

The numeric AssaultCube mastermode of the server

	0 = OPEN
	1 = PRIVATE ( passworded )
	2 = NUM ( full )

=head3 mastermode_name

The name of the mastermode on the server ( OPEN, PRIVATE, NUM )

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
