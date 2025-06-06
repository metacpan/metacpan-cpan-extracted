#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2022 -- leonerd@leonerd.org.uk

package Feature::Compat::Try 0.05;

use v5.14;
use warnings;
use feature ();

# Core's use feature 'try' only supports 'finally' since 5.35.8
use constant HAVE_FEATURE_TRY => $] >= 5.035008;

=head1 NAME

C<Feature::Compat::Try> - make C<try/catch> syntax available

=head1 SYNOPSIS

   use Feature::Compat::Try;

   sub foo
   {
      try {
         attempt_a_thing();
         return "success";
      }
      catch ($e) {
         warn "It failed - $e";
         return "failure";
      }
   }

=head1 DESCRIPTION

This module makes syntax support for C<try/catch> control flow easily
available.

Perl added such syntax at version 5.34.0, and extended it to support optional
C<finally> blocks at 5.35.9, which is enabled by

   use feature 'try';

On that version of perl or later, this module simply enables the core feature
equivalent to using it directly. On such perls, this module will install with
no non-core dependencies, and requires no C compiler.

On older versions of perl before such syntax is available, it is currently
provided instead using the L<Syntax::Keyword::Try> module, imported with a
special set of options to configure it to recognise exactly and only the same
syntax as the core perl feature, thus ensuring that any code using it will
still continue to function on that newer perl.

=cut

=head1 KEYWORDS

=head2 try

   try {
      STATEMENTS...
   }
   ...

A C<try> statement provides the main body of code that will be invoked, and
must be followed by a C<catch> statement. It may optionally be followed by
a C<finally> statement.

Execution of the C<try> statement itself begins from the block given to the
statement and continues until either it throws an exception, or completes
successfully by reaching the end of the block.

The body of a C<try {}> block may contain a C<return> expression. If executed,
such an expression will cause the entire containing function to return with
the value provided. This is different from a plain C<eval {}> block, in which
circumstance only the C<eval> itself would return, not the entire function.

The body of a C<try {}> block may contain loop control expressions (C<redo>,
C<next>, C<last>) which will have their usual effect on any loops that the
C<try {}> block is contained by.

The parsing rules for the set of statements (the C<try> block and its
associated C<catch>) are such that they are parsed as a self-contained
statement. Because of this, there is no need to end with a terminating
semicolon.

Even though it parses as a statement and not an expression, a C<try> block can
still yield a value if it appears as the final statement in its containing
C<sub> or C<do> block. For example:

   my $result = do {
      try { attempt_func() }
      catch ($e) { "Fallback Value" }
   };

=head2 catch

   ...
   catch ($var) {
      STATEMENTS...
   }

A C<catch> statement provides a block of code to the preceding C<try>
statement that will be invoked in the case that the main block of code throws
an exception. A new lexical variable is created to store the exception in.

Presence of this C<catch> statement causes any exception thrown by the
preceding C<try> block to be non-fatal to the surrounding code. If the
C<catch> block wishes to optionally handle some exceptions but not others, it
can re-raise it (or another exception) by calling C<die> in the usual manner.

As with C<try>, the body of a C<catch {}> block may also contain a C<return>
expression, which as before, has its usual meaning, causing the entire
containing function to return with the given value. The body may also contain
loop control expressions (C<redo>, C<next> or C<last>) which also have their
usual effect.

=head2 finally

   ...
   finally {
      STATEMENTS...
   }

A C<finally> statement provides an optional block of code to the preceding
C<try>/C<catch> pair which is executed afterwards, both in the case of a
normal execution or a thrown exception. This code block may be used to
provide whatever clean-up operations might be required by preceding code.

Because it is executed during a stack cleanup operation, a C<finally {}> block
may not cause the containing function to return, or to alter the return value
of it. It also cannot see the containing function's C<@_> arguments array
(though as it is block scoped within the function, it will continue to share
any normal lexical variables declared up until that point). It is protected
from disturbing the value of C<$@>. If the C<finally {}> block code throws an
exception, this will be printed as a warning and discarded, leaving C<$@>
containing the original exception, if one existed.
=cut

sub import
{
   if( HAVE_FEATURE_TRY ) {
      feature->import(qw( try ));
      require warnings;
      warnings->unimport(qw( experimental::try ));
   }
   else {
      require Syntax::Keyword::Try;
      Syntax::Keyword::Try->VERSION( '0.27' );
      Syntax::Keyword::Try->import(qw( try -require_catch -require_var ));
   }
}

=head1 COMPATIBILITY NOTES

This module may use either L<Syntax::Keyword::Try> or the perl core C<try>
feature to implement its syntax. While the two behave very similarly, and both
conform to the description given above, the following differences should be
noted.

=over 4

=item * Visibility to C<caller()>

The C<Syntax::Keyword::Try> module implements C<try> blocks by using C<eval>
frames. As a result, they are visible to the C<caller()> function and hence to
things like C<Carp::longmess> when viewed as stack traces.

By comparison, core's C<feature 'try'> creates a new kind of context stack
entry that is ignored by C<caller()> and hence these blocks do not show up in
stack traces.

This should not matter to most use-cases - e.g. even C<Carp::croak> will be
fine here. But if you are using C<caller()> with calculated indexes to inspect
the state of callers to your code and there may be C<try> frames in the way,
you will need to somehow account for the difference in stack height.

=item * C<B::Deparse>

The core C<feature 'try'> is implemented by emitting real opcodes that
represent its behaviour, which is recognised by the version of L<B::Deparse>
that ships with core perl. As a result, any code using this implementation
will deparse currently with tools like C<perl -MO=Deparse ...>, or others
related to it such as coverage checkers.

By comparison, since C<Syntax::Keyword::Try> uses C<OP_CUSTOM> it is not
recognised by C<B::Deparse> and so attempts to deparse this will result in
error messages like

   unexpected OP_CUSTOM (catch) at ...

This is rather unavoidable due to the way that C<B::Deparse> is implemented
and does not easily support custom operators.

See also L<https://rt.cpan.org/Ticket/Display.html?id=134812>.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
