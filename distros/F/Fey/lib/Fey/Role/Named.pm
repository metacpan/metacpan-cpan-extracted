package Fey::Role::Named;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use Moose::Role;

requires 'name';

1;

# ABSTRACT: A role for things with a name

__END__

=pod

=encoding UTF-8

=head1 NAME

Fey::Role::Named - A role for things with a name

=head1 VERSION

version 0.44

=head1 SYNOPSIS

  use Moose 2.1200;

  with 'Fey::Role::Named';

=head1 DESCRIPTION

This role has no methods or attributes of its own, it simply requires
that the consuming class provide a C<name()> method.

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
