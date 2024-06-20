###############################################################################
## ----------------------------------------------------------------------------
## Condvar helper class.
##
###############################################################################

package MCE::Shared::Condvar;

use strict;
use warnings;

use 5.010001;

no warnings qw( threads recursion uninitialized numeric );

our $VERSION = '1.891';

use MCE::Shared::Base ();
use MCE::Util ();
use MCE::Mutex ();

use overload (
   q("")    => \&MCE::Shared::Base::_stringify,
   q(0+)    => \&MCE::Shared::Base::_numify,
   fallback => 1
);

my $LF = "\012"; Internals::SvREADONLY($LF, 1);
my $_tid = $INC{'threads.pm'} ? threads->tid() : 0;
my $_reset_flg = 1;

sub CLONE {
   $_tid = threads->tid() if $INC{'threads.pm'};
}

sub DESTROY {
   my ($_cv) = @_;
   my $_pid  = $_tid ? $$ .'.'. $_tid : $$;

   if ($_cv->{_init_pid} eq $_pid) {
      MCE::Util::_destroy_socks($_cv, qw(_cw_sock _cr_sock));
   }

   return;
}

###############################################################################
## ----------------------------------------------------------------------------
## Public methods.
##
###############################################################################

sub new {
   my ($_class, $_cv) = (shift, {});

   $_cv->{_init_pid} = $_tid ? $$ .'.'. $_tid : $$;
   $_cv->{_value}    = shift || 0;
   $_cv->{_count}    = 0;

   MCE::Util::_sock_pair($_cv, qw(_cr_sock _cw_sock), undef, 1);

   MCE::Shared::Object::_reset(), $_reset_flg = ''
      if $_reset_flg && $INC{'MCE/Shared/Server.pm'};

   bless $_cv, $_class;
}

sub get { $_[0]->{_value} }
sub set { $_[0]->{_value} = $_[1] }

# The following methods applies to shared-context only and handled by
# MCE::Shared::Object.

sub lock      { }
sub unlock    { }

sub broadcast { }
sub signal    { }
sub timedwait { }
sub wait      { }

###############################################################################
## ----------------------------------------------------------------------------
## Sugar API, mostly resembles https://redis.io/commands#string primitives.
##
###############################################################################

# append ( string )

