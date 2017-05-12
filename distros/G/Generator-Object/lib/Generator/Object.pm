package Generator::Object;

=head1 NAME

Generator::Object - Generator objects for Perl using Coro

=head1 SYNOPSIS

 use strict; use warnings;
 use Generator::Object;

 my $gen = generator {
   my $x = 0;
   while (1) {
     $x += 2;
     $_->yield($x);
   }
 };

 print $gen->next; # 2
 print $gen->next; # 4

=head1 DESCRIPTION

L<Generator::Object> provides a class for creating Python-like generators for
Perl using C<Coro>. Calling the C<next> method will invoke the generator, while
inside the generator body, calling the C<yield> method on the object will
suspend the interpreter and return execution to the main thread. When C<next>
is called again the execution will return to the point of the C<yield> inside
the generator body. Arguments passed to C<yield> are returned from C<next>.
This pattern allows for long-running processes to return values, possibly
forever, with lazy evaluation.

For convenience the generator object is provided to the function body as C<$_>.
Further the context of the C<next> method call is provided via the C<wantarray>
object method. When/if the generator is exhausted, the C<next> method will
return C<undef> and the C<exhausted> method will return true. Any return value
from the body will then be available from the C<retval> method. The generator
may be restarted at any time by using the C<restart> method. C<retval> will
be empty after the generator restarts.

Note: in version 0.01 of this module the generator would automatically
restart when calling C<next> again after it was exhausted. This behavior was
removed in version 0.02 because upon reflection this is not usually what the
author means and since C<restart> is available it can be done manually.

The internals of the object are entirely off-limits and where possible they
have been hidden to prevent access. No subclass api is presented nor planned.
The use of L<Coro> internally shouldn't interfere with use of L<Coro>
externally.

=cut

use strict;
use warnings;

our $VERSION = '0.04';
$VERSION = eval $VERSION;

use Coro ();

=head1 EXPORTS

=head2 generator

 my $gen = generator { ...; $_->yield($val) while 1 };

Convenience function for creating instances of L<Generator::Object>. Takes a
block (subref) which is the body of the generator. Returns an instance of
L<Generator::Object>.

=cut

sub import {
  my $class = shift;
  my $caller = caller;

  no strict 'refs';
  *{"${caller}::generator"} = sub (&) {
    my $sub = shift;
    return $class->new($sub);
  };

  # yield??
}

=head1 CONSTRUCTOR

=head2 new

 my $gen = Generator::Object->new(sub{...; $_->yield});

Takes a subref which is the body of the generator. Returns an instance of
L<Generator::Object>.

=cut

sub new {
  my $class = shift;
  my $sub = shift;
  return bless { sub => $sub, retval => [] }, $class;
}

=head1 METHODS

=head2 exhausted

 while (1) {
   next if defined $gen->next;
   print "Done\n" if $gen->exhausted;
 }

When the generator is exhausted the C<next> method will return C<undef>.
However, since C<next> might legitimately return C<undef>, this method is
provided to check that the generator has indeed been exhausted. If the
generator is restarted, then this method will again returns false.

=cut

sub exhausted { shift->{exhausted} }

=head2 next

 my $first  = $gen->next;
 my $second = $gen->next;

This method iterates the generator until C<yield> is called or the body is
returned from. It returns any value passed to C<yield>, in list context all
arguments are returned, in scalar context the first argument is returned. The
context of the C<next> call is available from the C<wantarray> method for more
manual control.

When the generator is exhausted, that is to say, when the body function
returns, C<next> returns C<undef>. Check C<exhausted> to differentiate between
exhaustion and a yielded C<undef>. Any values returned from the body are
available via the C<retval> method, again list return is emulated and the
C<wantarray> method (of the final C<next> call) can be checked when returning.

=cut

sub next {
  my $self = shift;
  return undef if $self->exhausted;

  # protect some state values from leaking
  local $self->{orig} = $Coro::current;
  local $self->{wantarray} = wantarray;
  local $self->{yieldval};

  $self->{coro} = Coro->new(sub {
    local $_ = $self;
    $self->{retval} = [ $self->{sub}->() ];
    $self->{exhausted} = 1;
    $self->{orig}->schedule_to;
  }) unless $self->{coro};

  $self->{coro}->schedule_to;

  my $yield = $self->{yieldval} || [];
  return $self->{wantarray} ? @$yield : $yield->[0];
}

=head2 restart

 my $gen = generator { my $x = 1; $_->yield($x++) while 1 };
 my $first = $gen->next;
 $gen->restart;
 $first == $gen->next; # true

Restarts the generator to its initial state. Of course if your generator has
made external changes, those will remain. Any values in C<retval> are cleared
and C<exhausted> is reset (if applicable).

Note: C<restart> is no longer implicitly called when C<next> is invoked on an
exhasted generator. You may recreate the old behavior by simply doing

 $gen->restart if $gen->exhausted;

=cut

sub restart {
  my $self = shift;
  delete $self->{coro};
  delete $self->{exhausted};
  $self->{retval} = [];
}

=head2 retval

 my $gen = generator { return 'val' };
 $gen->next;
 my $val = $gen->retval; # 'val'

Returns the value or values returned from the generator upon exhaustion if any.
In list context all returned values are given, in scalar context the first
element is returned. Note that the context in which C<next> was called as the
generator is exhausted is available via the C<wantarray> method for manual
control.

Before the generator is exhausted (and therefore before it has really returned
anything) the value of retval is C<undef> in scalar context and an empty list
in list context. Note that version 0.01 returned C<undef> in both contexts but
this has been corrected in version 0.02.

=cut

sub retval {
  my $self = shift;
  return undef unless $self->{retval};
  return
    wantarray
    ? @{ $self->{retval} }
    : $self->{retval}[0];
}

=head2 wantarray

 my $gen = generator {
   while (1) {
     $_->wantarray
       ? $_->yield('next called in list context')
       : $_->yield('next called in scalar context');
   }
 }

 my ($list) = $gen->next;
 my $scalar = $gen->next;

Much like the Perl built-in of the same name, this method provides the context
in which the C<next> method is called, making that information available to the
generator body.

=cut

sub wantarray { shift->{wantarray} }

=head2 yield

 my $gen = generator { ...; $_->yield($val) while 1 };

This method is the guts of the generator. When called C<yield> suspends the
state of the interpreter as it exists inside the generator body and returns to
the point at which C<next> was called. The values passed will be returned by
C<next> (see its documentation for more).

This method should not be called outside the generator body. For now, doing
so dies. In the future though this might change to be a safer no-op in the
future, or else the method may only be made available inside the body as
safe-guards. In the meantime, just don't do it!

=cut

sub yield {
  my $self = shift;
  die "Must not call yield outside the generator!\n"
    unless $self->{orig};

  $self->{yieldval} = [ @_ ];
  $self->{orig}->schedule_to;
}

=head1 FUTURE WORK

I intend (possibly soon) to allow arguments to be passed to the generator body
possibly even on every call to C<next>. Stay tuned.

=head1 SEE ALSO

=over

=item L<Coro>

=back

A few similar modules already exist. Their API and design choices weren't to my
liking, but they may appeal to you. Certainly I used them as reference and
thanks are due.

=over

=item L<Coro::Generator>

=item L<Attribute::Generator>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Generator-Object>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2015 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

