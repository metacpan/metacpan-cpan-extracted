#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Feature::Compat::Try 0.02;

use v5.14;
use warnings;

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

This module is written in the aspiration that one day perl will gain true
native syntax support for C<try/catch> control flow, and that it will be
spelled using the syntax defined here. The intention here is that on such
a version of perl that provides this syntax this module will simply enable it,
equivalent to perhaps

   use feature 'try';

On older versions of perl before such syntax is available, it is currently
provided instead using the L<Syntax::Keyword::Try> module, imported with a
special set of options to configure it to recognise exactly and only the same
syntax as this as-yet-aspirational core perl feature, thus ensuring that any
code using it will still continue to function on that newer perl.

=cut

=head1 KEYWORDS

=head2 try

   try {
      STATEMENTS...
   }
   ...

A C<try> statement provides the main body of code that will be invoked, and
must be followed by a C<catch> statement.

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

=cut

sub import
{
   # Hopefully some future version of perl will add `use feature 'try';` so
   # we can be conditional on the perl version here.

   # ironic use of eval {}
   if( eval { require feature; feature->import(qw( try )); 1 } ) {
      require warnings;
      warnings->unimport(qw( experimental::try ));
   }
   else {
      require Syntax::Keyword::Try;
      Syntax::Keyword::Try->VERSION( '0.21' );
      Syntax::Keyword::Try->import(qw( try -no_finally -require_var ));
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
