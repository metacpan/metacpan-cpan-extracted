package Markdent::Event::EndCode;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.26';

use Markdent::Types qw( Str );

use Moose;
use MooseX::StrictConstructor;

has delimiter => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

with(
    'Markdent::Role::Event'         => { event_class => __PACKAGE__ },
    'Markdent::Role::BalancedEvent' => { compare     => ['delimiter'] },
    'Markdent::Role::EventAsText'
);

sub as_text { $_[0]->delimiter() }

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: An event for the end of a code span

__END__

=pod

=head1 NAME

Markdent::Event::EndCode - An event for the end of a code span

=head1 VERSION

version 0.26

=head1 DESCRIPTION

This class represents the end of a code span.

=head1 ATTRIBUTES

This class has the following attributes:

=head2 delimiter

The delimiter for the code span.

=head1 METHODS

This class has the following methods:

=head2 $event->as_text()

Returns the event's delimiter.

=head1 ROLES

This class does the L<Markdent::Role::Event> and
L<Markdent::Role::BalancedEvent> roles.

=head1 BUGS

See L<Markdent> for bug reporting details.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
