#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2018 -- leonerd@leonerd.org.uk

package Future::AsyncAwait;

use strict;
use warnings;

our $VERSION = '0.11';

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

require Future;

=head1 NAME

C<Future::AsyncAwait> - deferred subroutine syntax for futures

=head1 SYNOPSIS

   use Future::AsyncAwait;

   async sub do_a_thing
   {
      my $first = await do_first_thing();

      my $second = await do_second_thing();

      return combine_things( $first, $second );
   }

   do_a_thing()->get;

=head1 DESCRIPTION

This module provides syntax for deferring and resuming subroutines while
waiting for L<Future>s to complete. This syntax aims to make code that
performs asynchronous operations using futures look neater and more expressive
than simply using C<then> chaining and other techniques on the futures
themselves. It is also a similar syntax used by a number of other languages;
notably C# 5, EcmaScript 6, Python 3, and lately even Rust is considering
adding it.

The new syntax takes the form of two new keywords, C<async> and C<await>.

=head2 C<async>

The C<async> keyword should appear just before the C<sub> keyword that
declares a new function. When present, this marks that the function performs
its work in a I<potentially> asynchronous fashion. This has two effects: it
permits the body of the function to use the C<await> expression, and it forces
the return value of the function to always be a L<Future> instance.

   async sub myfunc
   {
      return 123;
   }

   my $f = myfunc();
   my $result = $f->get;

This C<async>-declared function always returns a C<Future> instance when
invoked. The returned future instance will eventually complete when the
function returns, either by the C<return> keyword or by falling off the end;
the result of the future will be the return value from the function's code.
Alternatively, if the function body throws an exception, this will cause the
returned future to fail.

=head2 C<await>

The C<await> keyword forms an expression which takes a C<Future> instance as
an operand and yields the eventual result of it. Superficially it can be
thought of similar to invoking the C<get> method on the future.

   my $result = await $f;

   my $result = $f->get;

However, the key difference (and indeed the entire reason for being a new
syntax keyword) is the behaviour when the future is still pending and is not
yet complete. Whereas the simple C<get> method would block until the future is
complete, the C<await> keyword causes its entire containing function to become
suspended, making it return a new (pending) future instance. It waits in this
state until the future it was waiting on completes, at which point it wakes up
and resumes execution from the point of the C<await> expression. When the
now-resumed function eventually finishes (either by returning a value or
throwing an exception), this value is set as the result of the future it had
returned earlier.

Because the C<await> keyword may cause its containing function to suspend
early, returning a pending future instance, it is only allowed inside
C<async>-marked subs.

The converse is not true; just because a function is marked as C<async> does
not require it to make use of the C<await> expression. It is still useful to
turn the result of that function into a future, entirely without C<await>ing
on any itself.

=head1 EARLY-VERSION WARNING

B<WARNING>: The actual semantics in this module are in an early state of
implementation. Some things will randomly break. While it seems stable enough
for small-scale development and experimental testing, don't expect to be able
to use this module reliably in production yet.

=head2 Things That Work Already

Most simple cases involving awaiting on still-pending futures should be
working:

   async sub foo
   {
      my ( $f ) = @_;

      BEFORE();
      await $f;
      AFTER();
   }

   async sub bar
   {
      my ( $f ) = @_;

      return 1 + await( $f ) + 3;
   }

   async sub splot
   {
      while( COND ) {
         await func();
      }
   }

   async sub wibble
   {
      if( COND ) {
         await func();
      }
   }

   async sub wobble
   {
      foreach my $var ( THINGs ) {
         await func();
      }
   }

   async sub splat
   {
      eval {
         await func();
      };
   }

Plain lexical variables are preserved across an C<await> deferral:

   async sub quux
   {
      my $message = "Hello, world\n";
      await func();
      print $message;
   }

=head2 Things That Don't Yet Work

C<local> variable assignments inside an C<async> function will confuse the
suspend mechanism:

   our $DEBUG = 0;

   async sub quark
   {
      local $DEBUG = 1;
      await func();
   }

Since C<foreach> loops on non-lexical iterator variables (usually package
variables) effectively imply a C<local>-like behaviour, these are also
disallowed.

   our $VAR;

   async sub splurt
   {
      foreach $VAR ( LIST ) {
         await ...
      }
   }

Additionally, complications with the savestack appear to be affecting some
uses of package-level C<our> variables captured by async functions:

   our $VAR;

   async sub bork
   {
      print "VAR is $VAR\n";
      await func();
   }

See also the L</TODO> list for further things.

=head2 Async Without Await

Any function that doesn't actually await anything, and just returns immediate
futures can be neatened by this module too.

Instead of writing

   sub imm
   {
      ...
      return Future->done( @result );
   }

you can now simply write

   async sub imm
   {
      ...
      return @result;
   }

with the added side-benefit that any exceptions thrown by the elided code will
be turned into an immediate-failed C<Future> rather than making the call
itself propagate the exception, which is usually what you wanted when dealing
with futures.

=head1 WITH OTHER MODULES

=head2 Syntax::Keyword::Try

As of C<Future::AsyncAwait> version 0.10 and L<Syntax::Keyword::Try> version
0.07, cross-module integration tests assert that basic C<try/catch> blocks
inside an C<async sub> work correctly, including those that attempt to
C<return> from inside C<try>.

=cut

sub import
{
   my $class = shift;
   my $caller = caller;

   $class->import_into( $caller, @_ );
}

sub import_into
{
   my $class = shift;
   my ( $caller, @syms ) = @_;

   @syms or @syms = qw( async );

   my %syms = map { $_ => 1 } @syms;
   $^H{"Future::AsyncAwait/async"}++ if delete $syms{async};

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 SEE ALSO

=over 4

=item *

"Awaiting The Future" - TPC in Amsterdam 2017

L<(slides)|https://docs.google.com/presentation/d/13x5l8Rohv_RjWJ0OTvbsWMXKoNEWREZ4GfKHVykqUvc/edit#slide=id.p>

=back

=head1 TODO

=over 4

=item *

Suspend and resume with some consideration for the savestack; i.e. the area
used to implement C<local> and similar. While in general C<local> support has
awkward questions about semantics, there are certain situations and cases
where internally-implied localisation of variables would still be useful and
can be supported without the semantic ambiguities of generic C<local>.

Some notes on what makes the problem hard can be found at

L<https://rt.cpan.org/Ticket/Display.html?id=122793>

=item *

Clean up the implementation; check for and fix memory leaks.

=item *

Support older versions of perl than 5.24.

L<https://rt.cpan.org/Ticket/Display.html?id=122252>

=back

=head1 ACKNOWLEDGEMENTS

With thanks to C<Zefram>, C<ilmari> and others from C<irc.perl.org/#p5p> for
assisting with trickier bits of XS logic. Thanks to C<genio> for project
management and actually reminding me to write some code.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
