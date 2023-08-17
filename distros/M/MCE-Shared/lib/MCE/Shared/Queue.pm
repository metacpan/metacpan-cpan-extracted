###############################################################################
## ----------------------------------------------------------------------------
## Hybrid-queue helper class.
##
###############################################################################

package MCE::Shared::Queue;

use strict;
use warnings;

use 5.010001;

no warnings qw( threads recursion uninitialized numeric );

our $VERSION = '1.885';

## no critic (Subroutines::ProhibitExplicitReturnUndef)

use Scalar::Util qw( looks_like_number );
use MCE::Shared::Base ();
use MCE::Util ();
use MCE::Mutex ();

use overload (
   q("")    => \&MCE::Shared::Base::_stringify,
   q(0+)    => \&MCE::Shared::Base::_numify,
   fallback => 1
);

###############################################################################
## ----------------------------------------------------------------------------
## Attributes used internally.
## _qr_sock _qw_sock _datp _datq _dsem _heap _init_pid _porder _type
## _ar_sock _aw_sock _asem _tsem
##
###############################################################################

our ($HIGHEST, $LOWEST, $FIFO, $LIFO, $LILO, $FILO) = (1, 0, 1, 0, 1, 0);
my  ($PORDER, $TYPE, $AWAIT) = ($HIGHEST, $FIFO, 0);

my $LF = "\012"; Internals::SvREADONLY($LF, 1);
my $_tid = $INC{'threads.pm'} ? threads->tid() : 0;
my $_reset_flg = 1;

my %_valid_fields_new = map { $_ => 1 } qw(
   await barrier fast porder queue type
);

sub _croak {
   goto &MCE::Shared::Base::_croak;
}
sub CLONE {
   $_tid = threads->tid() if $INC{'threads.pm'};
}

sub DESTROY {
   my ($_Q) = @_;
   my $_pid = $_tid ? $$ .'.'. $_tid : $$;

   undef $_Q->{_datp}, undef $_Q->{_datq}, undef $_Q->{_heap};

   if ($_Q->{_init_pid} eq $_pid) {
      MCE::Util::_destroy_socks($_Q, qw(_aw_sock _ar_sock _qw_sock _qr_sock));
   }

   return;
}

###############################################################################
## ----------------------------------------------------------------------------
## Instance instantiation.
##
###############################################################################

# new ( options )

sub new {
   my ($_class, %_argv) = @_;
   my $_Q = {}; bless($_Q, ref($_class) || $_class);

   for my $_p (keys %_argv) {
      _croak("Queue: ($_p) is not a valid constructor argument")
         unless (exists $_valid_fields_new{$_p});
   }

   $_Q->{_asem} =  0;  # Semaphore count variable for the ->await method
   $_Q->{_datp} = {};  # Priority data { p1 => [ ], p2 => [ ], pN => [ ] }
   $_Q->{_heap} = [];  # Priority heap [ pN, p2, p1 ] in heap order
                       # fyi, _datp will always dequeue before _datq

   # --------------------------------------------------------------------------

   $_Q->{_await}  = defined $_argv{await}  ? $_argv{await}  : $AWAIT;
   $_Q->{_porder} = defined $_argv{porder} ? $_argv{porder} : $PORDER;
   $_Q->{_type}   = defined $_argv{type}   ? $_argv{type}   : $TYPE;

   if (exists $_argv{queue}) {
      _croak('Queue: (queue) is not an ARRAY reference')
         if (ref $_argv{queue} ne 'ARRAY');
      $_Q->{_datq} = $_argv{queue};
   }
   else {
      $_Q->{_datq} = [];
   }

   # --------------------------------------------------------------------------

   $_Q->{_qr_mutex} = MCE::Mutex->new();
   $_Q->{_init_pid} = $_tid ? $$ .'.'. $_tid : $$;
   $_Q->{_dsem}     = 0;

   MCE::Util::_sock_pair($_Q, qw(_qr_sock _qw_sock), undef, 1);
   MCE::Util::_sock_pair($_Q, qw(_ar_sock _aw_sock), undef, 1) if $_Q->{_await};

   MCE::Shared::Object::_reset(), $_reset_flg = ''
      if ($_reset_flg && $INC{'MCE/Shared/Server.pm'});

   return $_Q;
}

###############################################################################
## ----------------------------------------------------------------------------
## Public methods.
##
###############################################################################

# await ( pending_threshold )

sub await {
   # Handled by MCE::Shared::Object when shared.
   return;
}

# clear ( ) 

sub clear {
   my ($_Q) = @_;

   %{ $_Q->{_datp} } = ();
   @{ $_Q->{_datq} } = ();
   @{ $_Q->{_heap} } = ();

   return;
}

# end ( )

sub end {
   my ($_Q) = @_;

   if (!exists $_Q->{_ended}) {
      for my $_i (1 .. $_Q->{_dsem}) { syswrite($_Q->{_qw_sock}, $LF) }
      $_Q->{_dsem} = 0, $_Q->{_ended} = undef;
   }

   return;
}

# enqueue ( item [, item, ... ] )

sub enqueue {
   my $_Q = shift;

   return unless (scalar @_);

   if (exists $_Q->{_ended}) {
      warn "Queue: (enqueue) called on queue that has been 'end'ed\n";
      return;
   }

   if ($_Q->{_dsem}) {
      for my $_i (1 .. scalar @_) {
         $_Q->{_dsem} -= 1, syswrite($_Q->{_qw_sock}, $LF);
         last unless $_Q->{_dsem};
      }
   }

   push @{ $_Q->{_datq} }, @_;

   return;
}

