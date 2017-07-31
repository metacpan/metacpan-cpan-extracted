=head1 NAME

Memoize::Once - memoise expression on first execution

=head1 SYNOPSIS

    use Memoize::Once qw(once);

    $value = once(expensive_computation());

=head1 DESCRIPTION

This module supplies an operator that causes an expression to be evaluated
only once per program run, memoising its value for the remainder of
the run.

=cut

package Memoize::Once;

{ use 5.006; }
use warnings;
use strict;

use Devel::CallChecker 0.003 ();
use XSLoader;

our $VERSION = "0.002";

use parent "Exporter";
our @EXPORT_OK = qw(once);

XSLoader::load(__PACKAGE__, $VERSION);

=head1 OPERATORS

=over

=item once(EXPR)

Evaluate I<EXPR> once and memoise its value.  The first time a C<once>
expression is evaluated, I<EXPR> is evaluated, and (if everything proceeds
normally) C<once> stores the value it yielded and also yields the same
value.  When the same C<once> expression is evaluated subsequently, it
yields the value that I<EXPR> yielded the first time, without evaluating
I<EXPR> again.  There is one instance of this memoisation for each
instance of the C<once> operator in the source.

Because I<EXPR> is not evaluated until the C<once> operator is being
evaluated, it can refer to and use any aspects of the lexical and dynamic
environment as they exist at runtime of the C<once> operator.  However,
if I<EXPR> yields different results depending on variable aspects of the
environment, such as arguments of the surrounding subroutine, then the
memoisation is probably inappropriate.  That is, I<EXPR> can't sensibly
depend on the specific features of an invocation of the surrounding
code, but can depend on the general features that are consistent to
all invocations.

If evaluation of I<EXPR> results in an exception, rather than yielding
a normal value, no value will be memoised.  A value will be memoised
the first time that I<EXPR> does yield a normal value.  If multiple
evaluations of I<EXPR> are in progress simultaneously (due to recursion),
and multiple instances of it yield a normal value, then the first yielded
value will be memoised and others will be ignored.  A C<once> expression
will never yield a value other than the one it memoised.

I<EXPR> is always evaluated in scalar context, regardless of the
context in which the C<once> operator appears.  To memoise a list,
write C<@{once([...])}>.

=back

=head1 BUGS

L<B::Deparse> will generate incorrect source when deparsing C<once>
expressions.  The code that it displays gives a rough indication of
how memoisation operates, but appears buggy in detail.  In fact the
C<once> operator works through some custom ops that cannot be adequately
represented in pure Perl.

=head1 SEE ALSO

L<Memoize::Lift>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2011, 2017 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
