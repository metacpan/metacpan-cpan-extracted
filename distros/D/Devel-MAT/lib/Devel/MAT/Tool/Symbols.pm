#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Symbols;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );

our $VERSION = '0.34';

use constant CMD => "symbols";
use constant CMD_DESC => "Display a list of the symbol table";

=head1 NAME

C<Devel::MAT::Tool::Symbols> - display a list of the symbol table

=head1 DESCRIPTION

This C<Devel::MAT> tool displays a list names from the symbol table.

=cut

=head1 COMMANDS

=head2 symbols

   pmat> symbols strict
   $strict::VERSION
   &strict::all_bits
   &strict::all_explicit_bits
   &strict::bits
   &strict::import
   &strict::unimport

Prints a list of every name inside a symbol table hash ("stash"), starting
from the one given by name, or the toplevel default stash if none is provided.

Takes the following named options:

=over 4

=item --recurse, -R

Recursively show the inner symbols inside stashes.

=back

=cut

sub extract_symbols
{
   my ( $stash, $prefix ) = @_;

   my @ret;
   foreach my $key ( sort $stash->keys ) {
      my $gv = $stash->value( $key );

      my $name;
      if( $key =~ m/^([\0-\x1f])/ ) {
         $name = "{^" . chr(ord($1)+0x40) . substr( $key, 1 ) . "}";
      }
      else {
         $name = $prefix . $key;
      }

      push @ret, [ $gv, $name ];
   }

   return @ret;
}

sub _show_symbol
{
   my ( $name, $sv ) = @_;

   Devel::MAT::Cmd->printf( "%s at %s\n",
      $name,
      Devel::MAT::Cmd->format_sv( $sv ),
   );
}

use constant CMD_OPTS => (
   recurse => { help => "recursively show inner symbols",
                alias => "R" },
);

use constant CMD_ARGS => (
   { name => "start", help => "show symbols within this symbol, rather than %main::" },
);

sub run
{
   my $self = shift;
   my %opts = %{ +shift };

   my $df = $self->df;

   my @queue;

   if( @_ ) {
      my $name = shift @_;
      @queue = extract_symbols( $self->pmat->find_stash( $name ), $name . "::" );
   }
   else {
      # Don't recurse into self-referential 'main::' symbol
      @queue = grep { $_->[1] ne "main::" }
         extract_symbols( $df->defstash, "" );

      # Also skip the "debug location" symbols, whatever those are
      @queue = grep { $_->[1] !~ m/^_</ } @queue;
   }

   while( @queue ) {
      $_ = shift @queue;
      if( $_->[0]->isa( "Devel::MAT::SV::GLOB" ) ) {
         my ( $gv, $name ) = @$_;
         _show_symbol( '$' . $name, $gv->scalar ) if $gv->scalar;
         _show_symbol( '@' . $name, $gv->array  ) if $gv->array;
         _show_symbol( '%' . $name, $gv->hash   ) if $gv->hash;
         _show_symbol( '&' . $name, $gv->code   ) if $gv->code;

         unshift @queue, [ $gv->hash, $name ] if $gv->hash;
      }
      elsif( $opts{recurse} and $_->[0]->isa( "Devel::MAT::SV::STASH" ) ) {
         my ( $stash, $prefix ) = @$_;
         unshift @queue, extract_symbols( $stash, $prefix );
      }
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
