# the generic "ip+nick" role
package Games::AssaultCube::Log::Line::Base::NickIP;
use Moose::Role;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

has 'ip' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'nick' => (
	isa		=> 'Str',
	is		=> 'ro',
	default		=> 'unarmed',
);

1;
__END__

=for stopwords ip

=head1 NAME

Games::AssaultCube::Log::Line::Base::NickIP - The NickIP role for subclasses

=head1 ABSTRACT

This module provides the NickIP role for subclasses.

=head1 DESCRIPTION

This module provides the NickIP role for subclasses. This is the AssaultCube player name + ip.

=head2 Attributes

Those attributes are part of the role, and will be applied to subclasses that use this.

=head3 nick

The nick of the client

=head3 ip

The ip of the client

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
