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

our $VERSION = '1.829';

use MCE::Shared::Base ();
use MCE::Util ();
use MCE::Mutex ();
use bytes;

use overload (
   q("")    => \&MCE::Shared::Base::_stringify,
   q(0+)    => \&MCE::Shared::Base::_numify,
   fallback => 1
);

my $LF = "\012"; Internals::SvREADONLY($LF, 1);
my $_has_threads = $INC{'threads.pm'} ? 1 : 0;
my $_tid = $_has_threads ? threads->tid() : 0;
my $_reset_flg = 1;

sub new {
   my ($_class, $_cv) = (shift, {});

   $_cv->{_init_pid} = $_has_threads ? $$ .'.'. $_tid : $$;
   $_cv->{_mutex}    = MCE::Mutex->new( impl => 'Channel' );
   $_cv->{_value}    = shift || 0;
   $_cv->{_count}    = 0;

   MCE::Util::_sock_pair($_cv, qw(_cr_sock _cw_sock));

   MCE::Shared::Object::_reset(), $_reset_flg = ''
      if $_reset_flg && $INC{'MCE/Shared/Server.pm'};

   bless $_cv, $_class;
}

sub CLONE {
   $_tid = threads->tid() if $_has_threads;
}

sub DESTROY {
   my ($_cv) = @_;
   my $_pid  = $_has_threads ? $$ .'.'. $_tid : $$;

   if ($_cv->{_init_pid} eq $_pid) {
      MCE::Util::_destroy_socks($_cv, qw(_cw_sock _cr_sock));
      delete $_cv->{'_mutex'};
   }

   return;
}

###############################################################################
## ----------------------------------------------------------------------------
## Public methods.
##
###############################################################################

sub get { $_[0]->{_value} }
sub set { $_[0]->{_value} = $_[1] }

# The following methods applies to sharing only and are handled by
# MCE::Shared::Object.

sub lock      { }
sub unlock    { }

sub broadcast { }
sub signal    { }
sub timedwait { }
sub wait      { }

