package JavaScript::QuickJS::RegExp;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

JavaScript::QuickJS::RegExp

=head1 SYNOPSIS

    my $regexp = JavaScript::QuickJS->new()->eval("/foo/");

    if ($regexp->test('fo')) {
        # This won’t run because test() will return falsy.
    }

=head1 DESCRIPTION

This class represents a JavaScript
L<RegExp|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RegExp>
instance in Perl.

This class is not instantiated directly.

=head1 METHODS

The following methods correspond to their JS equivalents:

=over

=item * C<exec()>

=item * C<test()>

=back

In addition, the following methods return their corresponding JS property:

=over

=item * C<flags()>

=item * C<dotAll()>

=item * C<global()>

=item * C<hasIndices()>

=item * C<ignoreCase()>

=item * C<multiline()>

=item * C<source()>

=item * C<sticky()>

=item * C<unicode()>

=item * C<lastIndex()>

=back

=cut

1;
