#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2022 -- leonerd@leonerd.org.uk

package Future::PP 0.51;

use v5.14;
use warnings;
no warnings 'recursion'; # Disable the "deep recursion" warning

our @ISA = qw( Future::_base );

use Carp qw(); # don't import croak
use List::Util 1.29 qw( pairs pairkeys );
use Scalar::Util qw( weaken blessed reftype );
use Time::HiRes qw( gettimeofday );

our @CARP_NOT = qw( Future Future::_base Future::Utils );

use constant DEBUG => !!$ENV{PERL_FUTURE_DEBUG};

use constant STRICT => !!$ENV{PERL_FUTURE_STRICT};

# Callback flags
use constant {
   CB_DONE   => 1<<0, # Execute callback on done
   CB_FAIL   => 1<<1, # Execute callback on fail
   CB_CANCEL => 1<<2, # Execute callback on cancellation

   CB_SELF   => 1<<3, # Pass $self as first argument
   CB_RESULT => 1<<4, # Pass result/failure as a list

   CB_SEQ_ONDONE => 1<<5, # Sequencing on success (->then)
   CB_SEQ_ONFAIL => 1<<6, # Sequencing on failure (->else)

   CB_SEQ_IMDONE => 1<<7, # $code is in fact immediate ->done result
   CB_SEQ_IMFAIL => 1<<8, # $code is in fact immediate ->fail result

   CB_SEQ_STRICT => 1<<9, # Complain if $code didn't return a Future
};

use constant CB_ALWAYS => CB_DONE|CB_FAIL|CB_CANCEL;

sub _shortmess
{
   my $at = Carp::shortmess( $_[0] );
   chomp $at; $at =~ s/\.$//;
   return $at;
}

sub _callable
{
   my ( $cb ) = @_;
   defined $cb and ( reftype($cb) eq 'CODE' || overload::Method($cb, '&{}') );
}

sub new
{
   my $proto = shift;
   return bless {
      ready     => 0,
      callbacks => [], # [] = [$type, ...]
      ( DEBUG ?
         ( do { my $at = Carp::shortmess( "constructed" );
                chomp $at; $at =~ s/\.$//;
                constructed_at => $at } )
         : () ),
      ( $Future::TIMES ?
         ( btime => [ gettimeofday ] )
         : () ),
   }, ( ref $proto || $proto );
}

sub __selfstr
{
   my $self = shift;
   return "$self" unless defined $self->{label};
   return "$self (\"$self->{label}\")";
}

my $GLOBAL_END;
END { $GLOBAL_END = 1; }

sub DESTROY_debug {
   my $self = shift;
   return if $GLOBAL_END;
   return if $self->{ready} and ( $self->{reported} or !$self->{failure} );

   my $lost_at = join " line ", (caller)[1,2];
   # We can't actually know the real line where the last reference was lost; 
   # a variable set to 'undef' or close of scope, because caller can't see it;
   # the current op has already been updated. The best we can do is indicate
   # 'near'.

   if( $self->{ready} and $self->{failure} ) {
      warn "${\$self->__selfstr} was $self->{constructed_at} and was lost near $lost_at with an unreported failure of: " .
         $self->{failure}[0] . "\n";
   }
   elsif( !$self->{ready} ) {
      warn "${\$self->__selfstr} was $self->{constructed_at} and was lost near $lost_at before it was ready.\n";
   }
}
*DESTROY = \&DESTROY_debug if DEBUG;

sub is_ready
{
   my $self = shift;
   return $self->{ready};
}

sub is_done
{
   my $self = shift;
   return $self->{ready} && !$self->{failure} && !$self->{cancelled};
}

sub is_failed
{
   my $self = shift;
   return $self->{ready} && !!$self->{failure}; # boolify
}

sub is_cancelled
{
   my $self = shift;
   return $self->{cancelled};
}

sub state
{
   my $self = shift;
   return !$self->{ready}     ? "pending" :
           DEBUG              ? $self->{ready_at} :
           $self->{failure}   ? "failed" :
           $self->{cancelled} ? "cancelled" :
                                "done";
}

