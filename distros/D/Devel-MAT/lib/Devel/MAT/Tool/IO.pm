#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2017 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::IO;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );

our $VERSION = '0.35';

use constant CMD => "io";
use constant CMD_DESC => "Commands working with IO SVs";

=head1 NAME

C<Devel::MAT::Tool::IO> - list IO SVs

=head1 DESCRIPTION

This C<Devel::MAT> tool operates on IO handle SVs.

=cut

=head1 COMMANDS

=cut

use constant CMD_SUBS => qw(
   list
);

sub _print_ios
{
   shift;
   my @svs = @_;

   Devel::MAT::Cmd->print_table(
      [
         [ "Addr", "ifileno", "ofileno" ],
         map { my $sv = $_; [
            Devel::MAT::Cmd->format_sv( $sv ),
            $sv->ifileno // "-",
            $sv->ofileno // "-",
         ] } @svs
      ],
      align => [ undef, "right", "right" ],
   );
}

package # hide
   Devel::MAT::Tool::IO::list;
use base qw( Devel::MAT::Tool );

use constant CMD_DESC => "List all the IO SVs in the heap";

=head2 io list

   pmat> io list
   Addr                           ifileno  ofileno
   IO() at 0x1bbf640              -1       -1
   IO() at 0x1bbf508              0        -1
   ...

Prints a list of all the IO handles that have filenumbers.

=cut

sub _by_fileno
{
   my ( $ai, $ao ) = split m{/}, $a;
   my ( $bi, $bo ) = split m{/}, $b;

   return $ai <=> $bi || $ao <=> $bo;
}

sub run
{
   my $self = shift;

   my %ios;

   foreach my $sv ( $self->df->heap ) {
      next unless $sv->type eq "IO";

      my $ifileno = $sv->ifileno // -1;
      my $ofileno = $sv->ofileno // -1;

      $ios{"$ifileno/$ofileno"} = $sv;
   }

   Devel::MAT::Tool::IO->_print_ios( map { $ios{$_} } sort _by_fileno keys %ios );
}

package # hide
   Devel::MAT::Tool::IO::find;
use base qw( Devel::MAT::Tool );

# This tool for back-compat only; it's been renamed.

use constant CMD_ARGS => (
   { name => "fileno", help => "the file number" }
);

sub run
{
   my $self = shift;
   my ( $num ) = @_;

   Devel::MAT::Cmd->printf( "%s - this tool has been renamed to 'find io'\n",
      Devel::MAT::Cmd->format_note( "Note", 2 )
   );
   $self->pmat->load_tool( "Find" )
      ->run_cmd( qw( io ), $num );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