# enqueuep ( priority, item [, item, ... ] )

sub enqueuep {
   my ($_Q, $_p) = (shift, shift);

   _croak('Queue: (enqueuep priority) is not an integer')
      if (!looks_like_number($_p) || int($_p) != $_p);

   return unless (scalar @_);

   if (exists $_Q->{_ended}) {
      warn "Queue: (enqueuep) called on queue that has been 'end'ed\n";
      return;
   }

   if ($_Q->{_dsem}) {
      for my $_i (1 .. scalar @_) {
         $_Q->{_dsem} -= 1, syswrite($_Q->{_qw_sock}, $LF);
         last unless $_Q->{_dsem};
      }
   }

   $_Q->_enqueuep($_p, @_);

   return;
}

# dequeue ( )
# dequeue ( count )

sub dequeue {
   my ($_Q, $_cnt) = @_;
   my (@_items, $_has_data, $_buf);

   if (defined $_cnt && $_cnt ne '1') {
      _croak('Queue: (dequeue count argument) is not valid')
         if (!looks_like_number($_cnt) || int($_cnt) != $_cnt || $_cnt < 1);

      my $_pending = @{ $_Q->{_datq} };

      if ($_pending < $_cnt && scalar @{ $_Q->{_heap} }) {
         for my $_h (@{ $_Q->{_heap} }) {
            $_pending += @{ $_Q->{_datp}->{$_h} };
         }
      }
      $_cnt = $_pending if $_pending < $_cnt;

      for my $_i (1 .. $_cnt) { push @_items, $_Q->_dequeue() }
   }
   else {
      $_has_data = ( @{ $_Q->{_datq} } || @{ $_Q->{_heap} } ) ? 1 : 0;
      $_buf      = $_Q->_dequeue();
   }

   return @_items if (scalar  @_items);
   return $_buf   if ($_has_data);
   return ()      if (exists  $_Q->{_ended});

   $_Q->{_dsem} += 1, MCE::Util::_sysread($_Q->{_qr_sock}, my($_next), 1);

   goto \&dequeue;
}

# dequeue_nb ( )
# dequeue_nb ( count )

sub dequeue_nb {
   my ($_Q, $_cnt) = @_;

   if (defined $_cnt && $_cnt ne '1') {
      _croak('Queue: (dequeue_nb count argument) is not valid')
         if (!looks_like_number($_cnt) || int($_cnt) != $_cnt || $_cnt < 1);

      my $_pending = @{ $_Q->{_datq} };

      if ($_pending < $_cnt && scalar @{ $_Q->{_heap} }) {
         for my $_h (@{ $_Q->{_heap} }) {
            $_pending += @{ $_Q->{_datp}->{$_h} };
         }
      }

      $_cnt = $_pending if $_pending < $_cnt;

      return map { $_Q->_dequeue() } 1 .. $_cnt;
   }

   my $_buf = $_Q->_dequeue();

   return defined($_buf) ? $_buf : ();
}

# dequeue_timed ( timeout )
# dequeue_timed ( timeout, count )

sub dequeue_timed {
   my ($_Q, $_timeout, $_cnt) = @_;

   if (defined $_timeout) {       
      _croak('Queue: (dequeue_timed timeout argument) is not valid')
         if (!looks_like_number($_timeout));
   }

   if (defined $_cnt && $_cnt ne '1') {
      _croak('Queue: (dequeue_timed count argument) is not valid')
         if (!looks_like_number($_cnt) || int($_cnt) != $_cnt || $_cnt < 1);

      my $_pending = @{ $_Q->{_datq} };

      if ($_pending < $_cnt && scalar @{ $_Q->{_heap} }) {
         for my $_h (@{ $_Q->{_heap} }) {
            $_pending += @{ $_Q->{_datp}->{$_h} };
         }
      }

      $_cnt = $_pending if $_pending < $_cnt;

      return map { $_Q->_dequeue() } 1 .. $_cnt;
   }

   my $_buf = $_Q->_dequeue();

   return defined($_buf) ? $_buf : ();
}

# pending ( )

sub pending {
   my ($_Q) = @_;
   my $_pending = @{ $_Q->{_datq} };

   if (scalar @{ $_Q->{_heap} }) {
      for my $_h (@{ $_Q->{_heap} }) {
         $_pending += @{ $_Q->{_datp}->{$_h} };
      }
   }

   return (exists $_Q->{_ended})
      ? $_pending ? $_pending : undef
      : $_pending;
}

# insert ( index, item [, item, ... ] )

sub insert {
   my ($_Q, $_i) = (shift, shift);

   _croak('Queue: (insert index) is not an integer')
      if (!looks_like_number($_i) || int($_i) != $_i);

   return unless (scalar @_);

   if (exists $_Q->{_ended}) {
      warn "Queue: (insert) called on queue that has been 'end'ed\n";
      return;
   }

   if ($_Q->{_dsem}) {
      for my $_i (1 .. scalar @_) {
         $_Q->{_dsem} -= 1, syswrite($_Q->{_qw_sock}, $LF);
         last unless $_Q->{_dsem};
      }
   }

   if (abs($_i) > scalar @{ $_Q->{_datq} }) {
      if ($_i >= 0) {
         if ($_Q->{_type}) {
            push @{ $_Q->{_datq} }, @_;
         } else {
            unshift @{ $_Q->{_datq} }, @_;
         }
      }
      else {
         if ($_Q->{_type}) {
            unshift @{ $_Q->{_datq} }, @_;
         } else {
            push @{ $_Q->{_datq} }, @_;
         }
      }
   }
   else {
      if (!$_Q->{_type}) {
         $_i = ($_i >= 0)
            ? scalar(@{ $_Q->{_datq} }) - $_i
            : abs($_i);
      }
      splice @{ $_Q->{_datq} }, $_i, 0, @_;
   }

   return;
}