sub append {
   length( $_[0]->{_value} .= $_[1] // '' );
}

# decr
# decrby ( number )
# incr
# incrby ( number )
# getdecr
# getincr

sub decr    { --$_[0]->{_value}               }
sub decrby  {   $_[0]->{_value} -= $_[1] || 0 }
sub incr    { ++$_[0]->{_value}               }
sub incrby  {   $_[0]->{_value} += $_[1] || 0 }
sub getdecr {   $_[0]->{_value}--        // 0 }
sub getincr {   $_[0]->{_value}++        // 0 }

# getset ( value )

sub getset {
   my $old = $_[0]->{_value};
   $_[0]->{_value} = $_[1];

   $old;
}

# len ( )

sub len {
   length $_[0]->{_value};
}

###############################################################################
## ----------------------------------------------------------------------------
## Server functions.
##
###############################################################################

{
   use bytes;

   use constant {
      SHR_O_CVB => 'O~CVB',  # Condvar broadcast
      SHR_O_CVS => 'O~CVS',  # Condvar signal
      SHR_O_CVT => 'O~CVT',  # Condvar timedwait
      SHR_O_CVW => 'O~CVW',  # Condvar wait
   };

   my ( $_DAU_R_SOCK_REF, $_DAU_R_SOCK, $_obj, $_id );

   my %_output_function = (

      SHR_O_CVB.$LF => sub {                      # Condvar broadcast
         $_DAU_R_SOCK = ${ $_DAU_R_SOCK_REF };
         chomp($_id = <$_DAU_R_SOCK>);

         my $_var = $_obj->{ $_id } || do {
            print {$_DAU_R_SOCK} $LF;
            return;
         };
         for my $_i (1 .. $_var->{_count}) {
            syswrite($_var->{_cw_sock}, $LF);
         }

         $_var->{_count} = 0;
         print {$_DAU_R_SOCK} $LF;

         return;
      },

      SHR_O_CVS.$LF => sub {                      # Condvar signal
         $_DAU_R_SOCK = ${ $_DAU_R_SOCK_REF };
         chomp($_id = <$_DAU_R_SOCK>);

         my $_var = $_obj->{ $_id } || do {
            print {$_DAU_R_SOCK} $LF;
            return;
         };
         if ( $_var->{_count} >= 0 ) {
            syswrite($_var->{_cw_sock}, $LF);
            $_var->{_count} -= 1;
         }

         print {$_DAU_R_SOCK} $LF;

         return;
      },

      SHR_O_CVT.$LF => sub {                      # Condvar timedwait
         $_DAU_R_SOCK = ${ $_DAU_R_SOCK_REF };
         chomp($_id = <$_DAU_R_SOCK>);

         my $_var = $_obj->{ $_id } || do {
            print {$_DAU_R_SOCK} $LF;
            return;
         };

         $_var->{_count} -= 1;
         print {$_DAU_R_SOCK} $LF;

         return;
      },

      SHR_O_CVW.$LF => sub {                      # Condvar wait
         $_DAU_R_SOCK = ${ $_DAU_R_SOCK_REF };
         chomp($_id = <$_DAU_R_SOCK>);

         my $_var = $_obj->{ $_id } || do {
            print {$_DAU_R_SOCK} $LF;
            return;
         };

         $_var->{_count} += 1;
         print {$_DAU_R_SOCK} $LF;

         return;
      },

   );

   sub _init_mgr {
      my $_function;
      ( $_DAU_R_SOCK_REF, $_obj, $_function ) = @_;

      for my $key ( keys %_output_function ) {
         last if exists($_function->{$key});
         $_function->{$key} = $_output_function{$key};
      }

      return;
   }
}

###############################################################################
## ----------------------------------------------------------------------------
## Object package.
##
###############################################################################

## Items below are folded into MCE::Shared::Object.

package # hide from rpm
   MCE::Shared::Object;

use strict;
use warnings;

no warnings qw( threads recursion uninitialized numeric once );

use Time::HiRes qw( alarm sleep );
use bytes;

no overloading;

my $_is_MSWin32 = ($^O eq 'MSWin32') ? 1 : 0;

my ($_DAT_LOCK, $_DAT_W_SOCK, $_DAU_W_SOCK, $_dat_ex, $_dat_un, $_chn, $_obj);

sub _init_condvar {
   ($_DAT_LOCK, $_DAT_W_SOCK, $_DAU_W_SOCK, $_dat_ex, $_dat_un, $_chn, $_obj) = @_;

   return;
}

# broadcast ( floating_seconds )
# broadcast ( )

sub broadcast {
   my $_id = $_[0]->[0];
   return unless ( my $_CV = $_obj->{ $_id } );
   return unless ( exists $_CV->{_cr_sock} );

   sleep($_[1]) if defined $_[1];

   _req1('O~CVB', $_id.$LF);
   $_[0]->[6]->unlock();

   sleep(0);
}

# signal ( floating_seconds )
# signal ( )

sub signal {
   my $_id = $_[0]->[0];
   return unless ( my $_CV = $_obj->{ $_id } );
   return unless ( exists $_CV->{_cr_sock} );

   sleep($_[1]) if defined $_[1];

   _req1('O~CVS', $_id.$LF);
   $_[0]->[6]->unlock();

   sleep(0);
}

# timedwait ( floating_seconds )

sub timedwait {
   my $_id = $_[0]->[0];
   my $_timeout = $_[1];

   return unless ( my $_CV = $_obj->{ $_id } );
   return unless ( exists $_CV->{_cr_sock} );
   return $_[0]->wait() unless $_timeout;

   _croak('Condvar: timedwait (timeout) is not valid')
      if (!looks_like_number($_timeout) || $_timeout < 0);

   _req1('O~CVW', $_id.$LF);
   $_[0]->[6]->unlock();

   $_timeout = 0.0003 if $_timeout < 0.0003;

   local $@; eval {
      local $SIG{ALRM} = sub { alarm 0; die "alarm clock restart\n" };
      alarm $_timeout unless $_is_MSWin32;

      die "alarm clock restart\n"
         if $_is_MSWin32 && MCE::Util::_sock_ready($_CV->{_cr_sock}, $_timeout);

      (!$_is_MSWin32)
         ? (MCE::Util::_sysread($_CV->{_cr_sock}, my($_b1), 1), alarm(0))
         : (MCE::Util::_sysread($_CV->{_cr_sock}, my($_b2), 1));
   };

   alarm 0 unless $_is_MSWin32;

   if ($@) {
      chomp($@), _croak($@) unless $@ eq "alarm clock restart\n";
      _req1('O~CVT', $_id.$LF);

      return '';
   }

   return 1;
}

# wait ( )

sub wait {
   my $_id = $_[0]->[0];
   return unless ( my $_CV = $_obj->{ $_id } );
   return unless ( exists $_CV->{_cr_sock} );

   _req1('O~CVW', $_id.$LF);
   $_[0]->[6]->unlock();

   MCE::Util::_sock_ready($_CV->{_cr_sock}) if $_is_MSWin32;
   MCE::Util::_sysread($_CV->{_cr_sock}, my($_b), 1);

   return 1;
}

1;

__END__

###############################################################################
## ----------------------------------------------------------------------------
## Module usage.
##
###############################################################################

=head1 NAME

MCE::Shared::Condvar - Condvar helper class

=head1 VERSION

This document describes MCE::Shared::Condvar version 1.891

=head1 DESCRIPTION

This helper class for L<MCE::Shared> provides a C<Scalar>, C<Mutex>, and
primitives for conditional locking.

=head1 SYNOPSIS

 use MCE::Shared;

 my $cv = MCE::Shared->condvar( 0 );

 # OO interface

 $val = $cv->set( $val );
 $val = $cv->get();
 $len = $cv->len();

 # conditional locking primitives

 $cv->lock();
 $cv->unlock();
 $cv->broadcast(0.05);     # delay before broadcasting
 $cv->broadcast();
 $cv->signal(0.05);        # delay before signaling
 $cv->signal();
 $cv->timedwait(2.5);
 $cv->wait();

 # included, sugar methods without having to call set/get explicitly

 $val = $cv->append( $string );     #   $val .= $string
 $val = $cv->decr();                # --$val
 $val = $cv->decrby( $number );     #   $val -= $number
 $val = $cv->getdecr();             #   $val--
 $val = $cv->getincr();             #   $val++
 $val = $cv->incr();                # ++$val
 $val = $cv->incrby( $number );     #   $val += $number
 $old = $cv->getset( $new );        #   $o = $v, $v = $n, $o

=head1 EXAMPLE

The following example demonstrates barrier synchronization.

 use MCE;
 use MCE::Shared;
 use Time::HiRes qw(usleep);

 my $num_workers = 8;
 my $count = MCE::Shared->condvar(0);
 my $state = MCE::Shared->scalar('ready');

 my $microsecs = ( $^O =~ /mswin|mingw|msys|cygwin/i ) ? 0 : 200;

 # The lock is released upon entering ->broadcast, ->signal, ->timedwait,
 # and ->wait. For performance reasons, the condition variable is *not*
 # re-locked prior to exiting the call. Therefore, obtain the lock when
 # synchronization is desired subsequently.

 sub barrier_sync {
    usleep($microsecs) while $state->get eq 'down';

    $count->lock;
    $state->set('up'), $count->incr;

    if ($count->get == $num_workers) {
       $count->decr, $state->set('down');
       $count->broadcast;
    }
    else {
       $count->wait while $state->get eq 'up';
       $count->lock;
       $state->set('ready') if $count->decr == 0;
       $count->unlock;
    }
 }

 sub user_func {
    my $id = MCE->wid;
    for (1 .. 400) {
       MCE->print("$_: $id\n");
       barrier_sync();  # made possible by MCE::Shared::Condvar
     # MCE->sync();     # same thing via the MCE-Core API
    }
 }

 my $mce = MCE->new(
    max_workers => $num_workers,
    user_func   => \&user_func
 )->run;

 # Time taken from a 2.6 GHz machine running Mac OS X.
 # threads::shared:   0.207s  Perl threads
 #   forks::shared:  36.426s  child processes
 #     MCE::Shared:   0.353s  child processes
 #        MCE Sync:   0.062s  child processes

=head1 API DOCUMENTATION

=head2 MCE::Shared::Condvar->new ( )

Called by MCE::Shared for constructing a shared-condvar object.

=head2 MCE::Shared->condvar ( [ value ] )

Constructs a new condition variable. Its value defaults to C<0> when C<value>
is not specified.

 use MCE::Shared;

 $cv = MCE::Shared->condvar( 100 );
 $cv = MCE::Shared->condvar;

=head2 set ( value )

Sets the value associated with the C<cv> object. The new value is returned
in scalar context.

 $val = $cv->set( 10 );
 $cv->set( 10 );

=head2 get

Returns the value associated with the C<cv> object.

 $val = $cv->get;

=head2 len

Returns the length of the value. It returns the C<undef> value if the value
is not defined.

 $len = $var->len;

=head2 lock

Attempts to grab the lock and waits if not available. Multiple calls to
C<< $cv->lock >> by the same process or thread is safe. The mutex will remain
locked until C<< $cv->unlock >> is called.

 $cv->lock;

=head2 unlock

Releases the lock. A held lock by an exiting process or thread is released
automatically.

 $cv->unlock;

=head2 signal ( [ floating_seconds ] )

Releases a held lock on the variable. Then, unblocks one process or thread
that's C<wait>ing on that variable. The variable is *not* locked upon return.

Optionally, delay C<floating_seconds> before signaling.

 $count->signal;
 $count->signal( 0.5 );

=head2 broadcast ( [ floating_seconds ] )

The C<broadcast> method works similarly to C<signal>. It releases a held lock
on the variable. Then, unblocks all the processes or threads that are blocked
in a condition C<wait> on the variable, rather than only one. The variable is
*not* locked upon return.

Optionally, delay C<floating_seconds> before broadcasting.

 $count->broadcast;
 $count->broadcast( 0.5 );

=head2 wait

Releases a held lock on the variable. Then, waits until another thread does a
C<signal> or C<broadcast> for the same variable. The variable is *not* locked
upon return.

 $count->wait() while $state->get() eq "bar";

=head2 timedwait ( floating_seconds )

Releases a held lock on the variable. Then, waits until another thread does a
C<signal> or C<broadcast> for the same variable or if the timeout exceeds
C<floating_seconds>.

A false value is returned if the timeout is reached, and a true value otherwise.
In either case, the variable is *not* locked upon return.

 $count->timedwait( 10 ) while $state->get() eq "foo";

=head1 SUGAR METHODS

This module is equipped with sugar methods to not have to call C<set>
and C<get> explicitly. In shared context, the benefit is atomicity and
reduction in inter-process communication.

The API resembles a subset of the Redis primitives
L<https://redis.io/commands#strings> without the key argument.

=head2 append ( value )

Appends a value at the end of the current value and returns its new length.

 $len = $cv->append( "foo" );

=head2 decr

Decrements the value by one and returns its new value.

 $num = $cv->decr;

=head2 decrby ( number )

Decrements the value by the given number and returns its new value.

 $num = $cv->decrby( 2 );

=head2 getdecr

Decrements the value by one and returns its old value.

 $old = $cv->getdecr;

=head2 getincr

Increments the value by one and returns its old value.

 $old = $cv->getincr;

=head2 getset ( value )

Sets the value and returns its old value.

 $old = $cv->getset( "baz" );

=head2 incr

Increments the value by one and returns its new value.

 $num = $cv->incr;

=head2 incrby ( number )

Increments the value by the given number and returns its new value.

 $num = $cv->incrby( 2 );

=head1 CHAMENEOS DEMONSTRATION

The L<MCE example|https://github.com/marioroy/mce-examples/tree/master/chameneos> is derived from the L<chameneos example|http://benchmarksgame.alioth.debian.org/u64q/program.php?test=chameneosredux&lang=perl&id=4> by Jonathan DePeri and Andrew Rodland.

 use 5.010;
 use strict;
 use warnings;

 use MCE::Hobo;
 use MCE::Shared;
 use Time::HiRes 'time';

 die 'No argument given' if not @ARGV;

 my $start = time;
 my %color = ( blue => 1, red => 2, yellow => 4 );

 my ( @colors, @complement );

 @colors[values %color] = keys %color;

 for my $triple (
   [qw(blue blue blue)],
   [qw(red red red)],
   [qw(yellow yellow yellow)],
   [qw(blue red yellow)],
   [qw(blue yellow red)],
   [qw(red blue yellow)],
   [qw(red yellow blue)],
   [qw(yellow red blue)],
   [qw(yellow blue red)],
 ) {
   $complement[ $color{$triple->[0]} | $color{$triple->[1]} ] =
     $color{$triple->[2]};
 }

 my @numbers = qw(zero one two three four five six seven eight nine);

 sub display_complements
 {
   for my $i (1, 2, 4) {
     for my $j (1, 2, 4) {
       print "$colors[$i] + $colors[$j] -> $colors[ $complement[$i | $j] ]\n";
     }
   }
   print "\n";
 }

 sub num2words
 {
   join ' ', '', map $numbers[$_], split //, shift;
 }

 # Construct condvars and queues first before other shared objects or in
 # any order when IO::FDPass is installed, used by MCE::Shared::Server.

 my $meetings = MCE::Shared->condvar();

 tie my @creatures, 'MCE::Shared';
 tie my $first, 'MCE::Shared', undef;
 tie my @met, 'MCE::Shared';
 tie my @met_self, 'MCE::Shared';

 sub chameneos
 {
   my $id = shift;

   while (1) {
     $meetings->lock();

     unless ($meetings->get()) {
       $meetings->unlock();
       last;
     }

     if (defined $first) {
       $creatures[$first] = $creatures[$id] =
         $complement[$creatures[$first] | $creatures[$id]];

       $met_self[$first]++ if ($first == $id);
       $met[$first]++;  $met[$id]++;
       $meetings->decr();
       $first = undef;

       # Unlike threads::shared (condvar) which retains the lock
       # while in the scope, MCE::Shared signal and wait methods
       # must be called prior to leaving the block, due to lock
       # being released upon return.

       $meetings->signal();
     }
     else {
       $first = $id;
       $meetings->wait();  # ditto ^^
     }
   }
 }

 sub pall_mall
 {
   my $N = shift;
   @creatures = map $color{$_}, @_;
   my @threads;

   print " ", join(" ", @_);
   $meetings->set($N);

   for (0 .. $#creatures) {
     $met[$_] = $met_self[$_] = 0;
     push @threads, MCE::Hobo->create(\&chameneos, $_);
   }
   for (@threads) {
     $_->join();
   }

   $meetings->set(0);

   for (0 .. $#creatures) {
     print "\n$met[$_]", num2words($met_self[$_]);
     $meetings->incrby($met[$_]);
   }

   print "\n", num2words($meetings->get()), "\n\n";
 }

 display_complements();

 pall_mall($ARGV[0], qw(blue red yellow));
 pall_mall($ARGV[0], qw(blue red yellow red yellow blue red yellow red blue));

 printf "duration: %0.03f\n", time - $start;

=head1 CREDITS

The conditional locking feature is inspired by L<threads::shared>.

=head1 LIMITATIONS

Perl must have L<IO::FDPass> for constructing a shared C<condvar> or C<queue>
while the shared-manager process is running. For platforms where L<IO::FDPass>
isn't possible, construct C<condvar> and C<queue> before other classes.
On systems without C<IO::FDPass>, the manager process is delayed until sharing
other classes or started explicitly.

 use MCE::Shared;

 my $has_IO_FDPass = $INC{'IO/FDPass.pm'} ? 1 : 0;

 my $cv  = MCE::Shared->condvar();
 my $que = MCE::Shared->queue();

 MCE::Shared->start() unless $has_IO_FDPass;

Regarding mce_open, C<IO::FDPass> is needed for constructing a shared-handle
from a non-shared handle not yet available inside the shared-manager process.
The workaround is to have the non-shared handle made before the shared-manager
is started. Passing a file by reference is fine for the three STD* handles.

 # The shared-manager knows of \*STDIN, \*STDOUT, \*STDERR.

 mce_open my $shared_in,  "<",  \*STDIN;   # ok
 mce_open my $shared_out, ">>", \*STDOUT;  # ok
 mce_open my $shared_err, ">>", \*STDERR;  # ok
 mce_open my $shared_fh1, "<",  "/path/to/sequence.fasta";  # ok
 mce_open my $shared_fh2, ">>", "/path/to/results.log";     # ok

 mce_open my $shared_fh, ">>", \*NON_SHARED_FH;  # requires IO::FDPass

The L<IO::FDPass> module is known to work reliably on most platforms.
Install 1.1 or later to rid of limitations described above.

 perl -MIO::FDPass -le "print 'Cheers! Perl has IO::FDPass.'"

=head1 INDEX

L<MCE|MCE>, L<MCE::Hobo>, L<MCE::Shared>

=head1 AUTHOR

Mario E. Roy, S<E<lt>marioeroy AT gmail DOT comE<gt>>

=cut

