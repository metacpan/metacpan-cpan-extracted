package Markdent::Event::StartStrong;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.37';

use Markdent::Types;

use Moose;
use MooseX::StrictConstructor;

has delimiter => (
    is       => 'ro',
    isa      => t('Str'),
    required => 1,
);

with(
    'Markdent::Role::Event'         => { event_class => __PACKAGE__ },
    'Markdent::Role::BalancedEvent' => { compare     => ['delimiter'] },
    'Markdent::Role::EventAsText',
);

sub as_text { $_[0]->delimiter() }

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: An event for the start of a strong span

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdent::Event::StartStrong - An event for the start of a strong span

=head1 VERSION

version 0.37

=head1 DESCRIPTION

This class represents the start of a strong span.

=head1 ATTRIBUTES

This class has the following attributes:

=head2 delimiter

The delimiter for the strong span.

=head1 METHODS

This class has the following methods:

=head2 $event->as_text()

Returns the event's delimiter.

=head1 ROLES

This class does the L<Markdent::Role::Event> and
L<Markdent::Role::BalancedEvent> roles.

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