# insertp ( priority, index, item [, item, ... ] )

sub insertp {
   my ($_Q, $_p, $_i) = (shift, shift, shift);

   _croak('Queue: (insertp priority) is not an integer')
      if (!looks_like_number($_p) || int($_p) != $_p);
   _croak('Queue: (insertp index) is not an integer')
      if (!looks_like_number($_i) || int($_i) != $_i);

   return unless (scalar @_);

   if (exists $_Q->{_ended}) {
      warn "Queue: (insertp) called on queue that has been 'end'ed\n";
      return;
   }

   if ($_Q->{_dsem}) {
      for my $_i (1 .. scalar @_) {
         $_Q->{_dsem} -= 1, syswrite($_Q->{_qw_sock}, $LF);
         last unless $_Q->{_dsem};
      }
   }

   if (exists $_Q->{_datp}->{$_p} && scalar @{ $_Q->{_datp}->{$_p} }) {

      if (abs($_i) > scalar @{ $_Q->{_datp}->{$_p} }) {
         if ($_i >= 0) {
            if ($_Q->{_type}) {
               push @{ $_Q->{_datp}->{$_p} }, @_;
            } else {
               unshift @{ $_Q->{_datp}->{$_p} }, @_;
            }
         }
         else {
            if ($_Q->{_type}) {
               unshift @{ $_Q->{_datp}->{$_p} }, @_;
            } else {
               push @{ $_Q->{_datp}->{$_p} }, @_;
            }
         }
      }
      else {
         if (!$_Q->{_type}) {
            $_i = ($_i >=0)
               ? scalar(@{ $_Q->{_datp}->{$_p} }) - $_i
               : abs($_i);
         }
         splice @{ $_Q->{_datp}->{$_p} }, $_i, 0, @_;
      }
   }
   else {
      $_Q->_enqueuep($_p, @_);
   }

   return;
}

# peek ( index )
# peek ( )

sub peek {
   my ($_Q, $_i) = @_;

   if ($_i) {
      _croak('Queue: (peek index) is not an integer')
         if (!looks_like_number($_i) || int($_i) != $_i);
   }
   else { $_i = 0 }

   return undef if (abs($_i) > scalar @{ $_Q->{_datq} });

   if (!$_Q->{_type}) {
      $_i = ($_i >= 0)
         ? scalar(@{ $_Q->{_datq} }) - ($_i + 1)
         : abs($_i + 1);
   }

   return $_Q->{_datq}->[$_i];
}

# peekp ( priority, index )
# peekp ( priority )

sub peekp {
   my ($_Q, $_p, $_i) = @_;

   if ($_i) {
      _croak('Queue: (peekp index) is not an integer')
         if (!looks_like_number($_i) || int($_i) != $_i);
   }
   else { $_i = 0 }

   _croak('Queue: (peekp priority) is not an integer')
      if (!looks_like_number($_p) || int($_p) != $_p);

   return undef unless (exists $_Q->{_datp}->{$_p});
   return undef if (abs($_i) > scalar @{ $_Q->{_datp}->{$_p} });

   if (!$_Q->{_type}) {
      $_i = ($_i >= 0)
         ? scalar(@{ $_Q->{_datp}->{$_p} }) - ($_i + 1)
         : abs($_i + 1);
   }

   return $_Q->{_datp}->{$_p}->[$_i];
}

# peekh ( index )
# peekh ( )

sub peekh {
   my ($_Q, $_i) = @_;

   if ($_i) {
      _croak('Queue: (peekh index) is not an integer')
         if (!looks_like_number($_i) || int($_i) != $_i);
   }
   else { $_i = 0 }

   return undef if (abs($_i) > scalar @{ $_Q->{_heap} });
   return $_Q->{_heap}->[$_i];
}

# heap ( )

sub heap {
   return @{ shift->{_heap} };
}

###############################################################################
## ----------------------------------------------------------------------------
## Private methods.
##
###############################################################################

# Add items to the tail of the queue with priority level.

sub _enqueuep {
   my ($_Q, $_p) = (shift, shift);

   # Enlist priority into the heap.
   if (!exists $_Q->{_datp}->{$_p} || @{ $_Q->{_datp}->{$_p} } == 0) {

      unless (scalar @{ $_Q->{_heap} }) {
         push @{ $_Q->{_heap} }, $_p;
      }
      elsif ($_Q->{_porder}) {
         $_Q->_heap_insert_high($_p);
      }
      else {
         $_Q->_heap_insert_low($_p);
      }
   }

   # Append item(s) into the queue.
   push @{ $_Q->{_datp}->{$_p} }, @_;

   return;
}

# Return one item from the queue.

sub _dequeue {
   my ($_Q) = @_;

   # Return item from the non-priority queue.
   unless (scalar @{ $_Q->{_heap} }) {
      return ($_Q->{_type})
         ? shift @{ $_Q->{_datq} } : pop @{ $_Q->{_datq} };
   }

   my $_p = $_Q->{_heap}->[0];

   # Delist priority from the heap when 1 item remains.
   shift @{ $_Q->{_heap} } if (@{ $_Q->{_datp}->{$_p} } == 1);

   # Return item from the priority queue.
   return ($_Q->{_type})
      ? shift @{ $_Q->{_datp}->{$_p} } : pop @{ $_Q->{_datp}->{$_p} };
}

