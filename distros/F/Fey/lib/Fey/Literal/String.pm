package Fey::Literal::String;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use Fey::Types qw( Str );

use Moose 2.1200;
use MooseX::SemiAffordanceAccessor 0.03;
use MooseX::StrictConstructor 0.13;

with 'Fey::Role::Comparable', 'Fey::Role::Selectable', 'Fey::Role::IsLiteral';

has 'string' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

sub BUILDARGS {
    my $class = shift;

    return { string => shift };
}

sub sql { $_[1]->quote( $_[0]->string() ) }

sub sql_with_alias { goto &sql }

sub sql_or_alias { goto &sql }

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a literal string in a SQL statement

__END__

=pod

=encoding UTF-8

=head1 NAME

Fey::Literal::String - Represents a literal string in a SQL statement

=head1 VERSION

version 0.44

=head1 SYNOPSIS

  my $string = Fey::Literal::String->new($string)

=head1 DESCRIPTION

This class represents a literal string in a SQL statement.

=head1 INHERITANCE

This module is a subclass of C<Fey::Literal>.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Literal::String->new($string)

This method creates a new C<Fey::Literal::String> object representing
the string passed to the constructor.

=head2 $string->string()

Returns the string as passed to the constructor.

=head2 $string->id()

The id for a string is always just the string itself.

=head2 $string->sql()

=head2 $string->sql_with_alias()

=head2 $string->sql_or_alias()

Returns the appropriate SQL snippet.

=head1 ROLES

This class does the C<Fey::Role::Selectable> and
C<Fey::Role::Comparable> roles.

=head1 BUGS

See L<Fey> for details on how to report bugs.

Bugs may be submitted at L<https://github.com/ap/Fey/issues>.

=head1 SOURCE

The source code repository for Fey can be found at L<https://github.com/ap/Fey>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2025 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
