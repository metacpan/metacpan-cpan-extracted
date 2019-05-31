package MVC::Neaf::Route::Null;

use strict;
use warnings;
our $VERSION = '0.2701';

=head1 NAME

MVC::Neaf::Route::Null - route stub for Not Even A Framework

=head1 DESCRIPTION

This is a utility class.
Nothing to see here unless one intends to work on L<MVC::Neaf> itself.

A Null route will be substituted in L<MVC::Neaf::Request>'s methods until
real routing has been performed.

Normally this shouldn't even be instantiated as L<MVC::Neaf::Route::PreRoute>
will take over before any user code gets a chance to be executed by Neaf.

But for the sake of completeness, it is here.

=head1 METHODS

=cut

use Carp;

use parent qw(MVC::Neaf::Util::Base);
use MVC::Neaf::Util qw(make_getters);

=head2 new

=cut

my $nobody_home = sub { die 404 };
sub new {
    my $class = shift;

    return $class->SUPER::new(
        method  => 'GET',
        path    => '/',
        code    => $nobody_home,
        default => {},
        hooks   => {},
        helpers => {},
        @_
    );
};

=head2 post_setup

Do nothing.

=cut

sub post_setup {
};

=head2 path

Returns C<path> argument given to C<new()>, defaults to C<'/'>.

=head2 method

Returns C<method> argument given to C<new()>, defaults to C<'GET'>.

=head2 code

Returns function that dies with 404.

=head2 strict

returns "strict" parameter.

=head2 code

Returns a "die 404" function by default.

=head2 hooks

Returns an empty hash by default.

=head2 default

Returns anempty hash by default.

=cut

make_getters (
    path     => 1,
    method   => 1,
    code     => 1,
    strict   => 1,
    default  => 1,
    hooks    => 1,
    helpers  => 1,
);

=head2 get_form

=head2 get_view

These two die, because there are no forms/views available until
the request routing has been started.

=cut

sub get_form {
    my ($self, $name) = @_;
    croak "No form '$name' in null route";
};

sub get_view {
    my ($self, $name) = @_;
    croak "No view '$name' in null route";
};

=head2 parent

Returns nothing, as this route isn't attached to any application.

=cut

sub parent {
    undef;
};

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2019 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
