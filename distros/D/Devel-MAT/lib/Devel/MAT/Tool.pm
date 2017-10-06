#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool;

use strict;
use warnings;

our $VERSION = '0.27';

use List::Util qw( any );

sub new
{
   my $class = shift;
   my ( $pmat, %args ) = @_;

   return bless {
      pmat     => $pmat,
      df       => $pmat->dumpfile,
      progress => $args{progress},
   }, $class;
}

sub pmat
{
   my $self = shift;
   return $self->{pmat};
}

sub df
{
   my $self = shift;
   return $self->{df};
}

sub report_progress
{
   my $self = shift;
   $self->{progress}->( @_ ) if $self->{progress};
}

sub get_sv
{
   my $self = shift;
   my ( $arg ) = @_;

   my $sv = Devel::MAT::UI->can( "current_sv" ) && Devel::MAT::UI->current_sv;

   if( defined $arg ) {
      my $addr = $_[0];

      # Acccept any root name symbolically
      if( any { $addr eq $_ } Devel::MAT::Dumpfile->ROOTS ) {
         $sv = $self->df->$addr;
      }
      else {
         $addr = hex $addr if $addr =~ m/^0x/;
         do { no warnings 'numeric'; $addr eq $addr+0 } or
            die "Expected numerical SV address\n";

         $sv = $self->df->sv_at( $addr ) or
            die sprintf "No such SV at address %x\n", $addr;
      }
   }

   $sv or die "Need an SV address\n";

   return $sv;
}

sub _dispatch_sub
{
   my $self = shift;
   my ( $cmd, @args ) = @_;

   my $meth = (caller 1)[3];

   if( my $code = $self->can( "${meth}_${cmd}" ) ) {
      return $self->$code( @args );
   }
   else {
      die "$self has no $cmd sub-command\n";
   }
}

0x55AA;
