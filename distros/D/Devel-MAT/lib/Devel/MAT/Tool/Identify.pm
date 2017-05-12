#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Identify;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );
use utf8;

our $VERSION = '0.25';

use Getopt::Long qw( GetOptionsFromArray );
use List::Util qw( pairs );
use List::UtilsBy qw( nsort_by );

use constant CMD => "identify";

=encoding UTF-8

=head1 NAME

C<Devel::MAT::Tool::Identify> - identify an SV by its ancestry

=head1 DESCRIPTION

This C<Devel::MAT> tool provides a command to identify an SV by walking up its
tree of inrefs, printing useful information that helps to identify what it is
by how it can be reached from well-known program roots.

=cut

my $YELLOW = "\e[33m";
my $CYAN   = "\e[36m";

my $NORMAL = "\e[m";

my %STRENGTH_ORDER = (
   strong   => 1,
   weak     => 2,
   indirect => 3,
   inferred => 4,
);

my $next_id;
my %id_for;
my %seen;

sub walk_graph
{
   my ( $node ) = @_;

   my @roots = $node->roots;
   my @edges = $node->edges_in;

   if( !@roots and !@edges ) {
      return "└─not found";
   }

   if( @roots == 1 and $roots[0] eq "EDEPTH" ) {
      return "└─not found at this depth";
   }

   if( @edges > 0 and $seen{$node->addr}++ ) {
      my $id = $id_for{$node->addr};
      return defined $id ? "└─already found as $YELLOW*$id$NORMAL"
                         : "└─already found ${YELLOW}circularly$NORMAL";
   }

   my @blocks = map { [ $_ ] } @roots;

   foreach ( nsort_by { $STRENGTH_ORDER{$_->[0]->strength} } pairs @edges ) {
      my ( $ref, $refnode ) = @$_;

      my $str = "";
      $str = "$CYAN\[${\$ref->strength}]$NORMAL" if $ref->strength ne "strong";

      my $ref_id;
      if( $refnode->edges_out > 1 and not $refnode->roots and not $id_for{$refnode->addr} ) {
         $ref_id = $id_for{$refnode->addr} = $next_id++;
      }

      my $header = sprintf "%s%s of %s, which is%s:",
         $str, $ref->name, $refnode->sv->desc_addr, $ref_id ? " $YELLOW(*$ref_id)$NORMAL" : "";

      if( $refnode->addr == $node->addr ) {
         push @blocks, [ $header, "itself" ];
      }
      else {
         push @blocks, [ $header, walk_graph( $refnode ) ];
      }
   }

   my @ret;
   foreach my $i ( 0 .. $#blocks ) {
      my $block = $blocks[$i];
      my $firstline = shift @$block;

      if( $i < $#blocks ) {
         push @ret, "├─$firstline",
              map { "│ $_" } @$block;
      }
      else {
         push @ret, "└─$firstline",
              map { "  $_" } @$block;
      }
   }

   return @ret;
}

=head1 COMMANDS

=cut

=head2 identify

   pmat> identify 0x1bbf640
   IO() at 0x1bbf640 is:
   └─the io of GLOB(@*I) at 0x1bbf628, which is:
     └─the ARGV GV

Prints a tree of the identification of the SV at the given address.

Takes the following named options:

=over 4

=item --depth D, -d D

Limits the output to the given number of steps away from the given initial SV.

=item --weak

Include weak direct references in the output (by default only strong direct
ones will be included).

=item --all

Include both weak and indirect references in the output.

=item --no-elide, -n

Don't elide C<REF()>-type SVs from the output. By default these will be
skipped over, leading to a shorter neater output by removing this
usually-unnecessary noise.

If this option is not given, elided reference SVs will be notated by adding
C<(via RV)> to the reference description.

=back

=cut

sub run_cmd
{
   my $self = shift;

   # reset
   $next_id = "A";
   undef %id_for;
   undef %seen;

   my $STRONG = 1;
   my $DIRECT = 1;
   my $ELIDE  = 1;

   GetOptionsFromArray( \@_,
      'depth|d=i'  => \my $DEPTH,
      'weak'       => sub { $STRONG = 0 },
      'all'        => sub { $STRONG = 0; $DIRECT = 0 },
      'no-elide|n' => sub { $ELIDE = 0; },
   ) or return;

   my $addr = $_[0] // die "Need an SV addr\n";
   $addr = hex $addr if $addr =~ m/^0x/;

   my $sv = $self->{df}->sv_at( $addr ) or
      die sprintf "No such SV at address %x\n", $addr;

   Devel::MAT::Cmd->printf( "%s is:\n", $sv->desc_addr );

   Devel::MAT::Cmd->printf( "%s\n", $_ ) for walk_graph( $self->{pmat}->inref_graph( $sv,
      depth => $DEPTH,
      strong => $STRONG,
      direct => $DIRECT,
      elide  => $ELIDE,
   ) );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
