#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Tools 0.53;

use v5.14;
use warnings;
use base qw( Devel::MAT::Tool );

use constant CMD => "tools";
use constant CMD_DESC => "List the available tools";

sub run
{
   my $self = shift;

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

sub run
{
   my $self = shift;
   my ( $toolname ) = @_;

   my $tool = $self->pmat->load_tool( $toolname, progress => $self->{progress} );
   $self->report_progress();
}

0x55AA;
