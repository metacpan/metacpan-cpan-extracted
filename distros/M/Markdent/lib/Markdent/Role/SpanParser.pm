package Markdent::Role::SpanParser;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.37';

use Moose::Role;

with 'Markdent::Role::AnyParser';

requires 'parse_block';

1;

# ABSTRACT: A role for span parsers

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdent::Role::SpanParser - A role for span parsers

=head1 VERSION

version 0.37

=head1 DESCRIPTION

This role implements behavior shared by all span parsers.

=head1 REQUIRED METHODS

=over 4

=item * $parser->parse_block(\$text)

This method takes a scalar reference to a markdown block and parses it for
span-level markup.

=back

=head1 ROLES

This role does the L<Markdent::Role::AnyParser> and
L<Markdent::Role::DebugPrinter> roles.

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