sub _mark_ready
{
   my $self = shift;
   $self->{ready} = 1;
   $self->{ready_at} = _shortmess $_[0] if DEBUG;

   if( $Future::TIMES ) {
      $self->{rtime} = [ gettimeofday ];
   }

   delete $self->{on_cancel};
   $_->[0] and $_->[0]->_revoke_on_cancel( $_->[1] ) for @{ $self->{revoke_when_ready} };
   delete $self->{revoke_when_ready};

   my $callbacks = delete $self->{callbacks} or return;

   my $cancelled = $self->{cancelled};
   my $fail      = defined $self->{failure};
   my $done      = !$fail && !$cancelled;

   my @result  = $done ? @{ $self->{result} } :
                 $fail ? @{ $self->{failure} } :
                         ();

   foreach my $cb ( @$callbacks ) {
      my ( $flags, $code ) = @$cb;
      my $is_future = blessed( $code ) && $code->isa( "Future" );

      next if $done      and not( $flags & CB_DONE );
      next if $fail      and not( $flags & CB_FAIL );
      next if $cancelled and not( $flags & CB_CANCEL );

      $self->{reported} = 1 if $fail;

      if( $is_future ) {
         $done ? $code->done( @result ) :
         $fail ? $code->fail( @result ) :
                 $code->cancel;
      }
      elsif( $flags & (CB_SEQ_ONDONE|CB_SEQ_ONFAIL) ) {
         my ( undef, undef, $fseq ) = @$cb;
         if( !$fseq ) { # weaken()ed; it might be gone now
            # This warning should always be printed, even not in DEBUG mode.
            # It's always an indication of a bug
            Carp::carp +(DEBUG ? "${\$self->__selfstr} ($self->{constructed_at})"
                               : "${\$self->__selfstr} $self" ) .
               " lost a sequence Future";
            next;
         }

         my $f2;
         if( $done and $flags & CB_SEQ_ONDONE or
             $fail and $flags & CB_SEQ_ONFAIL ) {

            if( $flags & CB_SEQ_IMDONE ) {
               $fseq->done( @$code );
               next;
            }
            elsif( $flags & CB_SEQ_IMFAIL ) {
               $fseq->fail( @$code );
               next;
            }

            my @args = (
               ( $flags & CB_SELF   ? $self : () ),
               ( $flags & CB_RESULT ? @result : () ),
            );

            unless( eval { $f2 = $code->( @args ); 1 } ) {
               $fseq->fail( $@ );
               next;
            }

            unless( blessed $f2 and $f2->isa( "Future" ) ) {
               # Upgrade a non-Future result, or complain in strict mode
               if( $flags & CB_SEQ_STRICT ) {
                  $fseq->fail( "Expected " . Future::CvNAME_FILE_LINE($code) . " to return a Future" );
                  next;
               }
               $f2 = Future->done( $f2 );
            }

            $fseq->on_cancel( $f2 );
         }
         else {
            $f2 = $self;
         }

         if( $f2->is_ready ) {
            $f2->on_ready( $fseq ) if !$f2->{cancelled};
         }
         else {
            push @{ $f2->{callbacks} }, [ CB_DONE|CB_FAIL, $fseq ];
            weaken( $f2->{callbacks}[-1][1] );
         }
      }
      else {
         $code->(
            ( $flags & CB_SELF   ? $self : () ),
            ( $flags & CB_RESULT ? @result : () ),
         );
      }
   }
}

sub done
{
   my $self = shift;

   if( ref $self ) {
      $self->{cancelled} and return $self;
      $self->{ready} and Carp::croak "${\$self->__selfstr} is already ".$self->state." and cannot be ->done";
      $self->{subs} and Carp::croak "${\$self->__selfstr} is not a leaf Future, cannot be ->done";
      $self->{result} = [ @_ ];
      $self->_mark_ready( "done" );
   }
   else {
      $self = $self->new;
      $self->{ready} = 1;
      $self->{ready_at} = _shortmess "done" if DEBUG;
      $self->{result} = [ @_ ];
      if( $Future::TIMES ) {
         $self->{rtime} = [ gettimeofday ];
      }
   }

   return $self;
}

