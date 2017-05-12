package Fey::ORM::Types;

use strict;
use warnings;

use base 'MooseX::Types::Combine';

our $VERSION = '0.47';

__PACKAGE__->provide_types_from(
    qw( MooseX::Types::Moose Fey::ORM::Types::Internal ));

1;

# ABSTRACT: Types for use in Fey::ORM

__END__

=pod

=head1 NAME

Fey::ORM::Types - Types for use in Fey::ORM

=head1 VERSION

version 0.47

=head1 DESCRIPTION

This module defines a whole bunch of types used by the Fey::ORM core
classes. None of these types are documented for external use at the present,
though that could change in the future.

=head1 BUGS

See L<Fey::ORM> for details on how to report bugs.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
