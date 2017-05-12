#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2006-2012 -- leonerd@leonerd.org.uk

package # hide from CPAN
  IO::Async::Internals::TimeQueue;

use strict;
use warnings;

use Carp;

use Time::HiRes qw( time );

BEGIN {
   my @methods = qw( next_time _enqueue cancel _fire );
   if( eval { require Heap::Fibonacci } ) {
      unshift our @ISA, "Heap::Fibonacci";
      require Heap::Elem;
      no strict 'refs';
      *$_ = \&{"HEAP_$_"} for @methods;
   }
   else {
      no strict 'refs';
      *$_ = \&{"ARRAY_$_"} for "new", @methods;
   }
}

# High-level methods

sub enqueue
{
   my $self = shift;
   my ( %params ) = @_;

   my $code = delete $params{code};
   ref $code or croak "Expected 'code' to be a reference";

   defined $params{time} or croak "Expected 'time'";
   my $time = $params{time};

   $self->_enqueue( $time, $code );
}

sub fire
{
   my $self = shift;
   my ( %params ) = @_;

   my $now = exists $params{now} ? $params{now} : time;
   $self->_fire( $now );
}

# Implementation using a Perl array

use constant {
   TIME => 0,
   CODE => 1,
};

sub ARRAY_new
{
   my $class = shift;
   return bless [], $class;
}

sub ARRAY_next_time
{
   my $self = shift;
   return @$self ? $self->[0]->[TIME] : undef;
}

sub ARRAY__enqueue
{
   my $self = shift;
   my ( $time, $code ) = @_;

   # TODO: This could be more efficient maybe using a binary search
   my $idx = 0;
   $idx++ while $idx < @$self and $self->[$idx][TIME] <= $time;
   splice @$self, $idx, 0, ( my $elem = [ $time, $code ]);

   return $elem;
}

sub ARRAY_cancel
{
   my $self = shift;
   my ( $id ) = @_;

   @$self = grep { $_ != $id } @$self;
}

sub ARRAY__fire
{
   my $self = shift;
   my ( $now ) = @_;

   my $count = 0;

   while( @$self ) {
      last if( $self->[0]->[TIME] > $now );

      my $top = shift @$self;

      $top->[CODE]->();
      $count++;
   }

   return $count;
}

# Implementation using Heap::Fibonacci

sub HEAP_next_time
{
   my $self = shift;

   my $top = $self->top;

   return defined $top ? $top->time : undef;
}

sub HEAP__enqueue
{
   my $self = shift;
   my ( $time, $code ) = @_;

   my $elem = IO::Async::Internals::TimeQueue::Elem->new( $time, $code );
   $self->add( $elem );

   return $elem;
}

sub HEAP_cancel
{
   my $self = shift;
   my ( $id ) = @_;

   $self->delete( $id );
}

sub HEAP__fire
{
   my $self = shift;
   my ( $now ) = @_;

   my $count = 0;

   while( defined( my $top = $self->top ) ) {
      last if( $top->time > $now );

      $self->extract_top;

      $top->code->();
      $count++;
   }

   return $count;
}

package # hide from CPAN
  IO::Async::Internals::TimeQueue::Elem;

use strict;
our @ISA = qw( Heap::Elem );

sub new
{
   my $self = shift;
   my $class = ref $self || $self;

   my ( $time, $code ) = @_;

   my $new = $class->SUPER::new(
      time => $time,
      code => $code,
   );

   return $new;
}

sub time
{
   my $self = shift;
   return $self->val->{time};
}

sub code
{
   my $self = shift;
   return $self->val->{code};
}

# This only uses methods so is transparent to HASH or ARRAY
sub cmp
{
   my $self = shift;
   my $other = shift;

   $self->time <=> $other->time;
}

0x55AA;
