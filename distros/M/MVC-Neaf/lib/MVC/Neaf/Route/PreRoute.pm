package MVC::Neaf::Route::PreRoute;

use strict;
use warnings;
our $VERSION = '0.2901';

=head1 NAME

MVC::Neaf::Route::PreRoute - temporary route stub for Not Even A Framework

=head1 DESCRIPTION

This is utility class.
Nothing to see here unless one intends to work on L<MVC::Neaf> itself.

It will show up in C<$req-E<gt>route> while a specific route
has not yet been selected.

It can still contain hooks & helpers, that's what it's for.

=head1 METHODS

=cut

use Carp;

use parent qw(MVC::Neaf::Route);

=head2 new

'method' parameter is required.

=cut

my $nobody_home = sub { die 404 };
sub new {
    my $class = shift;

    # Not using SUPER::new because MVC::Neaf::Route requires a parent
    my $self = bless {
        where   => '[in pre_route]',
        path    => '/',
        code    => $nobody_home,
        default => {},
        hooks   => {},
        helpers => {},
        @_
    }, $class;

    $self->post_setup()
        if $self->{parent};

    # Probably a bad idea. How to visually separate missing path in logs?
    $self->{path} = '[pre_route]';
    $self;
};


=head2 RUNTIME STUB METHODS

=over

=item * method = Actual method;

=item * path = C<'[pre_route]'>

May change to C</> in the future.

=item * code = C<die 404;>

=item * where = C<'[pre_route]'>

=back

Do not rely on these values.

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