sub fail
{
   my $self = shift;
   my ( $exception, @more ) = @_;

   if( ref $exception eq "Future::Exception" ) {
      @more = ( $exception->category, $exception->details );
      $exception = $exception->message;
   }

   $exception or Carp::croak "$self ->fail requires an exception that is true";

   if( ref $self ) {
      $self->{cancelled} and return $self;
      $self->{ready} and Carp::croak "${\$self->__selfstr} is already ".$self->state." and cannot be ->fail'ed";
      $self->{subs} and Carp::croak "${\$self->__selfstr} is not a leaf Future, cannot be ->fail'ed";
      $self->{failure} = [ $exception, @more ];
      $self->_mark_ready( "failed" );
   }
   else {
      $self = $self->new;
      $self->{ready} = 1;
      $self->{ready_at} = _shortmess "failed" if DEBUG;
      $self->{failure} = [ $exception, @more ];
      if( $Future::TIMES ) {
         $self->{rtime} = [ gettimeofday ];
      }
   }

   return $self;
}

sub on_cancel
{
   my $self = shift;
   my ( $code ) = @_;

   my $is_future = blessed( $code ) && $code->isa( "Future" );
   $is_future or _callable( $code ) or
      Carp::croak "Expected \$code to be callable or a Future in ->on_cancel";

   $self->{ready} and return $self;

   push @{ $self->{on_cancel} }, $code;
   if( $is_future ) {
      push @{ $code->{revoke_when_ready} }, my $r = [ $self, \$self->{on_cancel}[-1] ];
      weaken( $r->[0] );
      weaken( $r->[1] );
   }

   return $self;
}

# An optimised version for Awaitable role
sub AWAIT_ON_CANCEL
{
   my $self = shift;
   my ( $code ) = @_;

   push @{ $self->{on_cancel} }, $code;
}

sub AWAIT_CHAIN_CANCEL
{
   my $self = shift;
   my ( $f2 ) = @_;

   push @{ $self->{on_cancel} }, $f2;
   push @{ $f2->{revoke_when_ready} }, my $r = [ $self, \$self->{on_cancel}[-1] ];
   weaken( $r->[0] );
   weaken( $r->[1] );
}

sub _revoke_on_cancel
{
   my $self = shift;
   my ( $ref ) = @_;

   undef $$ref;
   $self->{empty_on_cancel_slots}++;

   my $on_cancel = $self->{on_cancel} or return;

   # If the list is nontrivally large and over half-empty / under half-full, compact it
   if( @$on_cancel >= 8 and $self->{empty_on_cancel_slots} >= 0.5 * @$on_cancel ) {
      # We can't grep { defined } because that will break all the existing SCALAR refs
      my $idx = 0;
      while( $idx < @$on_cancel ) {
         defined $on_cancel->[$idx] and $idx++, next;
         splice @$on_cancel, $idx, 1, ();
      }
      $self->{empty_on_cancel_slots} = 0;
   }
}

sub on_ready
{
   my $self = shift;
   my ( $code ) = @_;

   my $is_future = blessed( $code ) && $code->isa( "Future" );
   $is_future or _callable( $code ) or
      Carp::croak "Expected \$code to be callable or a Future in ->on_ready";

   if( $self->{ready} ) {
      my $fail = defined $self->{failure};
      my $done = !$fail && !$self->{cancelled};

      $self->{reported} = 1 if $fail;

      $is_future ? ( $done ? $code->done( @{ $self->{result} } ) :
                     $fail ? $code->fail( @{ $self->{failure} } ) :
                             $code->cancel )
                 : $code->( $self );
   }
   else {
      push @{ $self->{callbacks} }, [ CB_ALWAYS|CB_SELF, $self->wrap_cb( on_ready => $code ) ];
   }

   return $self;
}

# An optimised version for Awaitable role
sub AWAIT_ON_READY
{
   my $self = shift;
   my ( $code ) = @_;
   push @{ $self->{callbacks} }, [ CB_ALWAYS|CB_SELF, $self->wrap_cb( on_ready => $code ) ];
}