# Helper method for getting the reference to the underlying array.
# Use with test scripts for comparing data only (not a public API).

sub _get_aref {
   my ($_Q, $_p) = @_;

   if (defined $_p) {
      _croak('Queue: (get_aref priority) is not an integer')
         if (!looks_like_number($_p) || int($_p) != $_p);

      return undef unless (exists $_Q->{_datp}->{$_p});
      return $_Q->{_datp}->{$_p};
   }

   return $_Q->{_datq};
}

# Insert priority into the heap. A lower priority level comes first.

sub _heap_insert_low {
   my ($_Q, $_p) = @_;

   # Insert priority at the head of the heap.
   if ($_p < $_Q->{_heap}->[0]) {
      unshift @{ $_Q->{_heap} }, $_p;
   }

   # Insert priority at the end of the heap.
   elsif ($_p > $_Q->{_heap}->[-1]) {
      push @{ $_Q->{_heap} }, $_p;
   }

   # Insert priority through binary search.
   else {
      my $_lower = 0; my $_upper = @{ $_Q->{_heap} };

      while ($_lower < $_upper) {
         my $_midpoint = $_lower + (($_upper - $_lower) >> 1);
         if ($_p > $_Q->{_heap}->[$_midpoint]) {
            $_lower = $_midpoint + 1;
         } else {
            $_upper = $_midpoint;
         }
      }

      # Insert priority into the heap.
      splice @{ $_Q->{_heap} }, $_lower, 0, $_p;
   }

   return;
}

# Insert priority into the heap. A higher priority level comes first.

sub _heap_insert_high {
   my ($_Q, $_p) = @_;

   # Insert priority at the head of the heap.
   if ($_p > $_Q->{_heap}->[0]) {
      unshift @{ $_Q->{_heap} }, $_p;
   }

   # Insert priority at the end of the heap.
   elsif ($_p < $_Q->{_heap}->[-1]) {
      push @{ $_Q->{_heap} }, $_p;
   }

   # Insert priority through binary search.
   else {
      my $_lower = 0; my $_upper = @{ $_Q->{_heap} };

      while ($_lower < $_upper) {
         my $_midpoint = $_lower + (($_upper - $_lower) >> 1);
         if ($_p < $_Q->{_heap}->[$_midpoint]) {
            $_lower = $_midpoint + 1;
         } else {
            $_upper = $_midpoint;
         }
      }

      # Insert priority into the heap.
      splice @{ $_Q->{_heap} }, $_lower, 0, $_p;
   }

   return;
}

###############################################################################
## ----------------------------------------------------------------------------
## Server functions.
##
###############################################################################

