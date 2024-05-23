package Linux::Info::Distribution;

use strict;
use warnings;
use Carp       qw(confess);
use Hash::Util qw(lock_hash);

use Class::XSAccessor getters => {
    get_name       => 'name',
    get_id         => 'id',
    get_version    => 'version',
    get_version_id => 'version_id',
};

our $VERSION = '2.11'; # VERSION

# ABSTRACT: base class to handle Linux distribution information


sub new {
    my ( $class, $params_ref ) = @_;

    confess 'Must receive a hash reference as parameter'
      unless ( ( defined($params_ref) ) and ( ref $params_ref eq 'HASH' ) );

    my @expected = qw(name id version version_id);

    foreach my $key (@expected) {
        confess "The hash reference is missing the key '$key'"
          unless ( exists $params_ref->{$key} );
    }

    my $self = {
        name       => $params_ref->{name},
        id         => $params_ref->{id},
        version    => $params_ref->{version},
        version_id => $params_ref->{version_id},
    };

    bless $self, $class;
    lock_hash( %{$self} );
    return $self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Info::Distribution - base class to handle Linux distribution information

=head1 VERSION

version 2.11

=head1 SYNOPSIS

    # just an example, you probably want to use
    # Linux::Info::DistributionFactory instead
    my $distro = Linux::Info::Distribution-new({
        name => 'Foobar',
        version_id => '1.0',
        version => '1.0 (Cool Name)',
        id => 'foobar'
    });

=head1 DESCRIPTION

This is a base class that defines the most basic information one could retrieve
from a Linux distribution.

You probably want to the take a look of subclasses of this classes, unless you
looking for creating a entirely new classes tree.

Also, you probably want to use a factory class to create new instances instead
doing it manually.

The C<Linux::Info::Distribution> namespace started as a fork from
L<Linux::Distribution> distribution, even with some code shared between both of
them, although the API is very different.

At the end, modules under the C<Linux::Info::Distribution> tries to rely more
in the F</etc/os-release> file, which is more standardized and includes more
information.

=head1 METHODS

=head2 new

Creates and returns new instance.

Expects a hash reference with the following keys:

=over

=item *

name: the distribution name

=item *

id: a more concise, short version of the distribution name, normally in all
lowercase.

=item *

version: the long version identification of the distribution.

=item *

version_id: a shorter version of C<version>, generally with only numbers and
dots, possible a semantic version number.

=back

=head2 get_name

A getter for the C<name> attribute.

=head2 get_id

A getter for the C<id> attribute.

=head2 get_version

A getter for the C<version> attribute.

=head2 get_version_id

A getter for the C<version_id> attribute.

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

=over

=item *

L<Linux::Info::Distribution::Custom>

=item *

L<Linux::Info::Distribution::OSRelease>

=item *

L<Linux::Info::DistributionFactory>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior <glasswalk3r@yahoo.com.br>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Alceu Rodrigues de Freitas Junior.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
