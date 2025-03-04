#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2024 -- leonerd@leonerd.org.uk

package Future::AsyncAwait 0.70;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

require Future; Future->VERSION( '0.49' );

=head1 NAME

C<Future::AsyncAwait> - deferred subroutine syntax for futures

=head1 SYNOPSIS

=for highlighter language=perl

   use v5.14;
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
notably C# 5, EcmaScript 6, Python 3, Dart, Rust, C++20.

This module is still under active development. While it now seems relatively
stable enough for most use-cases and has received a lot of "battle-testing" in
a wide variety of scenarios, there may still be the occasional case of memory
leak left in it, especially if still-pending futures are abandoned.

The new syntax takes the form of two new keywords, C<async> and C<await>.

=head2 C<async>

The C<async> keyword should appear just before the C<sub> keyword that
declares a new function. When present, this marks that the function performs
its work in a I<potentially> asynchronous fashion. This has two effects: it
permits the body of the function to use the C<await> expression, and it wraps
the return value of the function in a L<Future> instance.

   async sub myfunc
   {
      return 123;
   }

   my $f = myfunc();
   my $result = $f->get;

As well as named function declarations it is also supported on anonymous
function expressions.

   my $code = async sub { return 456 };
   my $f = $code->();
   my $result = $f->get;

This C<async>-declared function always returns a C<Future> instance when
invoked. The returned future instance will eventually complete when the
function returns, either by the C<return> keyword or by falling off the end;
the result of the future will be the return value from the function's code.
Alternatively, if the function body throws an exception, this will cause the
returned future to fail.

If the final expression in the body of the function returns a C<Future>, don't
forget to C<await> it rather than simply returning it as it is, or else this
return value will become double-wrapped - almost certainly not what you
wanted.

   async sub otherfunc { ... }

   async sub myfunc
   {
      ...
      return await otherfunc();
   }

I<Since version 0.69> this module also supports the C<async> keyword on
lexical subroutine declarations when running on Perl version 5.18 or later.
Note that the C<my> keyword has to come first:

   use v5.18;

   my async sub lexfunc { ... }

   my $f = lexfunc(@args);

I<Since version 0.70> this module supports using the C<async> keyword to
declare named subs in other packages.

   async sub Some::Other::Package::myfunc { ... }

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

C<await> provides scalar context to its controlling expression.

   async sub func {
      # this function is invoked in scalar context
   }

   await func();

Because the C<await> keyword may cause its containing function to suspend
early, returning a pending future instance, it is only allowed inside
C<async>-marked subs.

The converse is not true; just because a function is marked as C<async> does
not require it to make use of the C<await> expression. It is still useful to
turn the result of that function into a future, entirely without C<await>ing
on any itself.

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

=head2 await (toplevel)

I<Since version 0.47.>

An C<await> expression is also permitted directly in the main script at
toplevel, outside of C<async sub>. This is implemented by simply invoking the
C<get> method on the future value. Thus, the following two lines are directly
equivalent:

   await afunc();
   afunc()->get;

This is provided as a syntax convenience for unit tests, toplevel scripts, and
so on. It allows code to be written in a style that can be easily moved into
an C<async sub>, and avoids encouraging "bad habits" of invoking the C<get>
method directly.

=head2 C<CANCEL>

I<Experimental. Since version 0.44.>

The C<CANCEL> keyword declares a block of code which will be run in the event
that the future returned by the C<async sub> is cancelled.

   async sub f
   {
      CANCEL { warn "This task was cancelled"; }

      await ...
   }

   f()->cancel;

A C<CANCEL> block is a self-contained syntax element, similar to perl
constructions like C<BEGIN>, and does not need a terminating semicolon.

When a C<CANCEL> block is encountered during execution of the C<async sub>,
the code in its block is stored for the case that the returned future is
cancelled. Each will take effect as it is executed, possibly multiple times if
it appears inside a loop, or not at all if it appears conditionally in a
branch that was not executed.

   async sub g
   {
      if(0) {
         CANCEL { warn "This does not happen"; }
      }

      foreach my $x ( 1..3 ) {
         CANCEL { warn "This happens for x=$x"; }
      }

      await ...
   }

   g()->cancel;

C<CANCEL> blocks are only invoked if a still-pending future is cancelled. They
are discarded without being executed if the function finishes; either
successfully or if it throws an exception.

=head1 Experimental Features

Some of the features of this module are currently marked as experimental. They
will provoke warnings in the C<experimental> category, unless silenced.

You can silence this with C<no warnings 'experimental'> but then that will
silence every experimental warning, which may hide others unintentionally. For
a more fine-grained approach you can instead use the import line for this
module to only silence this module's warnings selectively:

   use Future::AsyncAwait qw( :experimental(cancel) );

   use Future::AsyncAwait qw( :experimental );  # all of the above

=head1 SUPPORTED USES