sub result
{
   my $self = shift;
   $self->{ready} or
      Carp::croak( "${\$self->__selfstr} is not yet ready" );
   if( my $failure = $self->{failure} ) {
      $self->{reported} = 1;
      my $exception = $failure->[0];
      $exception = Future::Exception->new( @$failure ) if @$failure > 1;
      !ref $exception && $exception =~ m/\n$/ ? CORE::die $exception : Carp::croak $exception;
   }
   $self->{cancelled} and Carp::croak "${\$self->__selfstr} was cancelled";
   return $self->{result}->[0] unless wantarray;
   return @{ $self->{result} };
}

sub get
{
   my $self = shift;
   $self->await unless $self->{ready};
   return $self->result;
}

sub await
{
   my $self = shift;
   return $self if $self->{ready};
   Carp::croak "$self is not yet complete and does not provide ->await";
}

sub on_done
{
   my $self = shift;
   my ( $code ) = @_;

   my $is_future = blessed( $code ) && $code->isa( "Future" );
   $is_future or _callable( $code ) or
      Carp::croak "Expected \$code to be callable or a Future in ->on_done";

   if( $self->{ready} ) {
      return $self if $self->{failure} or $self->{cancelled};

      $is_future ? $code->done( @{ $self->{result} } ) 
                 : $code->( @{ $self->{result} } );
   }
   else {
      push @{ $self->{callbacks} }, [ CB_DONE|CB_RESULT, $self->wrap_cb( on_done => $code ) ];
   }

   return $self;
}

sub failure
{
   my $self = shift;
   $self->await unless $self->{ready};
   return unless $self->{failure};
   $self->{reported} = 1;
   return $self->{failure}->[0] if !wantarray;
   return @{ $self->{failure} };
}

sub on_fail
{
   my $self = shift;
   my ( $code ) = @_;

   my $is_future = blessed( $code ) && $code->isa( "Future" );
   $is_future or _callable( $code ) or
      Carp::croak "Expected \$code to be callable or a Future in ->on_fail";

   if( $self->{ready} ) {
      return $self if not $self->{failure};
      $self->{reported} = 1;

      $is_future ? $code->fail( @{ $self->{failure} } )
                 : $code->( @{ $self->{failure} } );
   }
   else {
      push @{ $self->{callbacks} }, [ CB_FAIL|CB_RESULT, $self->wrap_cb( on_fail => $code ) ];
   }

   return $self;
}

sub cancel
{
   my $self = shift;

   return $self if $self->{ready};

   $self->{cancelled}++;
   my $on_cancel = delete $self->{on_cancel};
   foreach my $code ( $on_cancel ? reverse @$on_cancel : () ) {
      defined $code or next;
      my $is_future = blessed( $code ) && $code->isa( "Future" );
      $is_future ? $code->cancel
                 : $code->( $self );
   }
   $self->_mark_ready( "cancel" );

   return $self;
}

my $make_donecatchfail_sub = sub {
   my ( $with_f, $done_code, $fail_code, @catch_list ) = @_;

   my $func = (caller 1)[3];
   $func =~ s/^.*:://;

   !$done_code or _callable( $done_code ) or
      Carp::croak "Expected \$done_code to be callable in ->$func";
   !$fail_code or _callable( $fail_code ) or
      Carp::croak "Expected \$fail_code to be callable in ->$func";

   my %catch_handlers = @catch_list;
   _callable( $catch_handlers{$_} ) or
      Carp::croak "Expected catch handler for '$_' to be callable in ->$func"
      for keys %catch_handlers;

   sub {
      my $self = shift;
      my @maybe_self = $with_f ? ( $self ) : ();

      if( !$self->{failure} ) {
         return $self unless $done_code;
         return $done_code->( @maybe_self, @{ $self->{result} } );
      }
      else {
         my $name = $self->{failure}[1];
         if( defined $name and $catch_handlers{$name} ) {
            return $catch_handlers{$name}->( @maybe_self, @{ $self->{failure} } );
         }
         return $self unless $fail_code;
         return $fail_code->( @maybe_self, @{ $self->{failure} } );
      }
   };
};