{
   use bytes;

   use constant {
      SHR_O_QUA => 'O~QUA',  # Queue await
      SHR_O_QUD => 'O~QUD',  # Queue dequeue
      SHR_O_QUN => 'O~QUN',  # Queue dequeue non-blocking
      SHR_O_QUT => 'O~QUT',  # Queue dequeue timed
   };

   my (
      $_DAU_R_SOCK_REF, $_DAU_R_SOCK, $_obj, $_freeze, $_thaw,
      $_cnt, $_id, $_has_data, $_pending, $_t
   );

   my %_output_function = (

      SHR_O_QUA.$LF => sub {                      # Queue await
         $_DAU_R_SOCK = ${ $_DAU_R_SOCK_REF };

         chomp($_id = <$_DAU_R_SOCK>),
         chomp($_t  = <$_DAU_R_SOCK>);

         my $_Q = $_obj->{ $_id } || do {
            print {$_DAU_R_SOCK} $LF;
            return;
         };
         $_Q->{_tsem} = $_t;

         if ($_Q->pending() <= $_t) {
            syswrite($_Q->{_aw_sock}, $LF);
         } else {
            $_Q->{_asem} += 1;
         }

         print {$_DAU_R_SOCK} $LF;

         return;
      },

      SHR_O_QUD.$LF => sub {                      # Queue dequeue
         $_DAU_R_SOCK = ${ $_DAU_R_SOCK_REF };

         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_cnt = <$_DAU_R_SOCK>);

         $_cnt = 0 if ($_cnt == 1);

         my $_Q = $_obj->{ $_id } || do {
            print {$_DAU_R_SOCK} '-1'.$LF;
            return;
         };

         my (@_items, $_buf);

         if ($_cnt) {
            $_pending = @{ $_Q->{_datq} };

            if ($_pending < $_cnt && scalar @{ $_Q->{_heap} }) {
               for my $_h (@{ $_Q->{_heap} }) {
                  $_pending += @{ $_Q->{_datp}->{$_h} };
               }
            }
            $_cnt = $_pending if $_pending < $_cnt;

            for my $_i (1 .. $_cnt) { push @_items, $_Q->_dequeue() }
         }
         else {
            $_has_data = ( @{ $_Q->{_datq} } || @{ $_Q->{_heap} } ) ? 1 : 0;
            $_buf      = $_Q->_dequeue();
         }

         if ($_cnt) {
            $_buf = $_freeze->(\@_items);
            print {$_DAU_R_SOCK} length($_buf).$LF, $_buf;
         }
         elsif ($_has_data) {
            $_buf = $_freeze->([ $_buf ]);
            print {$_DAU_R_SOCK} length($_buf).$LF, $_buf;
         }
         elsif (exists $_Q->{_ended}) {
            print {$_DAU_R_SOCK} '-2'.$LF;
         }
         else {
            print {$_DAU_R_SOCK} '-1'.$LF;
            $_Q->{_dsem} += 1;
         }

         if ($_Q->{_await} && $_Q->{_asem} && $_Q->pending() <= $_Q->{_tsem}) {
            for my $_i (1 .. $_Q->{_asem}) {
               syswrite($_Q->{_aw_sock}, $LF);
            }
            $_Q->{_asem} = 0;
         }

         return;
      },

      SHR_O_QUN.$LF => sub {                      # Queue dequeue non-blocking
         $_DAU_R_SOCK = ${ $_DAU_R_SOCK_REF };

         chomp($_id  = <$_DAU_R_SOCK>),
         chomp($_cnt = <$_DAU_R_SOCK>);

         my $_Q = $_obj->{ $_id } || do {
            print {$_DAU_R_SOCK} '-1'.$LF;
            return;
         };

         if ($_cnt == 1) {
            my $_buf = $_Q->_dequeue();

            if (defined $_buf) {
               $_buf = $_freeze->([ $_buf ]);
               print {$_DAU_R_SOCK} length($_buf).$LF, $_buf;
            }
            else {
               print {$_DAU_R_SOCK} '-1'.$LF;
            }
         }
         else {
            my @_items;
            my $_pending = @{ $_Q->{_datq} };

            if ($_pending < $_cnt && scalar @{ $_Q->{_heap} }) {
               for my $_h (@{ $_Q->{_heap} }) {
                  $_pending += @{ $_Q->{_datp}->{$_h} };
               }
            }
            $_cnt = $_pending if $_pending < $_cnt;

            for my $_i (1 .. $_cnt) { push @_items, $_Q->_dequeue() }

            if ($_cnt) {
               my $_buf = $_freeze->(\@_items);
               print {$_DAU_R_SOCK} length($_buf).$LF, $_buf;
            }
            else {
               print {$_DAU_R_SOCK} '-1'.$LF;
            }
         }

         if ($_Q->{_await} && $_Q->{_asem} && $_Q->pending() <= $_Q->{_tsem}) {
            for my $_i (1 .. $_Q->{_asem}) {
               syswrite($_Q->{_aw_sock}, $LF);
            }
            $_Q->{_asem} = 0;
         }

         return;
      },

      SHR_O_QUT.$LF => sub {                      # Queue dequeue timed
         $_DAU_R_SOCK = ${ $_DAU_R_SOCK_REF };

         chomp($_id = <$_DAU_R_SOCK>);

         my $_Q = $_obj->{ $_id } || do {
            print {$_DAU_R_SOCK} $LF;
            return;
         };

         $_Q->{_dsem} -= 1 if $_Q->{_dsem};

         print {$_DAU_R_SOCK} $LF;

         return;
      },

   );

   sub _init_mgr {
      my $_function;
      ( $_DAU_R_SOCK_REF, $_obj, $_function, $_freeze, $_thaw ) = @_;

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

use bytes;

no overloading;

my $_is_MSWin32 = ($^O eq 'MSWin32') ? 1 : 0;

my ($_DAT_LOCK, $_DAT_W_SOCK, $_DAU_W_SOCK, $_dat_ex, $_dat_un, $_chn, $_obj,
    $_freeze, $_thaw);

sub _init_queue {
   ($_DAT_LOCK, $_DAT_W_SOCK, $_DAU_W_SOCK, $_dat_ex, $_dat_un, $_chn, $_obj,
    $_freeze, $_thaw) = @_;

   return;
}

sub _req_queue {
   local $\ = undef if (defined $\);
   local $/ = $LF if ($/ ne $LF);
   local $MCE::Signal::SIG;

   {
      local $MCE::Signal::IPC = 1;
      $_is_MSWin32 ? CORE::lock $_DAT_LOCK : $_dat_ex->();

      print({$_DAT_W_SOCK} $_[0].$LF . $_chn.$LF),
      print({$_DAU_W_SOCK} $_[1]);
      chomp($_[2] = <$_DAU_W_SOCK>);

      read($_DAU_W_SOCK, $_[3], $_[2]) if ($_[2] > 0);

      $_dat_un->() if !$_is_MSWin32;
   }

   CORE::kill($MCE::Signal::SIG, $$) if $MCE::Signal::SIG;
}

sub await {
   my $_id = shift()->[0];
   return unless ( my $_Q = $_obj->{ $_id } );
   return unless ( exists $_Q->{_qr_sock} );

   my $_t = shift || 0;

   _croak('Queue: (await) is not enabled for this queue')
      unless (exists $_Q->{_ar_sock});
   _croak('Queue: (await threshold) is not an integer')
      if (!looks_like_number($_t) || int($_t) != $_t);

   $_t = 0 if ($_t < 0);
   _req1('O~QUA', $_id.$LF . $_t.$LF);

   MCE::Util::_sock_ready($_Q->{_ar_sock}) if $_is_MSWin32;
   MCE::Util::_sysread($_Q->{_ar_sock}, my($_b), 1);

   return;
}

sub dequeue {
   my ($self, $_cnt) = @_;
   my $_id = $self->[0];

   return unless ( my $_Q = $_obj->{ $_id } );
   return unless ( exists $_Q->{_qr_sock} );

   if (defined $_cnt && $_cnt ne '1') {
      _croak('Queue: (dequeue count argument) is not valid')
         if (!looks_like_number($_cnt) || int($_cnt) != $_cnt || $_cnt < 1);
   } else {
      $_cnt = 1;
   }

   _req_queue('O~QUD', $_id.$LF . $_cnt.$LF, my($_len), my($_buf));

   return $_thaw->($_buf)[0]   if ($_len > 0 && $_cnt == 1);
   return @{ $_thaw->($_buf) } if ($_len > 0);
   return                      if ($_len == -2);

   MCE::Util::_sock_ready($_Q->{_qr_sock}) if $_is_MSWin32;
   MCE::Util::_sysread($_Q->{_qr_sock}, my($_next), 1);

   goto \&dequeue;
}

sub dequeue_nb {
   my ($self, $_cnt) = @_;
   my $_id = $self->[0];

   return unless ( my $_Q = $_obj->{ $_id } );
   return unless ( exists $_Q->{_qr_sock} );

   if (defined $_cnt && $_cnt ne '1') {
      _croak('Queue: (dequeue_nb count argument) is not valid')
         if (!looks_like_number($_cnt) || int($_cnt) != $_cnt || $_cnt < 1);
   } else {
      $_cnt = 1;
   }

   _req_queue('O~QUN', $_id.$LF . $_cnt.$LF, my($_len), my($_buf));

   return if ($_len < 0);

   ($_cnt == 1) ? $_thaw->($_buf)[0] : @{ $_thaw->($_buf) };
}

sub dequeue_timed {
   my ($self, $_timeout, $_cnt) = @_;
   my $_id = $self->[0];
   my $_start;

   return unless ( my $_Q = $_obj->{ $_id } );
   return unless ( exists $_Q->{_qr_sock} );

   if (defined $_timeout) {
      _croak('Queue: (dequeue_timed timeout argument) is not valid')
         if (!looks_like_number($_timeout) || $_timeout < 0);
      $_start = MCE::Util::_time();
   }

   if (defined $_cnt && $_cnt ne '1') {
      _croak('Queue: (dequeue_timed count argument) is not valid')
         if (!looks_like_number($_cnt) || int($_cnt) != $_cnt || $_cnt < 1);
   } else {
      $_cnt = 1;
   }

   if (! $_timeout || $_timeout < 0.0) {
      _req_queue('O~QUN', $_id.$LF . $_cnt.$LF, my($_len), my($_buf));
      return if ($_len < 0);
      return ($_cnt == 1) ? $_thaw->($_buf)[0] : @{ $_thaw->($_buf) };
   }

   _req_queue('O~QUD', $_id.$LF . $_cnt.$LF, my($_len), my($_buf));

   return $_thaw->($_buf)[0]   if ($_len > 0 && $_cnt == 1);
   return @{ $_thaw->($_buf) } if ($_len > 0);
   return                      if ($_len == -2);

   $_Q->{_qr_mutex}->lock();
   $_timeout = $_timeout - (MCE::Util::_time() - $_start) - 0.045;
   $_timeout = 0.0 if $_timeout < 0.045;

   CORE::vec(my $_r, CORE::fileno($_Q->{_qr_sock}), 1) = 1;
   if (CORE::select($_r, undef, undef, $_timeout) > 0) {
      MCE::Util::_sysread($_Q->{_qr_sock}, my($_next), 1);
      $_Q->{_qr_mutex}->unlock();
      _req_queue('O~QUN', $_id.$LF . $_cnt.$LF, my($_len), my($_buf));
      return if ($_len < 0);
      return ($_cnt == 1) ? $_thaw->($_buf)[0] : @{ $_thaw->($_buf) };
   }

   $_Q->{_qr_mutex}->unlock();
   _req1('O~QUT', $_id.$LF);
   MCE::Util::_sleep(0.045); # yield

   return ();
}

sub pending {
   (@_ == 1 && !wantarray) ? _size('pending', @_) : _auto('pending', @_);
}

1;

__END__

###############################################################################
## ----------------------------------------------------------------------------
## Module usage.
##
###############################################################################

=head1 NAME

MCE::Shared::Queue - Hybrid-queue helper class

=head1 VERSION

This document describes MCE::Shared::Queue version 1.885

=head1 DESCRIPTION

A queue helper class for use as a standalone or managed by L<MCE::Shared>.

This module is mostly compatible with L<MCE::Queue> except for the C<gather>
option which is not supported in this context. It provides a queue interface
supporting normal and priority queues. Data from shared queues reside under
the shared-manager process, otherwise locally.

=head1 SYNOPSIS

 # non-shared or local construction for use by a single process

 use MCE::Shared::Queue;

 my $qu = MCE::Shared::Queue->new( await => 1, queue => [ "." ] );

 # construction for sharing with other threads and processes

 use MCE::Shared;
 use MCE::Shared::Queue;

 my $qu = MCE::Shared->queue(
    porder => $MCE::Shared::Queue::HIGHEST,
    type   => $MCE::Shared::Queue::FIFO,
 );

 # possible values for "porder" and "type"

 porder =>
    $MCE::Shared::Queue::HIGHEST # Highest priority items dequeue first
    $MCE::Shared::Queue::LOWEST  # Lowest priority items dequeue first

 type =>
    $MCE::Shared::Queue::FIFO    # First in, first out
    $MCE::Shared::Queue::LIFO    # Last in, first out
    $MCE::Shared::Queue::LILO    # Synonym for FIFO
    $MCE::Shared::Queue::FILO    # Synonym for LIFO

 # below, [ ... ] denotes optional parameters

 $qu->await( [ $pending_threshold ] );
 $qu->clear();
 $qu->end();

 $qu->enqueue( $item [, $item, ... ] );
 $qu->enqueuep( $priority, $item [, $item, ... ] );

 $item  = $qu->dequeue();
 @items = $qu->dequeue( $count );
 $item  = $qu->dequeue_nb();
 @items = $qu->dequeue_nb( $count );
 $item  = $qu->dequeue_timed( $timeout );
 @items = $qu->dequeue_timed( $timeout, $count );

 $qu->insert( $index, $item [, $item, ... ] );
 $qu->insertp( $priority, $index, $item [, $item, ... ] );

 $count = $qu->pending();
 $item  = $qu->peek( [ $index ] );
 $item  = $qu->peekp( $priority [, $index ] );
 @array = $qu->heap();

=head1 API DOCUMENTATION

=head2 MCE::Shared::Queue->new ( [ options ] )

=head2 MCE::Shared->queue ( [ options ] )

Constructs a new object. Supported options are queue, porder, type, and await.
Note: The barrier and fast options are silentently ignored (no-op) if specified;
starting with 1.867.

 # non-shared or local construction for use by a single process

 use MCE::Shared::Queue;

 $q1 = MCE::Shared::Queue->new();
 $q2 = MCE::Shared::Queue->new( queue  => [ 0, 1, 2 ] );

 $q3 = MCE::Shared::Queue->new( porder => $MCE::Shared::Queue::HIGHEST );
 $q4 = MCE::Shared::Queue->new( porder => $MCE::Shared::Queue::LOWEST  );

 $q5 = MCE::Shared::Queue->new( type   => $MCE::Shared::Queue::FIFO );
 $q6 = MCE::Shared::Queue->new( type   => $MCE::Shared::Queue::LIFO );

 $q7 = MCE::Shared::Queue->new( await  => 1, barrier => 0 );
 $q8 = MCE::Shared::Queue->new( fast   => 1 );

 # construction for sharing with other threads and processes

 use MCE::Shared;
 use MCE::Shared::Queue;

 $q1 = MCE::Shared->queue();
 $q2 = MCE::Shared->queue( queue  => [ 0, 1, 2 ] );

 $q3 = MCE::Shared->queue( porder => $MCE::Shared::Queue::HIGHEST );
 $q4 = MCE::Shared->queue( porder => $MCE::Shared::Queue::LOWEST  );

 $q5 = MCE::Shared->queue( type   => $MCE::Shared::Queue::FIFO );
 $q6 = MCE::Shared->queue( type   => $MCE::Shared::Queue::LIFO );

 $q7 = MCE::Shared->queue( await  => 1, barrier => 0 );
 $q8 = MCE::Shared->queue( fast   => 1 );

The C<await> option, when enabled, allows workers to block (semaphore-like)
until the number of items pending is equal or less than a threshold value.
The C<await> method is described below.

Obsolete: On Unix platforms, C<barrier> mode (enabled by default) prevents
many workers from dequeuing simultaneously to lessen overhead for the OS kernel.
Specify 0 to disable barrier mode and not allocate sockets. The barrier option
has no effect if constructing the queue inside a thread or enabling C<fast>.

Obsolete: The C<fast> option speeds up dequeues and is not enabled by default.
It is beneficial for queues not calling (->dequeue_nb) and not altering the
count value while running; e.g. ->dequeue($count).

=head2 await ( pending_threshold )

Waits until the queue drops down to threshold items. The C<await> method is
beneficial when wanting to throttle worker(s) appending to the queue. Perhaps,
consumers are running a bit behind and wanting prevent memory consumption from
increasing too high. Below, the number of items pending will never go above 20.

 use Time::HiRes qw( sleep );

 use MCE::Flow;
 use MCE::Shared;

 my $q = MCE::Shared->queue( await => 1, fast => 1 );
 my ( $producers, $consumers ) = ( 1, 8 );

 mce_flow {
    task_name   => [ 'producer', 'consumer' ],
    max_workers => [ $producers, $consumers ],
 },
 sub {
    ## producer
    for my $item ( 1 .. 100 ) {
       $q->enqueue($item);

       ## blocks until the # of items pending reaches <= 10
       if ($item % 10 == 0) {
          MCE->say( 'pending: '.$q->pending() );
          $q->await(10);
       }
    }

    ## notify consumers no more work
    $q->end();

 },
 sub {
    ## consumers
    while (defined (my $next = $q->dequeue())) {
       MCE->say( MCE->task_wid().': '.$next );
       sleep 0.100;
    }
 };

=head2 clear ( )

Clears the queue of any items.

 $q->clear;

=head2 end ( )

Stops the queue from receiving more items. Any worker blocking on C<dequeue>
will be unblocked automatically. Subsequent calls to C<dequeue> will behave
like C<dequeue_nb>. Current API available since MCE::Shared 1.814.

 $q->end();

MCE Models (e.g. MCE::Flow) may persist between runs. In that case, one might
want to enqueue C<undef>'s versus calling C<end>. The number of C<undef>'s
depends on how many items workers dequeue at a time.

 $q->enqueue((undef) x ($N_workers * 1));  # $q->dequeue()   1 item
 $q->enqueue((undef) x ($N_workers * 2));  # $q->dequeue(2)  2 items
 $q->enqueue((undef) x ($N_workers * N));  # $q->dequeue(N)  N items

=head2 enqueue ( item [, item, ... ] )

Appends a list of items onto the end of the normal queue.

 $q->enqueue( 'foo' );
 $q->enqueue( 'bar', 'baz' );

=head2 enqueuep ( priority, item [, item, ... ] )

Appends a list of items onto the end of the priority queue with priority.

 $q->enqueue( $priority, 'foo' );
 $q->enqueue( $priority, 'bar', 'baz' );

=head2 dequeue ( [ count ] )

Returns the requested number of items (default 1) from the queue. Priority
data will always dequeue first before any data from the normal queue.

 $q->dequeue;
 $q->dequeue( 2 );

The method will block if the queue contains zero items. If the queue contains
fewer than the requested number of items, the method will not block, but
return whatever items there are on the queue.

The $count, used for requesting the number of items, is beneficial when workers
are passing parameters through the queue. For this reason, always remember to
dequeue using the same multiple for the count. This is unlike Thread::Queue
which will block until the requested number of items are available.

 # MCE::Shared::Queue 1.816 and prior releases
 while ( my @items = $q->dequeue(2) ) {
    last unless ( defined $items[0] );
    ...
 }

 # MCE::Shared::Queue 1.817 and later
 while ( my @items = $q->dequeue(2) ) {
    ...
 }

=head2 dequeue_nb ( [ count ] )

Returns the requested number of items (default 1) from the queue. Like with
dequeue, priority data will always dequeue first. This method is non-blocking
and returns C<undef> in the absence of data.

 $q->dequeue_nb;
 $q->dequeue_nb( 2 );

=head2 dequeue_timed ( timeout [, $count ] )

Returns the requested number of items (default 1) from the queue. Like with
dequeue, priority data will always dequeue first. This method is blocking
until the timeout is reached and returns C<undef> in the absence of data.
Current API available since MCE::Shared 1.882.

 $q->dequeue_timed( 300 );    # timeout after 5 minutes
 $q->dequeue_timed( 300, 2 );

The timeout may be specified as fractional seconds. If timeout is missing,
undef, less than or equal to 0, or a non-shared object, then this call behaves
like dequeue_nb.

=head2 insert ( index, item [, item, ... ] )

Adds the list of items to the queue at the specified index position (0 is the
head of the list). The head of the queue is that item which would be removed
by a call to dequeue.

 $q = MCE::Shared->queue( type => $MCE::Shared::Queue::FIFO );
 $q->enqueue(1, 2, 3, 4);
 $q->insert(1, 'foo', 'bar');
 # Queue now contains: 1, foo, bar, 2, 3, 4

 $q = MCE::Shared->queue( type => $MCE::Shared::Queue::LIFO );
 $q->enqueue(1, 2, 3, 4);
 $q->insert(1, 'foo', 'bar');
 # Queue now contains: 1, 2, 3, 'foo', 'bar', 4

=head2 insertp ( priority, index, item [, item, ... ] )

Adds the list of items to the queue at the specified index position with
priority. The behavior is similarly to C<< $q->insert >> otherwise.

=head2 pending ( )

Returns the number of items in the queue. The count includes both normal
and priority data. Returns C<undef> if the queue has been ended, and there
are no more items in the queue.

 $q = MCE::Shared->queue();
 $q->enqueuep(5, 'foo', 'bar');
 $q->enqueue('sunny', 'day');

 print $q->pending(), "\n";
 # Output: 4

=head2 peek ( [ index ] )

Returns an item from the normal queue, at the specified index, without
dequeuing anything. It defaults to the head of the queue if index is not
specified. The head of the queue is that item which would be removed by a
call to dequeue. Negative index values are supported, similarly to arrays.

 $q = MCE::Shared->queue( type => $MCE::Shared::Queue::FIFO );
 $q->enqueue(1, 2, 3, 4, 5);

 print $q->peek(1), ' ', $q->peek(-2), "\n";
 # Output: 2 4

 $q = MCE::Shared->queue( type => $MCE::Shared::Queue::LIFO );
 $q->enqueue(1, 2, 3, 4, 5);

 print $q->peek(1), ' ', $q->peek(-2), "\n";
 # Output: 4 2

=head2 peekp ( priority [, index ] )

Returns an item from the queue with priority, at the specified index, without
dequeuing anything. It defaults to the head of the queue if index is not
specified. The behavior is similarly to C<< $q->peek >> otherwise.

=head2 peekh ( [ index ] )

Returns an item from the head of the heap or at the specified index.

 $q = MCE::Shared->queue( porder => $MCE::Shared::Queue::HIGHEST );
 $q->enqueuep(5, 'foo');
 $q->enqueuep(6, 'bar');
 $q->enqueuep(4, 'sun');

 print $q->peekh(0), "\n";
 # Output: 6

 $q = MCE::Shared->queue( porder => $MCE::Shared::Queue::LOWEST );
 $q->enqueuep(5, 'foo');
 $q->enqueuep(6, 'bar');
 $q->enqueuep(4, 'sun');

 print $q->peekh(0), "\n";
 # Output: 4

=head2 heap ( )

Returns an array containing the heap data. Heap data consists of priority
numbers, not the data.

 @h = $q->heap;   # $MCE::Shared::Queue::HIGHEST
 # Heap contains: 6, 5, 4

 @h = $q->heap;   # $MCE::Shared::Queue::LOWEST
 # Heap contains: 4, 5, 6

=head1 ACKNOWLEDGMENTS

=over 3

=item * L<List::BinarySearch>

The bsearch_num_pos method was helpful for accommodating the highest and lowest
order in MCE::Shared::Queue.

=item * L<POE::Queue::Array>

For extra optimization, two if statements were adopted for checking if the item
belongs at the end or head of the queue.

=item * L<List::Priority>

MCE::Shared::Queue supports both normal and priority queues.

=item * L<Thread::Queue>

Thread::Queue is used as a template for identifying and documenting the methods.
MCE::Shared::Queue is not fully compatible due to supporting normal and priority
queues simultaneously; e.g.

 $q->enqueue( $item [, $item, ... ] );         # normal queue
 $q->enqueuep( $p, $item [, $item, ... ] );    # priority queue

 $q->dequeue( [ $count ] );      # priority data dequeues first
 $q->dequeue_nb( [ $count ] );

 $q->pending();                  # counts both normal/priority queues

=back

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

