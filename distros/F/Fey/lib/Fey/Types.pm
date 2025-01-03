package Fey::Types;

use strict;
use warnings;

use base 'MooseX::Types::Combine';

our $VERSION = '0.44';

__PACKAGE__->provide_types_from(
    qw( MooseX::Types::Moose Fey::Types::Internal ));

1;

# ABSTRACT: Types for use in Fey

__END__

=pod

=encoding UTF-8

=head1 NAME

Fey::Types - Types for use in Fey

=head1 VERSION

version 0.44

=head1 DESCRIPTION

This module defines a whole bunch of types used by the Fey core
classes. None of these types are documented for external use at the
present, though that could change in the future.

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