Most cases involving awaiting on still-pending futures should work fine:

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

   async sub wubble
   {
      # on perl 5.35.5 and above
      foreach my ($k, $v) ( KVTHINGs ) {
         await func();
      }
   }

   async sub quux
   {
      my $x = do {
         await func();
      };
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

On perl versions 5.26 and later C<async sub> syntax supports the C<signatures>
feature if it is enabled:

   use v5.26;
   use feature 'signatures';

   async sub quart($x, $y)
   {
      ...
   }

I<Since version 0.55> any exceptions thrown by signature validation (because
of too few or too many arguments being passed) are thrown synchronously, and
do not result in a failed Future instance.

=head2 Cancellation

Cancelled futures cause a suspended C<async sub> to simply stop running.

   async sub fizz
   {
      await func();
      say "This is never reached";
   }

   my $f = fizz();
   $f->cancel;

Cancellation requests can propagate backwards into the future the
C<async sub> is currently waiting on.

   async sub floof
   {
      ...
      await $f1;
   }

   my $f2 = floof();

   $f2->cancel;  # $f1 will be cancelled too

This behaviour is still more experimental than the rest of the logic. The
following should be noted:

=over 4

=item *

Cancellation propagation is only implemented on Perl version 5.24 and above.
An C<async sub> in an earlier perl version will still stop executing if
cancelled, but will not propagate the request backwards into the future that
the C<async sub> is currently waiting on. See L</TODO>.

=back

=head1 SUBCLASSING Future

By default when an C<async sub> returns a result or fails immediately before
awaiting, it will return a new completed instance of the L<Future> class. In
order to allow code that wishes to use a different class to represent futures
the module import method can be passed the name of a class to use instead.

   use Future::AsyncAwait future_class => "Subclass::Of::Future";

   async sub func { ... }

This has the usual lexically-scoped effect, applying only to C<async sub>s
defined within the block; others are unaffected.

   use Future::AsyncAwait;

   {
      use Future::AsyncAwait future_class => "Different::Future";
      async sub x { ... }
   }

   async sub y { ... }  # returns a regular Future

This will only affect immediate results. If the C<await> keyword has to
suspend the function and create a new pending future, it will do this by using
the prototype constructor on the future it itself is waiting on, and the usual
subclass-respecting semantics of L<Future/new> will remain in effect there. As
such it is not usually necessary to use this feature just for wrapping event
system modules or other similar situations.

Such an alternative subclass should implement the API documented by
L<Future::AsyncAwait::Awaitable>.

=head1 WITH OTHER MODULES

=head2 Syntax::Keyword::Try

As of L<Future::AsyncAwait> version 0.10 and L<Syntax::Keyword::Try> version
0.07, cross-module integration tests assert that basic C<try/catch> blocks
inside an C<async sub> work correctly, including those that attempt to
C<return> from inside C<try>.

   use Future::AsyncAwait;
   use Syntax::Keyword::Try;

   async sub attempt
   {
      try {
         await func();
         return "success";
      }
      catch {
         return "failed";
      }
   }

As of L<Future::AsyncAwait> version 0.50, C<finally> blocks are invoked even
during cancellation.

=head2 Syntax::Keyword::Dynamically

As of L<Future::AsyncAwait> version 0.32, cross-module integration tests
assert that the C<dynamically> correctly works across an C<await> boundary.

   use Future::AsyncAwait;
   use Syntax::Keyword::Dynamically;

   our $var;

   async sub trial
   {
      dynamically $var = "value";

      await func();

      say "Var is still $var";
   }

=head2 Syntax::Keyword::Defer

As of L<Future::AsyncAwait> version 0.50, C<defer> blocks are invoked even
during cancellation.

   use Future::AsyncAwait;
   use Syntax::Keyword::Defer;

   async sub perhaps
   {
      defer { say "Cleaning up now" }
      await $f1;
   }

   my $fouter = perhaps();
   $fouter->cancel;

=head2 Object::Pad

As of L<Future::AsyncAwait> version 0.38 and L<Object::Pad> version 0.15, both
modules now use L<XS::Parse::Sublike> to parse blocks of code. Because of this
the two modules can operate together and allow class methods to be written as
async subs which await expressions:

   use Future::AsyncAwait;
   use Object::Pad;

   class Example
   {
      async method perform($block)
      {
         say "$self is performing code";
         await $block->();
         say "code finished";
      }
   }

=head2 Syntax::Keyword::MultiSub

As of L<Future::AsyncAwait> version 0.55 and L<Syntax::Keyword::MultiSub>
version 0.02 a cross-module integration test asserts that the C<multi>
modifier can be applied to C<async sub>.

   use Future::AsyncAwait;
   use Syntax::Keyword::MultiSub;

   async multi sub f () { return "nothing"; }
   async multi sub f ($key) { return await get_thing($key); }

=cut

sub import
{
   my $pkg = shift;
   my $caller = caller;

   $pkg->import_into( $caller, @_ );
}

sub unimport
{
   my $pkg = shift;
   my $caller = caller;

   $pkg->unimport_into( $caller, @_ );
}

sub import_into   { shift->apply( sub { $^H{ $_[0] }++ },      @_ ) }
sub unimport_into { shift->apply( sub { delete $^H{ $_[0] } }, @_ ) }

my @EXPERIMENTAL = qw( cancel );

sub apply
{
   my $pkg = shift;
   my ( $cb, $caller, @syms ) = @_;

   $cb->( "Future::AsyncAwait/async" ); # Just always turn this on

   SYM: while( @syms ) {
      my $sym = shift @syms;

      $^H{"Future::AsyncAwait/future"} = shift @syms, next if $sym eq "future_class";

      foreach ( @EXPERIMENTAL ) {
         $cb->( "Future::AsyncAwait/experimental($_)" ), next SYM if $sym eq ":experimental($_)";
      }
      if( $sym eq ":experimental" ) {
         $cb->( "Future::AsyncAwait/experimental($_)" ) for @EXPERIMENTAL;
         next SYM;
      }

      croak "Unrecognised import symbol $sym";
   }
}

=head1 SEE ALSO

=over 4

=item *

"Awaiting The Future" - TPC in Amsterdam 2017

L<https://www.youtube.com/watch?v=Xf7rStpNaT0> L<(slides)|https://docs.google.com/presentation/d/13x5l8Rohv_RjWJ0OTvbsWMXKoNEWREZ4GfKHVykqUvc/edit#slide=id.p>

=back

=head1 TODO

=over 4

=item *

Suspend and resume with some consideration for the savestack; i.e. the area
used to implement C<local> and similar. While in general C<local> support has
awkward questions about semantics, there are certain situations and cases
where internally-implied localisation of variables would still be useful and
can be supported without the semantic ambiguities of generic C<local>.

   our $DEBUG = 0;

   async sub quark
   {
      local $DEBUG = 1;
      await func();
   }

Since C<foreach> loops on non-lexical iterator variables (usually the C<$_>
global variable) effectively imply a C<local>-like behaviour, these are also
disallowed.

   async sub splurt
   {
      foreach ( LIST ) {
         await ...
      }
   }

Some notes on what makes the problem hard can be found at

L<https://rt.cpan.org/Ticket/Display.html?id=122793>

=item *

Currently this module requires perl version 5.16 or later. Additionally,
threaded builds of perl earlier than 5.22 are not supported.

L<https://rt.cpan.org/Ticket/Display.html?id=122252>

L<https://rt.cpan.org/Ticket/Display.html?id=124351>

=item *

Implement cancel back-propagation for Perl versions earlier than 5.24.
Currently this does not work due to some as-yet-unknown effects that
installing the back-propagation has, causing future instances to be reclaimed
too early.

L<https://rt.cpan.org/Ticket/Display.html?id=129202>

=back

=head1 KNOWN BUGS

This is not a complete list of all known issues, but rather a summary of the
most notable ones that currently prevent the module from working correctly in
a variety of situations. For a complete list of known bugs, see the RT queue
at L<https://rt.cpan.org/Dist/Display.html?Name=Future-AsyncAwait>.

=over 4

=item *

C<await> inside C<map> or C<grep> blocks does not work. This is due to the
difficulty of detecting the map or grep context from internal perl state at
suspend time, sufficient to be able to restore it again when resuming.

L<https://rt.cpan.org/Ticket/Display.html?id=129748>

As a workaround, consider converting a C<map> expression to the equivalent
form using C<push> onto an accumulator array with a C<foreach> loop:

   my @results = map { await func($_) } ITEMS;

becomes

   my @results;
   foreach my $item ( ITEMS ) {
      push @results, await func($item);
   }

with a similar transformation for C<grep> expressions.

Alternatively, consider using the C<fmap*> family of functions from
L<Future::Utils> to provide a concurrent version of the same code, which can
keep multiple items running concurrently:

   use Future::Utils qw( fmap );

   my @results = await fmap { func( shift ) }
      foreach    => [ ITEMS ],
      concurrent => 5;

=item *

The default arguments array (C<@_>) is not saved and restored by an C<await>
call on perl versions before v5.24. On such older perls, the value seen in the
C<@_> array after an await will not be the same as it was before.

L<https://rt.cpan.org/Ticket/Display.html?id=130683>

As a workaround, make sure to unpack the values out of it into regular lexical
variables early on, before the the first C<await>. The values of these
lexicals will be saved and restored as normal.

   async sub f
   {
      my ($vars, $go, @here) = @_;
      # do not make further use of @_ afterwards

      await thing();

      # $vars, $go, @here are all fine for use
   }

=back

=cut

=head1 ACKNOWLEDGEMENTS

With thanks to C<Zefram>, C<ilmari> and others from C<irc.perl.org/#p5p> for
assisting with trickier bits of XS logic.

Thanks to C<genio> for project management and actually reminding me to write
some code.

Thanks to The Perl Foundation for sponsoring me to continue working on the
implementation.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
