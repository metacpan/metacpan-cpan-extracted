package MVC::Neaf::Util::Base;

use strict;
use warnings;
our $VERSION = '0.2901';

=head1 NAME

MVC::Neaf::Util::Base - base class for other Not Even A Framework classes.

=head1 DESCRIPTION

This is an internal package providing some utility methods for Neaf itself.

See L<MVC::Neaf::X> for public interface.

=head1 METHODS

=cut

use Carp;
use File::Spec;

=head2 new( %options )

Will happily accept any args and pack them into self.

=cut

sub new {
    my ($class, %opt) = @_;

    return bless \%opt, $class;
};

# NOTE My bad! The first method in this package was prefixed with my_
#      Please prefix new methods with neaf_ instead, if possible.

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

=head2 dir ($path || [$path, ...])

For every given path, return $path if it starts with a '/',
or canonized concatenation of $self->neaf_base_dir and $path
otherwise.

Dies if C<neaf_base_dir> is not set.

B<NOTE> Please use this method whenever your Neaf extension/plugin
is given a path, do not rely on '.' to be set correctly!

=cut

sub dir {
    my $self = shift;

    # Cannot use Carp as it will likely point to the wrong location
    # TODO Only calculate this when needed
    my @stack = caller(1);

    # cache root so we only calculate it once
    my $root;

    # recursive handler sub that maps arrayrefs through itself
    my $handler;
    $handler = sub {
        return [map { $handler->() } @$_] if ref $_ eq 'ARRAY';
        return File::Spec->canonpath($_)
            if File::Spec->file_name_is_absolute($_);
        if (!defined $root) {
            $root = $self->neaf_base_dir;
            unless (defined $root) {
                warn ((ref $self)."->path(...) was called, but neaf_base_dir was never set at $stack[1] line $stack[2].\n");
                $root = '.';
            };
        };
        return File::Spec->canonpath("$root/$_");
    };

    local $_ = shift;
    return $handler->();
};

=head2 neaf_base_dir()

Dumb accessor that returns C<$self-E<gt>{neaf_base_dir}>.

Used by C<dir> (see above).

=cut

# Dumb accessor
sub neaf_base_dir {
    return $_[0]->{neaf_base_dir};
}

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2023 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
