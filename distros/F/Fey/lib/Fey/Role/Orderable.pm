package Fey::Role::Orderable;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use Moose::Role;

sub is_orderable {1}

1;

# ABSTRACT: A role for things that can be part of a ORDER BY clause

__END__

=pod

=encoding UTF-8

=head1 NAME

Fey::Role::Orderable - A role for things that can be part of a ORDER BY clause

=head1 VERSION

version 0.44

=head1 SYNOPSIS

  use Moose 2.1200;

  with 'Fey::Role::Orderable';

=head1 DESCRIPTION

Classes which do this role represent an object which can be part of a
C<ORDER BY> clause.

=head1 METHODS

This role provides the following methods:

=head2 $object->is_orderable()

Returns true.

=head1 BUGS

See L<Fey> for details on how to report bugs.

Bugs may be submitted at L<https://github.com/ap/Fey/issues>.

=head1 SOURCE

The source code repository for Fey can be found at L<https://github.com/ap/Fey>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2025 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
