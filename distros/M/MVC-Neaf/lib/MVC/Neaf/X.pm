package MVC::Neaf::X;

use strict;
use warnings;
our $VERSION = '0.2901';

# This class is empty (yet).
# See MVC::Neaf::Util::Base for implementation

=head1 NAME

MVC::Neaf::X - base class for Not Even A Framework extentions.

=head1 SYNOPSIS

    package MVC::Neaf::X::My::Module;
    use parent qw(MVC::Neaf::X);

    sub foo {
        my $self = shift;

        $self->my_croak("unimplemented"); # will die with package & foo prepended
    };

    1;

=head1 DESCRIPTION

Start out a Neaf extention by subclassing this class.

Some convenience methods here to help develop.

=head1 METHODS

=cut

use parent qw(MVC::Neaf::Util::Base);

=head2 new( %options )

Will happily accept any args and pack them into self.

=cut

=head2 my_croak( $message )

Like croak() from Carp, but the message is prefixed
with self's package and the name of method
in which error occurred.

=cut

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2023 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
