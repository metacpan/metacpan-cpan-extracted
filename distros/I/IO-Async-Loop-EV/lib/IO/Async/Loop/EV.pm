#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2026 -- leonerd@leonerd.org.uk

package IO::Async::Loop::EV 0.04;

use v5.20;
use warnings;

use feature qw( signatures );
no warnings qw( experimental::signatures );

use constant API_VERSION => '0.76';

use base qw( IO::Async::Loop );
IO::Async::Loop->VERSION( '0.49' );

BEGIN {
   if( $^V ge v5.36 ) {
      builtin->import(qw( refaddr weaken ));
      warnings->unimport(qw( experimental::builtin )) if $^V lt v5.40;
   }
   else {
      require Scalar::Util;
      Scalar::Util->import(qw( refaddr weaken ));
   }
}

use IO::Async::Metrics '$METRICS';

use constant _CAN_SUBSECOND_ACCURATELY => 0;

use Carp;

use EV;

=head1 NAME

C<IO::Async::Loop::EV> - use C<IO::Async> with C<EV>

=head1 SYNOPSIS

=for highlighter language=perl

   use IO::Async::Loop::EV;

   my $loop = IO::Async::Loop::EV->new();

   $loop->add( ... );

   $loop->add( IO::Async::Signal->new(
         name => 'HUP',
         on_receipt => sub { ... },
   ) );

   $loop->run;

=head1 DESCRIPTION

This subclass of L<IO::Async::Loop> uses L<EV> to perform its work.

=cut

sub new ( $class, @args )
{
   my $self = $class->SUPER::__new( @args );

   $self->{$_} = {} for qw( watch_r watch_w watch_time watch_signal watch_idle watch_process );

   # Check it's actually active
   if( defined $METRICS and $METRICS->adapter and $METRICS ) {
      weaken( my $weakself = $self );
      $self->{watch_prepare} = EV::prepare sub (@) { $weakself->pre_wait };
      $self->{watch_check}   = EV::check   sub (@) { $weakself->post_wait };
   }

   return $self;
}

sub loop_once ( $self, $timeout = undef )
{
   my $timeout_w;
   if( defined $timeout ) {
      $timeout_w = EV::timer $timeout, 0, sub (@) {}; # simply to wake up RUN_ONCE
   }

   EV::run( EV::RUN_ONCE );
}

sub watch_io ( $self, %params )
{
   my $handle = $params{handle} or die "Need a handle";

   if( my $on_read_ready = $params{on_read_ready} ) {
      $self->{watch_r}{refaddr $handle} = EV::io( $handle, EV::READ, $on_read_ready );
   }

   if( my $on_write_ready = $params{on_write_ready} ) {
      $self->{watch_w}{refaddr $handle} = EV::io( $handle, EV::WRITE, $on_write_ready );
   }
}

sub unwatch_io ( $self, %params )
{
   my $handle = $params{handle} or die "Need a handle";

   if( $params{on_read_ready} ) {
      delete $self->{watch_r}{refaddr $handle};
   }

   if( $params{on_write_ready} ) {
      delete $self->{watch_w}{refaddr $handle};
   }
}

sub watch_time ( $self, %params )
{
   my $code = $params{code} or croak "Expected 'code' as CODE ref";

   my $w;
   if( defined $params{after} ) {
      $w = EV::timer $params{after}, 0, $code;
   }
   else {
      $w = EV::periodic $params{at}, 0, 0, $code;
   }

   return $self->{watch_time}{$w} = $w;
}

sub unwatch_time ( $self, $id )
{
   delete $self->{watch_time}{$id};
}

sub watch_signal ( $self, $signal, $code )
{
   defined $self->signame2num( $signal ) or croak "No such signal '$signal'";

   $self->{watch_signal}{$signal} = EV::signal $signal, $code;
}

sub unwatch_signal ( $self, $signal )
{
   delete $self->{watch_signal}{$signal};
}

sub watch_idle ( $self, %params )
{
   my $when = delete $params{when} or croak "Expected 'when'";

   my $code = delete $params{code} or croak "Expected 'code' as a CODE ref";

   $when eq "later" or croak "Expected 'when' to be 'later'";

   my $key;
   my $w = EV::idle sub {
      delete $self->{watch_idle}{$key};
      goto &$code;
   };

   $key = "$w";
   $self->{watch_idle}{$key} = $w;
   return $key;
}

sub unwatch_idle ( $self, $id )
{
   delete $self->{watch_idle}{$id};
}

sub watch_process ( $self, $pid, $code )
{
   $self->{watch_process}{$pid} = EV::child $pid, 0, sub ( $w, @ ) {
      $code->( $w->rpid, $w->rstatus );
   };
}

sub unwatch_process ( $self, $pid )
{
   delete $self->{watch_process}{$pid};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
