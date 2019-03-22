#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2017 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Sizes;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );

our $VERSION = '0.42';

use constant FOR_UI => 1;

use List::Util qw( sum0 );
use List::UtilsBy qw( rev_nsort_by );

=head1 NAME

C<Devel::MAT::Tool::Sizes> - calculate sizes of SV structures

=head1 DESCRIPTION

This C<Devel::MAT> tool calculates the sizes of the structures around SVs.
The individual size of each individual SV is given by the C<size> method,
though in several cases SVs can be considered to be part of larger structures
of a combined aggregate size. This tool calculates those sizes and adds them
to the UI.

The structural size is calculated from the basic size of the SV, added to
which for various types is:

=over 2

=item ARRAY

Arrays add the basic size of every non-mortal element SV.

=item HASH

Hashes add the basic size of every non-mortal value SV.

=item CODE

Codes add the basic size of their padlist and constant value, and all their
padnames, pads, constants and globrefs.

=back

The owned size is calculated by starting at the given SV and accumulating the
set of every strong outref whose refcount is 1. This is the set of all SVs the
original directly owns.

=cut

sub init_ui
{
   my $self = shift;
   my ( $ui ) = @_;

   my %size_tooltip = (
      SV        => "Display the size of each SV individually",
      Structure => "Display the size of SVs including its internal structure",
      Owned     => "Display the size of SVs including all owned referrents",
   );

   $ui->provides_radiobutton_set(
      map {
         my $size = $_ eq "SV" ? "size" : "\L${_}_size";

         $ui->register_icon(
            name => "size-$_",
            svg  => "icons/size-$_.svg",
         );

         {
            text    => $_,
            icon    => "size-$_",
            tooltip => $size_tooltip{$_},
            code    => sub {
               $ui->set_svlist_column_values(
                  column => Devel::MAT::UI->COLUMN_SIZE,
                  from   => sub { shift->$size },
               );
            },
         }
      } qw( SV Structure Owned )
   );
}

=head1 SV METHODS

This tool adds the following SV methods.

=head2 structure_set

   @svs = $sv->structure_set

Returns the total set of the SV's structure.

=head2 structure_size

   $size = $sv->structure_size

Returns the size, in bytes, of the structure that the SV contains.

=cut

# Most SVs' structual set is just themself
sub Devel::MAT::SV::structure_set { shift }

# ARRAY structure includes the element SVs
sub Devel::MAT::SV::ARRAY::structure_set
{
   my $av = shift;
   my @svs = ( $av, grep { $_ && !$_->immortal } $av->elems );
   return @svs;
}

# HASH structure includes the value SVs
sub Devel::MAT::SV::HASH::structure_set
{
   my $hv = shift;
   my @svs = ( $hv, grep { $_ && !$_->immortal } $hv->values );
   return @svs;
}

# CODE structure includes PADLIST, PADNAMES, PADs, and all pad name and pad SVs
sub Devel::MAT::SV::CODE::structure_set
{
   my $cv = shift;
   my @svs = ( $cv, grep { $_ && !$_->immortal }
      $cv->padlist, $cv->padnames_av, $cv->pads,
      $cv->constval, $cv->constants, $cv->globrefs );
   return @svs;
}

sub Devel::MAT::SV::structure_size
{
   return sum0 map { $_->size } shift->structure_set
}

=head2 owned_set

   @svs = $sv->owned_set

Returns the set of every SV owned by the given one.

=head2 owned_size

   $size = $sv->owned_size

Returns the total size, in bytes, of the SVs owned by the given one.

=cut

sub Devel::MAT::SV::owned_set
{
   my @more = ( shift );

   my %seen;
   my @owned;

   while( @more ) {
      my $next = pop @more;
      push @owned, $next;

      $seen{$next->addr}++;
      push @more, grep { !$seen{$_->addr} and
                         !$_->immortal and
                         $_->refcnt == 1 } map { $_->sv } $next->outrefs_strong;
   }
   return @owned;
}

sub Devel::MAT::SV::owned_size
{
   my $sv = shift;
   return $sv->{tool_sizes_owned} //= sum0 map { $_->size } $sv->owned_set;
}

=head1 COMMANDS

=cut

=head2 size

Prints the sizes of a given SV

   pmat> size defstash
   STASH(61) at 0x556e47243e10=defstash consumes:
     2.1 KiB directly
     11.2 KiB structurally
     54.2 KiB including owned referrants

=cut

use constant CMD => "size";
use constant CMD_DESC => "Show the size of a given SV";

use constant CMD_ARGS_SV => 1;

