package JSPL::Boolean;

use strict;
use warnings;

use overload 
    'bool' => sub { ${$_[0]} },
    fallback => 1;

1;
__END__

=head1 NAME

JSPL::Boolean - Perl class that encapsulates the JavaScript's C<true> and
C<false> values.

=head1 DESCRIPTION

In JavaScript, every boolean expression results in one of the two values
C<true> or C<false>.  Both values, when returned to perl space will be wrapped
as instances of JSPL::Boolean.  Both perl objects use the C<overload>
mechanism to behave as expected.

As in JavaScript the rules to convert other values to boolean values are
similar to perl's ones, you seldom need to think about them. But, although is
considered bad style, you can found JavaScript code that uses something like the
following:

    function foo(val) {
	if(val === true) {
	    ...
	}
    }

So the need arises to be able to generate true JavaScript boolean values from perl. In those cases you can use the class methods described next.

=head1 Class methods

=over 4

=item True

Return an object that when passed to JavaScript results in the C<true> value,
and when evaluated in a perl expression gives a TRUE value.

    my $realJStrue = JSPL::Boolean->True;

The same object that constant L<JSPL/JS_TRUE>.

=item False

Return an object that when passed to JavaScript results in the C<false> value,
and when evaluated in a perl expression gives a FALSE value.

    my $realJSfalse = JSPL::Boolean->False;

The same object that constant L<JSPL/JS_FALSE>.

=back