sub _sequence
{
   my $f1 = shift;
   my ( $code, $flags ) = @_;

   $flags |= CB_SEQ_STRICT if STRICT;

   # For later, we might want to know where we were called from
   my $level = 1;
   $level++ while (caller $level)[0] eq "Future::_base";
   my $func = (caller $level)[3];
   $func =~ s/^.*:://;

   $flags & (CB_SEQ_IMDONE|CB_SEQ_IMFAIL) or _callable( $code ) or
      Carp::croak "Expected \$code to be callable in ->$func";

   if( !defined wantarray ) {
      Carp::carp "Calling ->$func in void context";
   }

   if( $f1->is_ready ) {
      # Take a shortcut
      return $f1 if $f1->is_done   and not( $flags & CB_SEQ_ONDONE ) or
                    $f1->{failure} and not( $flags & CB_SEQ_ONFAIL );

      if( $flags & CB_SEQ_IMDONE ) {
         return Future->done( @$code );
      }
      elsif( $flags & CB_SEQ_IMFAIL ) {
         return Future->fail( @$code );
      }

      my @args = (
         ( $flags & CB_SELF ? $f1 : () ),
         ( $flags & CB_RESULT ? $f1->is_done   ? @{ $f1->{result} } :
                                $f1->{failure} ? @{ $f1->{failure} } :
                                               () : () ),
      );

      my $fseq;
      unless( eval { $fseq = $code->( @args ); 1 } ) {
         return Future->fail( $@ );
      }

      unless( blessed $fseq and $fseq->isa( "Future" ) ) {
         # Upgrade a non-Future result, or complain in strict mode
         $flags & CB_SEQ_STRICT and
            return Future->fail( "Expected " . Future::CvNAME_FILE_LINE($code) . " to return a Future" );

         $fseq = $f1->new->done( $fseq );
      }

      return $fseq;
   }

   my $fseq = $f1->new;
   $fseq->on_cancel( $f1 );

   # TODO: if anyone cares about the op name, we might have to synthesize it
   # from $flags
   $code = $f1->wrap_cb( sequence => $code ) unless $flags & (CB_SEQ_IMDONE|CB_SEQ_IMFAIL);

   push @{ $f1->{callbacks} }, [ CB_DONE|CB_FAIL|$flags, $code, $fseq ];
   weaken( $f1->{callbacks}[-1][2] );

   return $fseq;
}

sub then
{
   my $self = shift;
   my $done_code = shift;
   my $fail_code = ( @_ % 2 ) ? pop : undef;
   my @catch_list = @_;

   if( $done_code and !@catch_list and !$fail_code ) {
      return $self->_sequence( $done_code, CB_SEQ_ONDONE|CB_RESULT );
   }

   # Complex
   return $self->_sequence( $make_donecatchfail_sub->(
      0, $done_code, $fail_code, @catch_list,
   ), CB_SEQ_ONDONE|CB_SEQ_ONFAIL|CB_SELF );
}

sub then_done
{
   my $self = shift;
   my ( @result ) = @_;
   return $self->_sequence( \@result, CB_SEQ_ONDONE|CB_SEQ_IMDONE );
}

sub then_fail
{
   my $self = shift;
   my ( @failure ) = @_;
   return $self->_sequence( \@failure, CB_SEQ_ONDONE|CB_SEQ_IMFAIL );
}

sub else
{
   my $self = shift;
   my ( $fail_code ) = @_;

   return $self->_sequence( $fail_code, CB_SEQ_ONFAIL|CB_RESULT );
}

sub else_done
{
   my $self = shift;
   my ( @result ) = @_;
   return $self->_sequence( \@result, CB_SEQ_ONFAIL|CB_SEQ_IMDONE );
}

sub else_fail
{
   my $self = shift;
   my ( @failure ) = @_;
   return $self->_sequence( \@failure, CB_SEQ_ONFAIL|CB_SEQ_IMFAIL );
}

sub catch
{
   my $self = shift;
   my $fail_code = ( @_ % 2 ) ? pop : undef;
   my @catch_list = @_;

   return $self->_sequence( $make_donecatchfail_sub->(
      0, undef, $fail_code, @catch_list,
   ), CB_SEQ_ONDONE|CB_SEQ_ONFAIL|CB_SELF );
}

