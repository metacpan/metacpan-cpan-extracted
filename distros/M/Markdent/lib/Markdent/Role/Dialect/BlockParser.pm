package Markdent::Role::Dialect::BlockParser;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.40';

use Moose::Role;

1;

# ABSTRACT: A role for a dialect block parser

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdent::Role::Dialect::BlockParser - A role for a dialect block parser

=head1 VERSION

version 0.40

=head1 DESCRIPTION

This role has no internals, it simply indicates that the role which consumes it
is a block parser role.

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
