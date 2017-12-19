#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2017 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Identify;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );
use utf8;

our $VERSION = '0.32';

use List::Util qw( any pairs );
use List::UtilsBy qw( nsort_by );

use constant CMD => "identify";
use constant CMD_DESC => "Identify an SV by its referrers";

=encoding UTF-8

=head1 NAME

C<Devel::MAT::Tool::Identify> - identify an SV by its referrers

=head1 DESCRIPTION

This C<Devel::MAT> tool provides a command to identify an SV by walking up its
tree of inrefs, printing useful information that helps to identify what it is
by how it can be reached from well-known program roots.

=cut

my %STRENGTH_ORDER = (
   strong   => 1,
   weak     => 2,
   indirect => 3,
   inferred => 4,
);

sub _strength_label
{
   my ( $strength ) = @_;
   $strength eq "strong" ? "" :
      Devel::MAT::Cmd->format_note( "[$strength]", 1 ) . " ",
}

my $next_id;
my %id_for;
my %seen;

sub walk_graph
{
   my ( $node, $indent ) = @_;
   $indent //= "";

   my @roots = $node->roots;
   my @edges = $node->edges_in;

   if( !@roots and !@edges ) {
      Devel::MAT::Cmd->printf( "$indent└─not found\n" );
      return;
   }

   if( @roots == 1 and $roots[0] eq "EDEPTH" ) {
      Devel::MAT::Cmd->printf( "$indent└─not found at this depth\n" );
      return;
   }

   # Don't bother showing any non-root edges if we have a strong root
   @edges = () if any { $_->strength eq "strong" } @roots;

   if( @edges > 0 and $seen{$node->addr}++ ) {
      Devel::MAT::Cmd->printf( "$indent└─already found " );

      if( defined( my $id = $id_for{$node->addr} ) ) {
         Devel::MAT::Cmd->printf( "as %s\n",
            Devel::MAT::Cmd->format_note( "*$id" ),
         );
      }
      else {
         Devel::MAT::Cmd->printf( "%s\n",
            Devel::MAT::Cmd->format_note( "circularly" ),
         );
      }
      return;
   }

   foreach my $idx ( 0 .. $#roots ) {
      my $isfinal = $idx == $#roots && !@edges;

      Devel::MAT::Cmd->printf( $indent . ( $isfinal ? "└─%s%s\n" : "├─%s%s\n" ),
         _strength_label( $roots[$idx]->strength ),
         $roots[$idx]->name,
      );
   }

   my @refs = nsort_by { $STRENGTH_ORDER{$_->[0]->strength} } pairs @edges;
   foreach my $idx ( 0 .. $#refs ) {
      my ( $ref, $refnode ) = @{ $refs[$idx] };
      my $is_final = $idx == $#refs;

      Devel::MAT::Cmd->printf(
         $indent . ( $is_final ? "└─" : "├─" ) );

      my $ref_id;
      if( $refnode->edges_out > 1 and not $refnode->roots and not $id_for{$refnode->addr} ) {
         $ref_id = $id_for{$refnode->addr} = $next_id++;
      }

      Devel::MAT::Cmd->printf( "%s%s of %s, which is",
         _strength_label( $ref->strength ),
         $ref->name,
         Devel::MAT::Cmd->format_sv( $refnode->sv ),
      );

      if( $ref_id ) {
         Devel::MAT::Cmd->printf( " %s",
            Devel::MAT::Cmd->format_note( "(*$ref_id)" ),
         );
      }

      Devel::MAT::Cmd->printf( ":\n" );

      my $subindent = $indent . ( $is_final ? "  " : "│ " );

      if( $refnode->addr == $node->addr ) {
         Devel::MAT::Cmd->printf( "${subindent}itself\n" );
      }
      else {
         walk_graph( $refnode, $subindent );
      }
   }
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

Don't elide structure in the output.

By default, C<REF()>-type SVs will be skipped over, leading to a shorter
neater output by removing this usually-unnecessary noise. If this option is
not given, elided reference SVs will be notated by adding C<(via RV)> to the
reference description.

Additionally, members of the symbol table will be printed as being root SVs,
noting their symbol table name. This avoids additional nesting due to the
stashes and globs that make up the symbol table. This can also cause SVs to be
recognised as symbol table entries, when without it they might be cut off due
to the depth limit.

=back

=cut

use constant CMD_OPTS => (
   depth    => { help => "maximum depth to recurse",
                 type => "i",
                 alias => "d",
                 default => 10 },
   weak     => { help => "include weak references" },
   all      => { help => "include weak and indirect references",
                 alias => "a" },
   no_elide => { help => "don't elide REF, PAD and symbol structures",
                 alias => "n" },
);

use constant CMD_ARGS_SV => 1;

sub run
{
   my $self = shift;
   my %opts = %{ +shift };
   my ( $sv ) = @_;

   # reset
   $next_id = "A";
   undef %id_for;
   undef %seen;

   my $STRONG = 1;
   my $DIRECT = 1;
   my $ELIDE  = !$opts{no_elide};

   $STRONG = 0              if $opts{weak};
   $STRONG = 0, $DIRECT = 0 if $opts{all};

   $self->pmat->load_tool( "Inrefs", progress => $self->{progress} );

   Devel::MAT::Cmd->printf( "%s is:\n",
      Devel::MAT::Cmd->format_sv( $sv ),
   );

   walk_graph( $self->pmat->inref_graph( $sv,
      depth => $opts{depth},
      strong => $STRONG,
      direct => $DIRECT,
      elide  => $ELIDE,
   ) );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