sub then_with_f
{
   my $self = shift;
   my $done_code = shift;
   my $fail_code = ( @_ % 2 ) ? pop : undef;
   my @catch_list = @_;

   if( $done_code and !@catch_list and !$fail_code ) {
      return $self->_sequence( $done_code, CB_SEQ_ONDONE|CB_SELF|CB_RESULT );
   }

   return $self->_sequence( $make_donecatchfail_sub->(
      1, $done_code, $fail_code, @catch_list,
   ), CB_SEQ_ONDONE|CB_SEQ_ONFAIL|CB_SELF );
}

sub else_with_f
{
   my $self = shift;
   my ( $fail_code ) = @_;

   return $self->_sequence( $fail_code, CB_SEQ_ONFAIL|CB_SELF|CB_RESULT );
}

sub catch_with_f
{
   my $self = shift;
   my $fail_code = ( @_ % 2 ) ? pop : undef;
   my @catch_list = @_;

   return $self->_sequence( $make_donecatchfail_sub->(
      1, undef, $fail_code, @catch_list,
   ), CB_SEQ_ONDONE|CB_SEQ_ONFAIL|CB_SELF );
}

sub followed_by
{
   my $self = shift;
   my ( $code ) = @_;

   return $self->_sequence( $code, CB_SEQ_ONDONE|CB_SEQ_ONFAIL|CB_SELF );
}

sub without_cancel
{
   my $self = shift;
   my $new = $self->new;

   $self->on_ready( sub {
      my $self = shift;
      if( $self->{cancelled} ) {
         $new->cancel;
      }
      elsif( $self->{failure} ) {
         $new->fail( @{ $self->{failure} } );
      }
      else {
         $new->done( @{ $self->{result} } );
      }
   });

   $new->{orig} = $self; # just to strongref it - RT122920
   $new->on_ready( sub { undef $_[0]->{orig} } );

   return $new;
}

# $self->{subs} is an even-sized list of *pairs*, ( $subf, $flags, $subf, $flags, ... )
#   pairkeys @{ $self->{subs} }  yields just the futures

use constant {
   SUBFLAG_NO_CANCEL => (1<<0),
};

sub _new_convergent
{
   shift; # ignore this class
   my ( $subs ) = @_;

   my @flaggedsubs;

   for ( my $i = 0; $i < @$subs; $i++ ) {
      my $flags = 0;
      $flags |= SUBFLAG_NO_CANCEL, $i++ if !blessed $subs->[$i] and $subs->[$i] eq "also";

      my $sub = $subs->[$i];
      blessed $sub and $sub->isa( "Future" ) or Carp::croak "Expected a Future, got $sub";

      push @flaggedsubs, ( $sub, $flags );
   }

   # Find the best prototype. Ideally anything derived if we can find one.
   my $self;
   ref($_) eq "Future" or $self = $_->new, last for pairkeys @flaggedsubs;

   # No derived ones; just have to be a basic class then
   $self ||= Future->new;

   $self->{subs} = \@flaggedsubs;

   $self->on_cancel( \&_cancel_subs );

   @$subs = pairkeys @flaggedsubs;

   return $self;
}

# This might be called by a DESTROY during global destruction so it should
# be as defensive as possible (see RT88967)
sub _cancel_subs
{
   my $self = shift;
   my $subs = $self->{subs} or return;

   foreach ( pairs @$subs ) {
      my ( $sub, $flags ) = @$_;
      $sub->cancel if !( $flags & SUBFLAG_NO_CANCEL ) and $sub and !$sub->{ready};
   }
}

