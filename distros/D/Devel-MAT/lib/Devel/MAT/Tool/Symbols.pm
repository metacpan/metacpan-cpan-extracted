#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017-2018 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Symbols 0.47;

use v5.14;
use warnings;
use base qw( Devel::MAT::Tool );

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
      Devel::MAT::Cmd->format_symbol( $name, $sv ),
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

   Devel::MAT::Tool::more->paginate( sub {
      my ( $count ) = @_;
      while( $count and @queue ) {
         $_ = shift @queue;
         if( $_->[0]->isa( "Devel::MAT::SV::GLOB" ) ) {
            my ( $gv, $name ) = @$_;
            _show_symbol( '$' . $name, $gv->scalar ), $count-- if $gv->scalar;
            _show_symbol( '@' . $name, $gv->array  ), $count-- if $gv->array;
            _show_symbol( '%' . $name, $gv->hash   ), $count-- if $gv->hash;
            _show_symbol( '&' . $name, $gv->code   ), $count-- if $gv->code;

            unshift @queue, [ $gv->hash, $name ] if $gv->hash;
         }
         elsif( $opts{recurse} and $_->[0]->isa( "Devel::MAT::SV::STASH" ) ) {
            my ( $stash, $prefix ) = @$_;
            unshift @queue, extract_symbols( $stash, $prefix );
         }
      }

      return !!@queue;
   } );
}

package Devel::MAT::Tool::Symbols::_packages;

use base qw( Devel::MAT::Tool );

use constant CMD => "packages";
use constant CMD_DESC => "Display a list of the packages in the symbol table";

=head2 packages

Prints a list of every package name in the symbol table.

   pmat> packages
   package CORE at STASH(1) at 0x55cde0f74240
   package CORE::GLOBAL at STASH(0) at 0x55cde0f74270
   package Carp at STASH(4) at 0x55cde0fa1508
   ...

Takes the following named options:

=over 4

=item --versions, -V

Include the value of the I<$VERSION> of each package, if relevant.

=back

=cut

use constant CMD_OPTS => (
   versions => { help => "show the \$VERSION of each package",
                 alias => "V" },
);

sub _versionof
{
   my ( $stash ) = @_;

   # TODO: might be nice to have $stash->find_symbol
   my $versiongv = $stash->value( 'VERSION' ) or return "";
   my $versionsv = $versiongv->scalar or return "";

   my $version = $versionsv->pv // $versionsv->nv // $versionsv->uv;
   return " " . Devel::MAT::Cmd->format_value( $version );
}

sub run
{
   my $self = shift;
   my %opts = %{ +shift };

   my @queue = grep { $_->[1] ne "main::" }
      Devel::MAT::Tool::Symbols::extract_symbols( $self->df->defstash, "" );

   Devel::MAT::Tool::more->paginate( sub {
      my ( $count ) = @_;
      while( $count and @queue ) {
         $_ = shift @queue;
         my ( $gv, $name ) = @$_;
         next unless my $stash = $gv->hash;
         next unless $stash->isa( "Devel::MAT::SV::STASH" );

         Devel::MAT::Cmd->printf( "%s %s at %s\n",
            Devel::MAT::Cmd->format_note( "package" ),
            Devel::MAT::Cmd->format_symbol( $name =~ s/::$//r, $stash ) .
               ( $opts{versions} ? _versionof( $stash ) : "" ),
            Devel::MAT::Cmd->format_sv( $stash ),
         );
         $count--;

         unshift @queue, grep {
            $_->[0]->isa( "Devel::MAT::SV::GLOB" )
         } Devel::MAT::Tool::Symbols::extract_symbols( $stash, $name );
      }

      return !!@queue;
   } );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
