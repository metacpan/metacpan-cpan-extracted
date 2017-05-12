use strict;
use warnings;

package GraphViz2::Abstract::Util::Constants;
BEGIN {
  $GraphViz2::Abstract::Util::Constants::AUTHORITY = 'cpan:KENTNL';
}
{
  $GraphViz2::Abstract::Util::Constants::VERSION = '0.001000';
}

# ABSTRACT: Constants used by C<GraphViz2::Abstract::*>

## no critic (ProhibitConstantPragma)
use constant EMPTY_STRING => q[];
use constant FALSE        => q[false];
use constant NONE         => \q[none];
use constant TRUE         => q[true];
use constant UNKNOWN      => \q[unknown];

use parent 'Exporter';

## no critic (ProhibitAutomaticExportation)
our (@EXPORT) = qw( EMPTY_STRING FALSE NONE TRUE UNKNOWN );


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

GraphViz2::Abstract::Util::Constants - Constants used by C<GraphViz2::Abstract::*>

=head1 VERSION

version 0.001000

=head1 CONSTANTS

In the L<< GraphViz documentation|http://www.graphviz.org/content/attrs >>, there are a few default values
which are used multiple times, and the following constants refer to them in one way or another.

=over 4

=item C<EMPTY_STRING>

This simply returns an empty string, and is not likely to change.

    ""

=item C<FALSE>

Where the specification shows C<false> as a default value, this module instead returns the string C<false>

This is because under the hood, GraphViz2 doesn't support values for attributes other than defined ones.

So its assumed that GraphViz, under the hood, interprets the string "false" the same as the boolean condition "false";

=item C<TRUE>

Where the specification shows C<true> as a default value, this module instead returns the string C<true>

Its assumed that GraphViz, under the hood, interprets the string "true" the same as the boolean condition "true",
for similar reasons L<< C<false>|/FALSE >> is.

=item C<NONE>

In the GraphViz docs, a few items have a default value specified as:

    <none>

This item was confusing in the specification, and it wasn't clear if it was some sort of magic string, or what.

Internally, we use a special value, a reference to a string "none" to represent this default.

For instance:

    my $v = Edge->new()->target();

    ok( ref $v, 'target returned a ref' );
    is( ref $v, 'SCALAR', 'target returned a scalar ref' );
    is( ${ $v }, 'none', 'target returned a scalar ref of "none"' );

However, because its not known how to canonicalize such forms, those values are presently not returned by either C<as_hash> methods.

So as a result:

    my $v = Edge->new( color => \"none" )->as_hash()

Will emit an empty hash. ( Despite "none" being different from the default ).

Also:

    my $v = Edge->new( color => \"none" )->as_canon_hash()

Will not emit a value for C<color> in its output, which may have the undesirable effect of reverting to the default, C<black> once rendered.

=item C<UNKNOWN>

On the GraphViz documentations, there were quite a few fields where the defaults were simply not specified,
or their values were cryptic.

Internally, those fields have the default value of C<\"unknown">

Like C<"none">, those fields with those values will not be emitted during hash production.

=back

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
