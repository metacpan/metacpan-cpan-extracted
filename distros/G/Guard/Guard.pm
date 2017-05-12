=head1 NAME

Guard - safe cleanup blocks

=head1 SYNOPSIS

   use Guard;
   
   # temporarily chdir to "/etc" directory, but make sure
   # to go back to "/" no matter how myfun exits:
   sub myfun {
      scope_guard { chdir "/" };
      chdir "/etc";
   
      code_that_might_die_or_does_other_fun_stuff;
   }

   # create an object that, when the last reference to it is gone,
   # invokes the given codeblock:
   my $guard = guard { print "destroyed!\n" };
   undef $guard; # probably destroyed here

=head1 DESCRIPTION

This module implements so-called "guards". A guard is something (usually
an object) that "guards" a resource, ensuring that it is cleaned up when
expected.

Specifically, this module supports two different types of guards: guard
objects, which execute a given code block when destroyed, and scoped
guards, which are tied to the scope exit.

=head1 FUNCTIONS

This module currently exports the C<scope_guard> and C<guard> functions by
default.

=over 4

=cut

package Guard;

no warnings;

BEGIN {
   $VERSION = 1.023;
   @ISA = qw(Exporter);
   @EXPORT = qw(guard scope_guard);

   require Exporter;

   require XSLoader;
   XSLoader::load Guard, $VERSION;
}

our $DIED = sub { warn "$@" };

=item scope_guard BLOCK

=item scope_guard ($coderef)

Registers a block that is executed when the current scope (block,
function, method, eval etc.) is exited.

See the EXCEPTIONS section for an explanation of how exceptions
(i.e. C<die>) are handled inside guard blocks.

The description below sounds a bit complicated, but that's just because
C<scope_guard> tries to get even corner cases "right": the goal is to
provide you with a rock solid clean up tool.

The behaviour is similar to this code fragment:

   eval ... code following scope_guard ...
   {
      local $@;
      eval BLOCK;
      eval { $Guard::DIED->() } if $@;
   }
   die if $@;

Except it is much faster, and the whole thing gets executed even when the
BLOCK calls C<exit>, C<goto>, C<last> or escapes via other means.

If multiple BLOCKs are registered to the same scope, they will be executed
in reverse order. Other scope-related things such as C<local> are managed
via the same mechanism, so variables C<local>ised I<after> calling
C<scope_guard> will be restored when the guard runs.

Example: temporarily change the timezone for the current process,
ensuring it will be reset when the C<if> scope is exited:

   use Guard;
   use POSIX ();

   if ($need_to_switch_tz) {
      # make sure we call tzset after $ENV{TZ} has been restored
      scope_guard { POSIX::tzset };

      # localise after the scope_guard, so it gets undone in time
      local $ENV{TZ} = "Europe/London";
      POSIX::tzset;

      # do something with the new timezone
   }

=item my $guard = guard BLOCK

=item my $guard = guard ($coderef)

Behaves the same as C<scope_guard>, except that instead of executing
the block on scope exit, it returns an object whose lifetime determines
when the BLOCK gets executed: when the last reference to the object gets
destroyed, the BLOCK gets executed as with C<scope_guard>.

See the EXCEPTIONS section for an explanation of how exceptions
(i.e. C<die>) are handled inside guard blocks.

Example: acquire a Coro::Semaphore for a second by registering a
timer. The timer callback references the guard used to unlock it
again. (Please ignore the fact that C<Coro::Semaphore> has a C<guard>
method that does this already):

   use Guard;
   use Coro::AnyEvent;
   use Coro::Semaphore;

   my $sem = new Coro::Semaphore;

   sub lock_for_a_second {
      $sem->down;
      my $guard = guard { $sem->up };

      Coro::AnyEvent::sleep 1;

      # $sem->up gets executed when returning
   }

The advantage of doing this with a guard instead of simply calling C<<
$sem->down >> in the callback is that you can opt not to create the timer,
or your code can throw an exception before it can create the timer (or
the thread gets canceled), or you can create multiple timers or other
event watchers and only when the last one gets executed will the lock be
unlocked. Using the C<guard>, you do not have to worry about catching all
the places where you have to unlock the semaphore.

=item $guard->cancel

Calling this function will "disable" the guard object returned by the
C<guard> function, i.e. it will free the BLOCK originally passed to
C<guard >and will arrange for the BLOCK not to be executed.

This can be useful when you use C<guard> to create a cleanup handler to be
called under fatal conditions and later decide it is no longer needed.

=cut

1;

=back

=head1 EXCEPTIONS

Guard blocks should not normally throw exceptions (that is, C<die>). After
all, they are usually used to clean up after such exceptions. However,
if something truly exceptional is happening, a guard block should of
course be allowed to die. Also, programming errors are a large source of
exceptions, and the programmer certainly wants to know about those.

Since in most cases, the block executing when the guard gets executed does
not know or does not care about the guard blocks, it makes little sense to
let containing code handle the exception.

Therefore, whenever a guard block throws an exception, it will be caught
by Guard, followed by calling the code reference stored in C<$Guard::DIED>
(with C<$@> set to the actual exception), which is similar to how most
event loops handle this case.

The default for C<$Guard::DIED> is to call C<warn "$@">, i.e. the error is
printed as a warning and the program continues.

The C<$@> variable will be restored to its value before the guard call in
all cases, so guards will not disturb C<$@> in any way.

The code reference stored in C<$Guard::DIED> should not die (behaviour is
not guaranteed, but right now, the exception will simply be ignored).

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=head1 THANKS

Thanks to Marco Maisenhelder, who reminded me of the C<$Guard::DIED>
solution to the problem of exceptions.

=head1 SEE ALSO

L<Scope::Guard> and L<Sub::ScopeFinalizer>, which actually implement
dynamically scoped guards only, not the lexically scoped guards that their
documentation promises, and have a lot higher CPU, memory and typing
overhead.

L<Hook::Scope>, which has apparently never been finished and can corrupt
memory when used.

L<Scope::Guard> seems to have a big SEE ALSO section for even more
modules like it.

=cut