sub run
{
   my $self = shift;
   my ( $sv ) = @_;

   Devel::MAT::Cmd->printf( "%s consumes:\n",
      Devel::MAT::Cmd->format_sv( $sv )
   );

   Devel::MAT::Cmd->printf( "  %s directly\n",
      Devel::MAT::Cmd->format_bytes( $sv->size )
   );
   Devel::MAT::Cmd->printf( "  %s structurally\n",
      Devel::MAT::Cmd->format_bytes( $sv->structure_size )
   );
   Devel::MAT::Cmd->printf( "  %s including owned referrants\n",
      Devel::MAT::Cmd->format_bytes( $sv->owned_size )
   );
}

package # hide
   Devel::MAT::Tool::Sizes::_largest;
use base qw( Devel::MAT::Tool );

=head2 largest

   pmat> largest -owned
   STASH(61) at 0x55e4317dfe10: 54.2 KiB: of which
    |   GLOB(%*) at 0x55e43180be60: 16.9 KiB: of which
    |    |   STASH(40) at 0x55e43180bdd0: 16.7 KiB
    |    |   GLOB(&*) at 0x55e4318ad330: 2.8 KiB
    |    |   others: 15.0 KiB
    |   GLOB(%*) at 0x55e4317fdf28: 4.1 KiB: of which
    |    |   STASH(34) at 0x55e4317fdf40: 4.0 KiB bytes
   ...

Finds and prints the largest SVs by size. The 5 largest SVs are shown.

If counting sizes in a way that includes referred SVs, a tree is printed
showing the 3 largest SVs within these, and of those the 2 largest referred
SVs again. This should help identify large memory occupiers.

Takes the following named options:

=over 4

=item --struct

Count SVs using the structural size.

=item --owned

Count SVs using the owned size.

=back

By default, only the individual SV size is counted.

=cut

use constant CMD => "largest";
use constant CMD_DESC => "Find the largest SVs by size";

use Heap;
use List::UtilsBy qw( max_by );

my %seen;

sub list_largest_svs
{
   my ( $svlist, $metric, $indent, @counts ) = @_;

   my $method = $metric ? "${metric}_size" : "size";

   my $heap = Heap::Fibonacci->new;
   $heap->add( Devel::MAT::Tool::Sizes::_Elem->new( $_->$method, $_ ) ) for @$svlist;

   my $count = shift @counts;
   while( $count-- ) {
      my $topelem = $heap->extract_top or last;
      my $largest = $topelem->sv;

      $seen{$largest->addr}++;

      Devel::MAT::Cmd->printf( "$indent%s: %s",
         Devel::MAT::Cmd->format_sv( $largest ),
         Devel::MAT::Cmd->format_bytes( $largest->$method ),
      );

      if( !defined $metric or !@counts ) {
         Devel::MAT::Cmd->printf( "\n" );
         next;
      }

      my $set_method = "${metric}_set";
      my @set = $largest->$set_method;
      shift @set; # SV itself is always first

      if( !@set ) {
         Devel::MAT::Cmd->printf( "\n" );
         next;
      }

      Devel::MAT::Cmd->printf( ": of which\n" );
      list_largest_svs( \@set, $metric, "${indent} |   ", @counts );

      $seen{$_->addr}++ for @set;
   }

   my $others = 0;
   $others += $_->size for grep { !$seen{$_->addr} } @$svlist;

   if( $others ) {
      Devel::MAT::Cmd->printf( "$indent%s: %s\n",
         Devel::MAT::Cmd->format_note( "others" ),
         Devel::MAT::Cmd->format_bytes( $others ),
      );
   }
}

package Devel::MAT::Tool::Sizes::_Elem {
   sub new { my ( $class, $val, $sv ) = @_; bless [ $val, $sv ], $class }

   sub sv { my $self = shift; return $self->[1]; }
   sub heap { my $self = shift; $self->[2] = shift if @_; return $self->[2] }

   sub cmp { my ( $self, $other ) = @_; return $other->[0] <=> $self->[0] }
}

use constant CMD_OPTS => (
   struct => { help => "count SVs by structural size" },
   owned  => { help => "count SVs by owned size" },
);

use constant CMD_ARGS => (
   { name => "count", help => "how many items to display",
     repeated => 1 },
);

sub run
{
   my $self = shift;
   my %opts = %{ +shift };

   my @counts = ( 5, 3, 2 );
   $counts[$_] = $_[$_] for 0 .. $#_;

   my $df = $self->df;

   my $METRIC;
   $METRIC = "structure" if $opts{struct};
   $METRIC = "owned"     if $opts{owned};

   my @svs = $df->heap;

   my $method = $METRIC ? "${METRIC}_size" : "size";

   my $heap_total = scalar @svs;
   my $count = 0;
   foreach my $sv ( @svs ) {
      $count++;
      $self->report_progress( sprintf "Calculating sizes in %d of %d (%.2f%%)",
         $count, $heap_total, 100*$count / $heap_total ) if $count % 20000 == 0;
      $sv->$method;
   }
   $self->report_progress();

   undef %seen;
   list_largest_svs( \@svs, $METRIC, "", @counts );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
