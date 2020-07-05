package Markdent::Dialect::Theory::SpanParser;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.37';

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

=encoding UTF-8

=head1 NAME

Markdent::Dialect::Theory::SpanParser - Span parser for Theory's proposed Markdown extensions

=head1 VERSION

version 0.37

=head1 DESCRIPTION

This role is applied to a L<Markdent::Parser::SpanParser> in order to allow
the pipe (|) and colon (:) characters to be backslash-escaped. These are used
to mark tables, so they need to be escapeable.

=head1 ROLES

This role does the L<Markdent::Role::Dialect::SpanParser> role.

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
