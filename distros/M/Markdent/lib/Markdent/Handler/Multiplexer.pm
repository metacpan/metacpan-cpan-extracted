package Markdent::Handler::Multiplexer;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.37';

use Markdent::Types;

use Moose;
use MooseX::StrictConstructor;

with 'Markdent::Role::Handler';

has _handlers => (
    is       => 'ro',
    isa      => t( 'ArrayRef', of => t('HandlerObject') ),
    init_arg => 'handlers',
    required => 1,
);

sub handle_event {
    $_->handle_event( $_[1] ) for @{ $_[0]->_handlers() };
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Passes events on to multiple handlers

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdent::Handler::Multiplexer - Passes events on to multiple handlers

=head1 VERSION

version 0.37

=head1 DESCRIPTION

This class passes the event stream onto one or more handlers. This is handy if
you want to do multiple things with a document at once, for example generate
HTML and capture the events to save for a cache.

=head1 METHODS

This class provides the following methods:

=head2 Markdent::Handler::Multiplexer->new( handlers => [ ... ] )

This method creates a new handler. You must pass a list of one or more objects
which do the L<Markdent::Role::Handler> role as the "handlers" parameters.

=head1 ROLES

This class does the L<Markdent::Role::Handler> role.

=head1 BUGS

See L<Markdent> for bug reporting details.

Bugs may be submitted at L<https://github.com/houseabsolute/Markdent/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Markdent can be found at L<https://github.com/houseabsolute/Markdent>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
