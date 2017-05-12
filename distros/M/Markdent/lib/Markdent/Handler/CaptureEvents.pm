package Markdent::Handler::CaptureEvents;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.26';

use Markdent::CapturedEvents;

use Moose;
use MooseX::StrictConstructor;

with 'Markdent::Role::Handler';

has captured_events => (
    is       => 'ro',
    isa      => 'Markdent::CapturedEvents',
    init_arg => undef,
    default  => sub { Markdent::CapturedEvents->new() },
);

sub handle_event {
    $_[0]->captured_events()->capture_events( $_[1] );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Captures events for replaying later

__END__

=pod

=head1 NAME

Markdent::Handler::CaptureEvents - Captures events for replaying later

=head1 VERSION

version 0.26

=head1 DESCRIPTION

This class implements an event receiver which simply captures events using
L<Markdent::CapturedEvents>. This can be used as a way to cache the results of
parsing at an intermediate stage.

=head1 METHODS

This class provides the following methods:

=head2 Markdent::Handler::CapturedEvents->new()

This method creates a new handler.

=head2 $mhce->captured_events()

Returns a L<Markdent::CapturedEvents> object containing all the events seen by
this handler so far.

=head1 ROLES

This class does the L<Markdent::Role::Handler> role.

=head1 BUGS

See L<Markdent> for bug reporting details.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