###############################################################################
## ----------------------------------------------------------------------------
## Sugar API, mostly resembles http://redis.io/commands#string primitives.
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
         };
         for my $_i (1 .. $_var->{_count}) {
            1 until syswrite($_var->{_cw_sock}, $LF) || ($! && !$!{'EINTR'});
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
         };
         if ( $_var->{_count} >= 0 ) {
            1 until syswrite($_var->{_cw_sock}, $LF) || ($! && !$!{'EINTR'});
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

use Time::HiRes qw( sleep );
use bytes;

no overloading;

my $_is_MSWin32 = ($^O eq 'MSWin32') ? 1 : 0;

my ($_DAT_W_SOCK, $_DAU_W_SOCK, $_dat_ex, $_dat_un, $_chn, $_obj);

sub _init_condvar {
   ($_DAT_W_SOCK, $_DAU_W_SOCK, $_dat_ex, $_dat_un, $_chn, $_obj) = @_;

   return;
}

# lock ( )

sub lock {
   return unless ( my $_CV = $_obj->{ $_[0]->[0] } );
   return unless ( exists $_CV->{_mutex} );

   $_CV->{_mutex}->lock;
}

# unlock ( )

sub unlock {
   return unless ( my $_CV = $_obj->{ $_[0]->[0] } );
   return unless ( exists $_CV->{_mutex} );

   $_CV->{_mutex}->unlock;
}

# broadcast ( floating_seconds )
# broadcast ( )

sub broadcast {
   my $_id = $_[0]->[0];
   return unless ( my $_CV = $_obj->{ $_id } );
   return unless ( exists $_CV->{_cr_sock} );

   sleep($_[1]) if defined $_[1];

   _req1('O~CVB', $_id.$LF);
   $_CV->{_mutex}->unlock();

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
   $_CV->{_mutex}->unlock();

   sleep(0);
}

# timedwait ( floating_seconds )

sub timedwait {
   my $_id = $_[0]->[0];
   my $_timeout = $_[1];

   return unless ( my $_CV = $_obj->{ $_id } );
   return unless ( exists $_CV->{_cr_sock} );
   return $_[0]->wait() unless $_timeout;

   _croak('Condvar: timedwait (timeout) is not an integer')
      if (!looks_like_number($_timeout) || int($_timeout) != $_timeout);

   _req1('O~CVW', $_id.$LF);
   $_CV->{_mutex}->unlock();

   local $@; eval {
      local $SIG{ALRM} = sub { die "alarm clock restart\n" };
      alarm $_timeout unless $_is_MSWin32;

      die "alarm clock restart\n"
         if $_is_MSWin32 && MCE::Util::_sock_ready($_CV->{_cr_sock}, $_timeout);

      1 until sysread($_CV->{_cr_sock}, my($_b), 1) || ($! && !$!{'EINTR'});

      alarm 0;
   };

   alarm 0;

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
   $_CV->{_mutex}->unlock();

   MCE::Util::_sock_ready($_CV->{_cr_sock}) if $_is_MSWin32;
   1 until sysread($_CV->{_cr_sock}, my($_b), 1) || ($! && !$!{'EINTR'});

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

This document describes MCE::Shared::Condvar version 1.829

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

 my $microsecs = ( lc $^O =~ /mswin|mingw|msys|cygwin/ ) ? 0 : 200;

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

=over 3

=item new ( [ value ] )

Constructs a new condition variable. Its value defaults to C<0> when C<value>
is not specified.

 use MCE::Shared;

 $cv = MCE::Shared->condvar( 100 );
 $cv = MCE::Shared->condvar;

=item set ( value )

Sets the value associated with the C<cv> object. The new value is returned
in scalar context.

 $val = $cv->set( 10 );
 $cv->set( 10 );

=item get

Returns the value associated with the C<cv> object.

 $val = $cv->get;

=item len

Returns the length of the value. It returns the C<undef> value if the value
is not defined.

 $len = $var->len;

=item lock

Attempts to grab the lock and waits if not available. Multiple calls to
C<$cv->lock> by the same process or thread is safe. The mutex will remain
locked until C<$cv->unlock> is called.

 $cv->lock;

=item unlock

Releases the lock. A held lock by an exiting process or thread is released
automatically.

 $cv->unlock;

=item signal ( [ floating_seconds ] )

Releases a held lock on the variable. Then, unblocks one process or thread
that's C<wait>ing on that variable. The variable is *not* locked upon return.

Optionally, delay C<floating_seconds> before signaling.

 $count->signal;
 $count->signal( 0.5 );

=item broadcast ( [ floating_seconds ] )

The C<broadcast> method works similarly to C<signal>. It releases a held lock
on the variable. Then, unblocks all the processes or threads that are blocked
in a condition C<wait> on the variable, rather than only one. The variable is
*not* locked upon return.

Optionally, delay C<floating_seconds> before broadcasting.

 $count->broadcast;
 $count->broadcast( 0.5 );

=item wait

Releases a held lock on the variable. Then, waits until another thread does a
C<signal> or C<broadcast> for the same variable. The variable is *not* locked
upon return.

 $count->wait() while $state->get() eq "bar";

=item timedwait ( floating_seconds )

Releases a held lock on the variable. Then, waits until another thread does a
C<signal> or C<broadcast> for the same variable or if the timeout exceeds
C<floating_seconds>.

A false value is returned if the timeout is reached, and a true value otherwise.
In either case, the variable is *not* locked upon return.

 $count->timedwait( 10 ) while $state->get() eq "foo";

=back

=head1 SUGAR METHODS

This module is equipped with sugar methods to not have to call C<set>
and C<get> explicitly. In shared context, the benefit is atomicity and
reduction in inter-process communication.

The API resembles a subset of the Redis primitives
L<http://redis.io/commands#strings> without the key argument.

=over 3

=item append ( value )

Appends a value at the end of the current value and returns its new length.

 $len = $cv->append( "foo" );

=item decr

Decrements the value by one and returns its new value.

 $num = $cv->decr;

=item decrby ( number )

Decrements the value by the given number and returns its new value.

 $num = $cv->decrby( 2 );

=item getdecr

Decrements the value by one and returns its old value.

 $old = $cv->getdecr;

=item getincr

Increments the value by one and returns its old value.

 $old = $cv->getincr;

=item getset ( value )

Sets the value and returns its old value.

 $old = $cv->getset( "baz" );

=item incr

Increments the value by one and returns its new value.

 $num = $cv->incr;

=item incrby ( number )

Increments the value by the given number and returns its new value.

 $num = $cv->incrby( 2 );

=back

=head1 CREDITS

The conditional locking aspect is inspired by L<threads::shared>.

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