sub wait_all
{
   my $class = shift;
   my @subs = @_;

   unless( @subs ) {
      my $self = $class->done;
      $self->{subs} = [];
      return $self;
   }

   my $self = Future->_new_convergent( \@subs );

   my $pending = 0;
   $_->{ready} or $pending++ for @subs;

   # Look for immediate ready
   if( !$pending ) {
      $self->{result} = [ @subs ];
      $self->_mark_ready( "wait_all" );
      return $self;
   }

   weaken( my $weakself = $self );
   my $sub_on_ready = sub {
      return unless my $self = $weakself;

      $pending--;
      $pending and return;

      $self->{result} = [ pairkeys @{ $self->{subs} } ];
      $self->_mark_ready( "wait_all" );
   };

   foreach my $sub ( @subs ) {
      $sub->{ready} or $sub->on_ready( $sub_on_ready );
   }

   return $self;
}

sub wait_any
{
   my $class = shift;
   my @subs = @_;

   unless( @subs ) {
      my $self = $class->fail( "Cannot ->wait_any with no subfutures" );
      $self->{subs} = [];
      return $self;
   }

   my $self = Future->_new_convergent( \@subs );

   # Look for immediate ready
   my $immediate_ready;
   foreach my $sub ( @subs ) {
      $sub->{ready} and !$sub->{cancelled} and $immediate_ready = $sub, last;
   }

   if( $immediate_ready ) {
      $self->_cancel_subs;

      if( $immediate_ready->{failure} ) {
         $self->{failure} = [ @{ $immediate_ready->{failure} } ];
      }
      else {
         $self->{result} = [ @{ $immediate_ready->{result} } ];
      }
      $self->_mark_ready( "wait_any" );
      return $self;
   }

   my $pending = 0;

   weaken( my $weakself = $self );
   my $sub_on_ready = sub {
      return unless my $self = $weakself;
      return if $self->{result} or $self->{failure}; # don't recurse on child ->cancel

      return if --$pending and $_[0]->{cancelled};

      if( $_[0]->{cancelled} ) {
         $self->{failure} = [ "All component futures were cancelled" ];
      }
      elsif( $_[0]->{failure} ) {
         $self->{failure} = [ @{ $_[0]->{failure} } ];
      }
      else {
         $self->{result}  = [ @{ $_[0]->{result} } ];
      }

      $self->_cancel_subs;

      $self->_mark_ready( "wait_any" );
   };

   foreach my $sub ( @subs ) {
      # No need to test $sub->{ready} since we know none of them are
      next if $sub->{cancelled};
      $sub->on_ready( $sub_on_ready );
      $pending++;
   }

   return $self;
}

sub needs_all
{
   my $class = shift;
   my @subs = @_;

   unless( @subs ) {
      my $self = $class->done;
      $self->{subs} = [];
      return $self;
   }

   my $self = Future->_new_convergent( \@subs );

   # Look for immediate fail
   my $immediate_failure;
   foreach my $sub ( @subs ) {
      $sub->{cancelled} and $immediate_failure = [ "A component future was cancelled" ], last;
      $sub->{ready} and $sub->{failure} and $immediate_failure = $sub->{failure}, last;
   }

   if( $immediate_failure ) {
      $self->_cancel_subs;

      $self->{failure} = [ @$immediate_failure ];
      $self->_mark_ready( "needs_all" );
      return $self;
   }

   my $pending = 0;
   $_->{ready} or $pending++ for @subs;

   # Look for immediate done
   if( !$pending ) {
      $self->{result} = [ map { @{ $_->{result} } } @subs ];
      $self->_mark_ready( "needs_all" );
      return $self;
   }

   weaken( my $weakself = $self );
   my $sub_on_ready = sub {
      return unless my $self = $weakself;
      return if $self->{result} or $self->{failure}; # don't recurse on child ->cancel

      if( $_[0]->{cancelled} ) {
         $self->{failure} = [ "A component future was cancelled" ];
         $self->_cancel_subs;
         $self->_mark_ready( "needs_all" );
      }
      elsif( $_[0]->{failure} ) {
         $self->{failure} = [ @{ $_[0]->{failure} } ];
         $self->_cancel_subs;
         $self->_mark_ready( "needs_all" );
      }
      else {
         $pending--;
         $pending and return;

         $self->{result} = [ map { @{ $_->{result} } } pairkeys @{ $self->{subs} } ];
         $self->_mark_ready( "needs_all" );
      }
   };

   foreach my $sub ( @subs ) {
      $sub->{ready} or $sub->on_ready( $sub_on_ready );
   }

   return $self;
}

