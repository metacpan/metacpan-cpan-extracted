package Markdent::Event::EndLink;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.40';

use Moose;
use MooseX::StrictConstructor;

with(
    'Markdent::Role::Event' => { event_class => __PACKAGE__ },
    'Markdent::Role::BalancedEvent',
);

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: An event for the end of a link

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdent::Event::EndLink - An event for the end of a link

=head1 VERSION

version 0.40

=head1 DESCRIPTION

This class represents the end of a link.

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

This software is copyright (c) 2021 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
