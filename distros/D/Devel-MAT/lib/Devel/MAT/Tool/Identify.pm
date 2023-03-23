#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2017 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Identify 0.51;

use v5.14;
use warnings;
use base qw( Devel::MAT::ToolBase::GraphWalker );
use utf8;

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

   $self->reset;

   my $STRONG = 1;
   my $DIRECT = 1;
   my $ELIDE  = !$opts{no_elide};

   $STRONG = 0              if $opts{weak};
   $STRONG = 0, $DIRECT = 0 if $opts{all};

   $self->pmat->load_tool( "Inrefs", progress => $self->{progress} );

   Devel::MAT::Cmd->printf( "%s is:\n",
      Devel::MAT::Cmd->format_sv( $sv ),
   );

   $self->walk_graph( $self->pmat->inref_graph( $sv,
      depth => $opts{depth},
      strong => $STRONG,
      direct => $DIRECT,
      elide  => $ELIDE,
   ), "" );
}

sub _strength_label
{
   my ( $strength ) = @_;
   $strength eq "strong" ? "" :
      Devel::MAT::Cmd->format_note( "[$strength]", 1 ) . " ",
}

sub on_walk_nothing
{
   shift;
   my ( $node, $indent ) = @_;
   Devel::MAT::Cmd->printf( "$indent└─not found\n" );
}

sub on_walk_EDEPTH
{
   shift;
   my ( $node, $indent ) = @_;
   Devel::MAT::Cmd->printf( "$indent└─not found at this depth\n" );
}

sub on_walk_again
{
   shift;
   my ( $node, $cyclic, $id, $indent ) = @_;

   Devel::MAT::Cmd->printf( "$indent└─already found " );

   Devel::MAT::Cmd->printf( "%s ",
      Devel::MAT::Cmd->format_note( "circularly" )
   ) if $cyclic;

   if( defined $id ) {
      Devel::MAT::Cmd->printf( "as %s\n",
         Devel::MAT::Cmd->format_note( "*$id" ),
      );
   }
   else {
      Devel::MAT::Cmd->printf( "%s\n",
         Devel::MAT::Cmd->format_note( "circularly" ),
      );
   }
}

sub on_walk_root
{
   shift;
   my ( $node, $root, $isfinal, $indent ) = @_;

   Devel::MAT::Cmd->printf( $indent . ( $isfinal ? "└─%s%s\n" : "├─%s%s\n" ),
      _strength_label( $root->strength ), $root->name,
   );
}

sub on_walk_ref
{
   shift;
   my ( $node, $ref, $sv, $ref_id, $is_final, $indent ) = @_;

   Devel::MAT::Cmd->printf(
      $indent . ( $is_final ? "└─" : "├─" ) );

   Devel::MAT::Cmd->printf( "%s%s of %s, which is",
      _strength_label( $ref->strength ),
      $ref->name,
      Devel::MAT::Cmd->format_sv( $sv ),
   );

   if( $ref_id ) {
      Devel::MAT::Cmd->printf( " %s",
         Devel::MAT::Cmd->format_note( "(*$ref_id)" ),
      );
   }

   Devel::MAT::Cmd->printf( ":\n" );

   # return recursion args:
   return ( $indent . ( $is_final ? "  " : "│ " ) );
}

sub on_walk_itself
{
   shift;
   my ( $node, $indent ) = @_;
   Devel::MAT::Cmd->printf( "${indent}itself\n" );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