sub needs_any
{
   my $class = shift;
   my @subs = @_;

   unless( @subs ) {
      my $self = $class->fail( "Cannot ->needs_any with no subfutures" );
      $self->{subs} = [];
      return $self;
   }

   my $self = Future->_new_convergent( \@subs );

   # Look for immediate done
   my $immediate_done;
   my $pending = 0;
   foreach my $sub ( @subs ) {
      $sub->{ready} and !$sub->{failure} and !$sub->{cancelled} and $immediate_done = $sub, last;
      $sub->{ready} or $pending++;
   }

   if( $immediate_done ) {
      foreach my $sub ( @subs ) {
         $sub->{ready} ? $sub->{reported} = 1 : $sub->cancel;
      }

      $self->{result} = [ @{ $immediate_done->{result} } ];
      $self->_mark_ready( "needs_any" );
      return $self;
   }

   # Look for immediate fail
   my $immediate_fail = 1;
   foreach my $sub ( @subs ) {
      $sub->{ready} or $immediate_fail = 0, last;
   }

   if( $immediate_fail ) {
      $_->{reported} = 1 for @subs;
      # For consistency we'll pick the last one for the failure
      $self->{failure} = [ $subs[-1]->{failure} ];
      $self->_mark_ready( "needs_any" );
      return $self;
   }

   weaken( my $weakself = $self );
   my $sub_on_ready = sub {
      return unless my $self = $weakself;
      return if $self->{result} or $self->{failure}; # don't recurse on child ->cancel

      return if --$pending and $_[0]->{cancelled};

      if( $_[0]->{cancelled} ) {
         $self->{failure} = [ "All component futures were cancelled" ];
         $self->_mark_ready( "needs_any" );
      }
      elsif( $_[0]->{failure} ) {
         $pending and return;

         $self->{failure} = [ @{ $_[0]->{failure} } ];
         $self->_mark_ready( "needs_any" );
      }
      else {
         $self->{result} = [ @{ $_[0]->{result} } ];
         $self->_cancel_subs;
         $self->_mark_ready( "needs_any" );
      }
   };

   foreach my $sub ( @subs ) {
      $sub->{ready} or $sub->on_ready( $sub_on_ready );
   }

   return $self;
}

sub pending_futures
{
   my $self = shift;
   $self->{subs} or Carp::croak "Cannot call ->pending_futures on a non-convergent Future";
   return grep { not $_->{ready} } pairkeys @{ $self->{subs} };
}

sub ready_futures
{
   my $self = shift;
   $self->{subs} or Carp::croak "Cannot call ->ready_futures on a non-convergent Future";
   return grep { $_->{ready} } pairkeys @{ $self->{subs} };
}

sub done_futures
{
   my $self = shift;
   $self->{subs} or Carp::croak "Cannot call ->done_futures on a non-convergent Future";
   return grep { $_->{ready} and not $_->{failure} and not $_->{cancelled} } pairkeys @{ $self->{subs} };
}

sub failed_futures
{
   my $self = shift;
   $self->{subs} or Carp::croak "Cannot call ->failed_futures on a non-convergent Future";
   return grep { $_->{ready} and $_->{failure} } pairkeys @{ $self->{subs} };
}

sub cancelled_futures
{
   my $self = shift;
   $self->{subs} or Carp::croak "Cannot call ->cancelled_futures on a non-convergent Future";
   return grep { $_->{ready} and $_->{cancelled} } pairkeys @{ $self->{subs} };
}

sub btime
{
   my $self = shift;
   return $self->{btime};
}

sub rtime
{
   my $self = shift;
   return $self->{rtime};
}

sub set_label
{
   my $self = shift;
   ( $self->{label} ) = @_;
   return $self;
}

sub label
{
   my $self = shift;
   return $self->{label};
}

sub set_udata
{
   my $self = shift;
   my ( $name, $value ) = @_;
   $self->{"u_$name"} = $value;
   return $self;
}

sub udata
{
   my $self = shift;
   my ( $name ) = @_;
   return $self->{"u_$name"};
}

0x55AA;
