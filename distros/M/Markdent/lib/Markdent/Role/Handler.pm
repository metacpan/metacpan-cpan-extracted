package Markdent::Role::Handler;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.26';

use Moose::Role;

requires 'handle_event';

1;

# ABSTRACT: A required role for all handlers

__END__

=pod

=head1 NAME

Markdent::Role::Handler - A required role for all handlers

=head1 VERSION

version 0.26

=head1 DESCRIPTION

This role implements an interface shared by all handlers.

=head1 REQUIRED METHODS

=over 4

=item * $handler->handle_event($event)

This method will always be called with a single object which does the
L<Markdent::Role::Event> role.

=back

=head1 BUGS

See L<Markdent> for bug reporting details.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
