package MVC::Neaf::Util::Base;

use strict;
use warnings;
our $VERSION = 0.2501;

=head1 NAME

MVC::Neaf::Util::Base - base class for other Not Even A Framework classes.

=head1 DESCRIPTION

This is an internal package providing some utility methods for Neaf itself.

See L<MVC::Neaf::X> for public interface.

=head1 METHODS

=cut

use Carp;

=head2 new( %options )

Will happily accept any args and pack them into self.

=cut

sub new {
    my ($class, %opt) = @_;

    return bless \%opt, $class;
};

=head2 my_croak( $message )

Like croak() from Carp, but the message is prefixed
with self's package and the name of method
in which error occurred.

=cut

sub my_croak {
    my ($self, $msg) = @_;

    my $sub = [caller(1)]->[3];
    $sub =~ s/.*:://;

    croak join "", (ref $self || $self),"->",$sub,": ",$msg;
};

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2018 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
