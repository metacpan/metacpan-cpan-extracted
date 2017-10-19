#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2017 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool;

use strict;
use warnings;

our $VERSION = '0.30';

use Getopt::Long qw( GetOptionsFromArray );
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

sub get_sv_from_args
{
   my $self = shift;
   my ( $args ) = @_;

   my $sv = Devel::MAT::UI->can( "current_sv" ) && Devel::MAT::UI->current_sv;

   if( @$args ) {
      my $addr = shift @$args;

      # Acccept any root name symbolically
      if( any { $addr eq $_ } Devel::MAT::Dumpfile->ROOTS ) {
         $sv = $self->df->$addr;
      }
      else {
         $addr = do {
            no warnings 'portable';
            hex $addr;
         } if $addr =~ m/^0x/;

         do { no warnings 'numeric'; $addr eq $addr+0 } or
            die "Expected numerical SV address\n";

         $sv = $self->df->sv_at( $addr ) or
            die sprintf "No such SV at address %x\n", $addr;
      }
   }

   $sv or die "Need an SV address\n";

   return $sv;
}

# Some empty defaults
use constant CMD_OPTS => ();
use constant CMD_ARGS_SV => 0;
use constant CMD_ARGS => ();
use constant CMD_SUBS => ();

sub find_subcommand
{
   my $self = shift;
   my ( $subname ) = @_;

   # TODO: sanity check

   return ( ref($self) . "::" . $subname )->new( $self->pmat,
      progress => $self->{progress},
   );
}

sub run_cmd
{
   my $self = shift;
   my ( @args ) = @_;

   # TODO: consider what happens if parent commands have CMD_OPTS
   if( my @subs = $self->CMD_SUBS ) {
      my $subcmd = @args ? shift @args : $subs[0];
      return $self->find_subcommand( $subcmd )->run_cmd( @args );
   }

   my %optspec = $self->CMD_OPTS;

   my %opts;
   my %getopts;

   foreach my $name ( keys %optspec ) {
      my $spec = $optspec{$name};

      $opts{$name} = $spec->{default};

      my $getopt = $name;
      $getopt .= join "|", "", $spec->{alias} if defined $spec->{alias};

      $getopt =~ s/_/-/g;

      $getopt .= "=$spec->{type}" if $spec->{type};

      $getopts{$getopt} = \$opts{$name};
   }

   GetOptionsFromArray( \@args, %getopts ) or return;

   if( $self->CMD_ARGS_SV ) {
      my $sv = $self->get_sv_from_args( \@args );
      unshift @args, $sv;
   }

   # TODO: parsing/checking of ARGS?

   $self->run( %optspec ? \%opts : (), @args );
}

0x55AA;
