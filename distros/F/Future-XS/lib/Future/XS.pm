#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

package Future::XS 0.03;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

use Time::HiRes qw( tv_interval );

=head1 NAME

C<Future::XS> - experimental XS implementation of C<Future>

=head1 SYNOPSIS

   my $future = Future::XS->new;

   perform_some_operation(
      on_complete => sub {
         $future->done( @_ );
      }
   );

   $future->on_ready( sub {
      say "The operation is complete";
   } );

=head1 DESCRIPTION

This module provides an XS-based implementation of the L<Future> class. It is
currently experimental and shipped in its own distribution for testing
purposes, though once it seems stable the plan is to move it into the main
C<Future> distribution and load it automatically in favour of the pureperl
implementation on supported systems.

=cut

sub import
{
   my $pkg = shift;
   my $caller = caller;

   my %syms = map { $_ => 1 } @_;

   if( delete $syms{"-default"} ) {
      require Future;

      no warnings 'redefine';
      foreach my $name (qw( new done fail )) {
         no strict 'refs';
         *{"Future::${name}"} = \&{__PACKAGE__."::${name}"};
      }
   }

   croak "Unrecognised $pkg\->import symbols - " . join( ", ", sort keys %syms )
      if %syms;
}

# These methods aren't on the "fast path" so for now we'll just implement them in Perl

sub transform
{
   my $self = shift;
   my %args = @_;

   my $xfrm_done = $args{done};
   my $xfrm_fail = $args{fail};

   return $self->then_with_f(
      sub {
         my $self = shift;
         return $self unless $xfrm_done;
         return $self->done( $xfrm_done->( $self->result ) );
      },
      sub {
         my $self = shift;
         return $self unless $xfrm_fail;
         return $self->fail( $xfrm_fail->( $self->failure ) );
      },
   );
}

sub elapsed
{
   my $self = shift;
   return undef unless
      defined( my $btime = $self->btime ) and defined( my $rtime = $self->rtime );
   return tv_interval( $btime, $rtime );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
