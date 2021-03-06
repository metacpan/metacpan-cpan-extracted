package Fey::Role::Groupable;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.43';

use Moose::Role;

sub is_groupable {1}

1;

# ABSTRACT: A role for things that can be part of a GROUP BY clause

__END__

=pod

=head1 NAME

Fey::Role::Groupable - A role for things that can be part of a GROUP BY clause

=head1 VERSION

version 0.43

=head1 SYNOPSIS

  use Moose 2.1200;

  with 'Fey::Role::Groupable';

=head1 DESCRIPTION

Classes which do this role represent an object which can be part of a
C<GROUP BY> clause.

=head1 METHODS

This role provides the following methods:

=head2 $object->is_groupable()

Returns true.

=head1 BUGS

See L<Fey> for details on how to report bugs.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
