package Markdent::Role::AnyParser;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.37';

use Markdent::Types;

use Moose::Role;

with 'Markdent::Role::DebugPrinter';

has handler => (
    is       => 'ro',
    does     => t('HandlerObject'),
    required => 1,
);

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _send_event {
    my $self = shift;

    $self->handler()->handle_event( $self->_make_event(@_) );
}
## use critic

sub _make_event {
    my $self  = shift;
    my $class = shift;

    my $real_class = $class =~ /::/ ? $class : 'Markdent::Event::' . $class;

    return $real_class->new(@_);
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _detab_text {
    my $self = shift;
    my $text = shift;

    # Ripped off from Text::Mardkown
    ${$text} =~ s{ ^
                   (.*?)
                   \t
                 }
                 { $1 . (q{ } x (4 - length($1) % 4))}xmge;

    return;
}

sub _debug_look_for {
    my $self = shift;

    return unless $self->debug();

    my @look_debug = map { ref $_ ? "$_->[0] ($_->[1])" : $_ } @_;

    my $msg = "Looking for the following possible matches:\n";
    $msg .= "  - $_\n" for @look_debug;

    $self->_print_debug($msg);
}
## use critic

1;

# ABSTRACT: A role for block and span parsers

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdent::Role::AnyParser - A role for block and span parsers

=head1 VERSION

version 0.37

=head1 DESCRIPTION

This role implements behavior shared by all types of parser.

=head1 ATTRIBUTES

This role provides the following attributes:

=head2 handler

This is a read-only attribute. It is an object which does the
L<Markdent::Role::Handler> role.

This is required for all parsers.

=head1 METHODS

=head2 $parser->_detab_text(\$text)

This takes a scalar reference to a piece of text that will be outputted and
replaces tabs with spaces. This is down I<after> a piece of text is parser for
markup.

=head1 ROLES

This class does the L<Markdent::Role::DebugPrinter> role.

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
