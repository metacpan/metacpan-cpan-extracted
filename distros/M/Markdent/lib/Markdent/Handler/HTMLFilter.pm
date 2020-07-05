package Markdent::Handler::HTMLFilter;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.37';

use Markdent::CapturedEvents;

use Moose;
use MooseX::StrictConstructor;

with 'Markdent::Role::FilterHandler';

sub filter_event {
    my $self  = shift;
    my $event = shift;

    return
        if grep { $event->isa( 'Markdent::Event::' . $_ ) }
        qw(
        HTMLBlock
        HTMLComment
        HTMLCommentBlock
        HTMLTag
        StartHTMLTag
        EndHTMLTag
    );

    $self->handler()->handle_event($event);

    return;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Filters out HTML events from the event stream

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdent::Handler::HTMLFilter - Filters out HTML events from the event stream

=head1 VERSION

version 0.37

=head1 SYNOPSIS

  my $html = Markdent::Handler::HTMLStream->new( ... );

  my $filter = Markdent::Handler::HTMLFilter->new( handler => $html );

  my $parser = Markdent::Parser->new( handler => $filter ):

  $parser->parse( markdown => ... );

=head1 DESCRIPTION

This class implements an event filter which drops all HTML events I<except>
for HTML entities.

=head1 METHODS

This class provides the following methods:

=head2 Markdent::Handler::HTMLFilter->new()

This method creates a new handler.

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
