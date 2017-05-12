=head1 NAME

Memoize::Lift - lift expression evaluation to compile time

=head1 SYNOPSIS

	use Memoize::Lift qw(lift);

	$value = lift(expensive_computation());

=head1 DESCRIPTION

This module supplies an operator that causes an expression to be evaluated
immediately at compile time, memoising its value for use at runtime.

=cut

package Memoize::Lift;

{ use 5.013008; }
use warnings;
use strict;

use Devel::CallParser 0.000 ();
use XSLoader;

our $VERSION = "0.000";

use parent "Exporter";
our @EXPORT_OK = qw(lift);

XSLoader::load(__PACKAGE__, $VERSION);

=head1 OPERATORS

=over

=item lift(EXPR)

Evaluate I<EXPR> at compile time and memoise its value.  Whenever a
C<lift> expression is evaluated at runtime, it yields the value
that I<EXPR> yielded at compile time.  There is one instance of this
memoisation for each instance of the C<lift> operator in the source.

I<EXPR> is lexically located where the C<lift> operator is, and can use
static aspects of the lexical environment normally.  However, because
I<EXPR> is evaluated at compile time, it cannot use any aspects of the
dynamic environment as it would exist at runtime of the C<lift> operator.
Lexical variables visible at the location of the C<lift> operator remain
visible to I<EXPR>, but referencing them is an error.

If evaluation of I<EXPR> results in an exception, that exception will
terminate compilation.

I<EXPR> is always evaluated in scalar context, regardless of the
context in which the C<lift> operator appears.  To memoise a list,
write C<@{lift([...])}>.

=back

=head1 BUGS

L<B::Deparse> will generate incorrect source when deparsing C<lift>
expressions.  It will show the constant value of the expression as best
it can, which is not perfect if the value is non-trivial.  It has no
chance at all to show the original expression that yielded that value,
because the expression is not kept: the value determined at compile time
is built into the op tree as a constant item.

The custom parsing code required for C<lift> to operate is only invoked
if C<lift> is invoked using an unqualified name.  That is, referring
to it as C<Memoize::Lift::lift> won't work.  This limitation should be
resolved if L<Devel::CallParser> or something similar migrates into the
core in a future version of Perl.

=head1 SEE ALSO

L<Memoize::Once>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2011 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
