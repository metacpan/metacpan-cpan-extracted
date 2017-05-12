package Fey::Role::SQL::HasBindParams;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.43';

use Fey::Types qw( ArrayRef Bool );

use Moose::Role;

has '_bind_params' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => ArrayRef,
    default  => sub { [] },
    handles  => { _add_bind_param => 'push' },
    init_arg => undef,
);

has 'auto_placeholders' => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

# This needs to be a method and not a delegated method so it can be excluded
# by classes which need to exclude it.
sub bind_params {
    return @{ $_[0]->_bind_params() };
}

1;

# ABSTRACT: A role for queries which can have bind parameters

__END__

=pod

=head1 NAME

Fey::Role::SQL::HasBindParams - A role for queries which can have bind parameters

=head1 VERSION

version 0.43

=head1 SYNOPSIS

  use Moose 2.1200;

  with 'Fey::Role::SQL::HasBindParams';

=head1 DESCRIPTION

Classes which do this role represent a query which can have bind
parameters.

=head1 METHODS

This role provides the following methods:

=head2 $query->bind_params()

Returns the bind params associated with the query.

=head2 $query->auto_placeholders()

This attribute determines whether values are automatically turned into
placeholders and stored as bind parameters.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
