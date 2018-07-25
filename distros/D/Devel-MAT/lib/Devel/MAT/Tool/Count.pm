#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2018 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Count;

use strict;
use warnings;
use 5.014; # s///r
use base qw( Devel::MAT::Tool );

our $VERSION = '0.37';

use constant CMD => "count";
use constant CMD_DESC => "Count the various kinds of SV";

use List::Util qw( sum );
use List::UtilsBy qw( rev_nsort_by );
use Struct::Dumb;

=head1 NAME

C<Devel::MAT::Tool::Count> - count the various kinds of SV

=head1 DESCRIPTION

This C<Devel::MAT> tool counts the different kinds of SV in the heap.

=cut

=head1 COMMANDS

=head2 count

   pmat> count
     Kind       Count (blessed)        Bytes (blessed)
     ARRAY        170         0     15.1 KiB          
     CODE         166         0     20.8 KiB          

Prints a summary of the count of each type of object.

Takes the following named options:

=over 4

=item --blessed, -b

Additionally classify blessed references per package

=item --scalars, -S

Additionally classify SCALAR SVs according to which fields they have present

=item --struct

Use the structural size to sum byte counts

=item --owned

Use the owned size to sum byte counts

=back

=cut

use constant CMD_OPTS => (
   blessed => { help => "classify blessed references per package",
                alias => "b" },
   scalars => { help => "classify SCALARs according to present fields",
                alias => "S" },
   struct  => { help => "sum SVs by structural size" },
   owned   => { help => "sum SVs by owned size" },
);

struct Counts => [qw( svs bytes blessed_svs blessed_bytes )];

sub run
{
   my $self = shift;
   my %opts = %{ +shift };

   # TODO: consider options for
   #   sorting
   #   filtering

   my $size_meth = $opts{owned}  ? "owned_size" :
                   $opts{struct} ? "structure_size" :
                   "size";

   my %counts;
   my %counts_SCALAR;
   my %counts_per_package;

   foreach my $sv ( $self->df->heap ) {
      my $c = $counts{ref $sv} //= Counts( ( 0 ) x 4 );
      my $bytes = $sv->$size_meth;

      $c->svs++;
      $c->bytes += $bytes;

      if( $sv->blessed ) {
         $c->blessed_svs++;
         $c->blessed_bytes += $bytes;
      }

      if( $opts{scalars} and $sv->isa( "Devel::MAT::SV::SCALAR" ) ) {
         my $desc = $sv->desc;

         $c = $counts_SCALAR{$desc} //= Counts( ( 0 ) x 4 );

         $c->svs++;
         $c->bytes += $bytes;

         if( $sv->blessed ) {
            $c->blessed_svs++;
            $c->blessed_bytes += $bytes;
         }
      }

      $opts{blessed} or next;

      $c = $counts_per_package{ref $sv}{ $sv->blessed->stashname } //= Counts( ( 0 ) x 4 );
      $c->blessed_svs++;
      $c->blessed_bytes += $bytes;
   }

   my @table = (
      [ "  Kind", "Count", "(blessed)", "Bytes", "(blessed)" ],
   );

   foreach ( sort keys %counts ) {
      my $kind = $_ =~ s/^Devel::MAT::SV:://r;
      my $c = $counts{$_};

      push @table, [ "  $kind", $c->svs, $c->blessed_svs // "",
            Devel::MAT::Cmd->format_bytes( $c->bytes ),
            $c->blessed_bytes ? Devel::MAT::Cmd->format_bytes( $c->blessed_bytes ) : "" ];

      push @table, _gen_package_breakdown( $counts_per_package{$_} ) if $opts{blessed};

      if( $kind eq "SCALAR" and $opts{scalars} ) {
         foreach ( sort keys %counts_SCALAR ) {
            my $c = $counts_SCALAR{$_};

            push @table, [ "    $_", $c->svs, $c->blessed_svs // "",
                  Devel::MAT::Cmd->format_bytes( $c->bytes ),
                  $c->blessed_bytes ? Devel::MAT::Cmd->format_bytes( $c->blessed_bytes ) : "" ];
         }
      }
   }

   push @table, [ "  -----", ( "" ) x 4 ];

   my $total = Counts( ( 0 ) x 4 );
   foreach my $method (qw( svs bytes blessed_svs blessed_bytes )) {
      $total->$method = sum map { $_->$method } values %counts;
   }

   push @table, [ "  (total)", $total->svs, $total->blessed_svs // "",
            Devel::MAT::Cmd->format_bytes( $total->bytes ),
            $total->blessed_bytes ? Devel::MAT::Cmd->format_bytes( $total->blessed_bytes ) : "" ];

   Devel::MAT::Cmd->print_table( \@table,
      sep   => [ "    ", " ", "    ", " " ],
      align => [ undef, "right", "right", "right", "right" ],
   );
}

sub _gen_package_breakdown
{
   my ( $counts ) = @_;

   my @packages = rev_nsort_by { $counts->{$_}->blessed_svs } sort keys %$counts;

   my @ret;

   my $count;
   while( @packages ) {
      my $package = shift @packages;

      push @ret,
         [
            "    " . Devel::MAT::Cmd->format_symbol( $package ),
            "", $counts->{$package}->blessed_svs,
            "", Devel::MAT::Cmd->format_bytes( $counts->{$package}->blessed_bytes ),
         ];

      $count++;
      last if $count >= 10;
   }

   my $remaining = Counts( ( 0 ) x 4 );
   foreach my $method (qw( blessed_svs blessed_bytes )) {
      $remaining->$method = sum map { $counts->{$_}->$method } @packages;
   }

   push @ret,
      [ "    " . Devel::MAT::Cmd->format_note( "(others)" ),
         "", $remaining->blessed_svs,
         "", Devel::MAT::Cmd->format_bytes( $remaining->blessed_bytes ) ] if @packages;

   return @ret;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
