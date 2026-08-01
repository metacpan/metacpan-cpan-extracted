#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022-2026 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Tools 0.56;

use v5.20;
use warnings;
use base qw( Devel::MAT::Tool );

use feature qw( postderef signatures );
no warnings qw( experimental::postderef experimental::signatures );

use constant CMD => "tools";
use constant CMD_DESC => "List the available tools";

=head1 NAME

C<Devel::MAT::Tool::Tools> - display a list of the available tools

=head1 DESCRIPTION

This C<Devel::MAT> tool displays a list of the names and descriptions of
additional tools that may be available, and allows loading them.

=cut

=head1 COMMANDS

=for highlighter

=head2 tools

   pmat> tools
     Reachability - <no desc>
     Sizes        - <no desc>

Prints a list of the names of every additional tool that is available to load
into the F<pmat> analysis shell. Each is prefixed with a C<*> if it is already
loaded.

Currently, only the tools marked C<FOR_UI> are actually listed, which isn't
helpful in the shell as many tools are useful without UI additions.

=cut

sub run ( $self )
{
   my @table;

   foreach my $tool ( sort Devel::MAT->available_tools ) {
      my $tool_class = "Devel::MAT::Tool::$tool";
      next unless $tool_class->can( "FOR_UI" ) and $tool_class->FOR_UI;

      my $desc = $tool_class->can( "TOOL_DESC" ) ? $tool_class->TOOL_DESC : undef;

      my $loaded = $self->pmat->has_tool( $tool );

      push @table, [
         String::Tagged->from_sprintf( "%s %s",
            ( $loaded ? Devel::MAT::Cmd->format_note( "*", 1 ) : " " ),
            Devel::MAT::Cmd->format_note( $tool, 0 ),
         ),
         $desc // "<no desc>"
      ];
   }

   Devel::MAT::Cmd->print_table( \@table, sep => " - " );
}

package # hide
   Devel::MAT::Tool::Tools::_tool;

use base qw( Devel::MAT::Tool );

use constant CMD => "tool";
use constant CMD_DESC => "Load an extension tool";

use constant CMD_ARGS => (
   { name => "tool", help => "the name of the tool to load" },
);

=head2 tool

Loads an additional analysis tool.

   pmat> tool Sizes

=cut

sub run ( $self, $toolname )
{
   my $tool = $self->pmat->load_tool( $toolname, progress => $self->{progress} );
   $self->report_progress();
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
