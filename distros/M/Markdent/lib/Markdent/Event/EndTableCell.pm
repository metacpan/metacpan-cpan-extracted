package Markdent::Event::EndTableCell;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.26';

use Markdent::Types qw( Bool );

use Moose;
use MooseX::StrictConstructor;

has is_header_cell => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

with 'Markdent::Role::Event' => { event_class => __PACKAGE__ };

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: An event for the end of a table cell

__END__

=pod

=head1 NAME

Markdent::Event::EndTableCell - An event for the end of a table cell

=head1 VERSION

version 0.26

=head1 DESCRIPTION

This class represents the end of a table cell.

=head1 ROLES

This class does the L<Markdent::Role::Event> role.

=head1 ATTRIBUTES

This class has the following attributes:

=head2 is_header_cell

A boolean indicating whether the cell is a header cell. This will be true for
all cells in the table's header, but can also be true for cells in the table's
body.

=head1 BUGS

See L<Markdent> for bug reporting details.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
