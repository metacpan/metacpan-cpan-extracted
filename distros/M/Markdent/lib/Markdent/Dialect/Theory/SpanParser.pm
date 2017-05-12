package Markdent::Dialect::Theory::SpanParser;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.26';

use Moose::Role;

with 'Markdent::Role::Dialect::SpanParser';

around _build_escapable_chars => sub {
    my $orig  = shift;
    my $self  = shift;
    my $chars = $self->$orig();

    return [ @{$chars}, qw( | : ) ];
};

1;

# ABSTRACT: Span parser for Theory's proposed Markdown extensions

__END__

=pod

=head1 NAME

Markdent::Dialect::Theory::SpanParser - Span parser for Theory's proposed Markdown extensions

=head1 VERSION

version 0.26

=head1 DESCRIPTION

This role is applied to a L<Markdent::Parser::SpanParser> in order to allow
the pipe (|) and colon (:) characters to be backslash-escaped. These are used
to mark tables, so they need to be escapeable.

=head1 ROLES

This role does the L<Markdent::Role::Dialect::SpanParser> role.

=head1 BUGS

See L<Markdent> for bug reporting details.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
