package Fey::ORM::Mock::Seeder;
{
  $Fey::ORM::Mock::Seeder::VERSION = '0.06';
}

use strict;
use warnings;

use Moose;

has '_data' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[HashRef]',
    default => sub { [] },
    handles => {
        push_values => 'push',
        next        => 'shift',
    },
);

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Stores seeded data for future object construction

__END__

=pod

=head1 NAME

Fey::ORM::Mock::Seeder - Stores seeded data for future object construction

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This object is used to store seeded data for constructors. You will
probably not need to use this class directly, instead just use C<<
Fey::ORM::Mock->seed_class() >>.

=head1 METHODS

This class provides the following methods:

=head2 Fey::ORM::Mock::Seeder->new()

Returns a new seeder object.

=head2 $seeder->push_values( $class => \%row, \%row, ... )

This seeds the constructor parameters for the given class.

=head2 $recorder->next($class)

Returns the next set of values for given class, if any exist.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
