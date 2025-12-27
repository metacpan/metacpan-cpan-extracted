#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2024 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Show 0.54;

use v5.14;
use warnings;
use base qw( Devel::MAT::Tool );

use List::Util qw( max );

use constant CMD => "show";
use constant CMD_DESC => "Show information about a given SV";

use constant CMD_OPTS => (
   full_pv => { help => "show the full captured PV",
                alias => "F" },
   pad => { help => "show the first PAD of a CODE",
            alias => "P" },
);

=head1 NAME

C<Devel::MAT::Tool::Show> - show information about a given SV

=head1 DESCRIPTION

This C<Devel::MAT> tool provides a command that prints interesting information
from within an SV. Its exact output will depend on the type of SV it is
applied to.

=cut

=head1 COMMANDS

=cut

=head2 show

   pmat> show 0x1bbf598
   IO() at 0x1bbf598 with refcount 2
     blessed as IO::File
     ifileno=2
     ofileno=2

Prints information about the given SV.

=cut

use constant CMD_ARGS_SV => 1;

my @SHOW_EXTRA;
sub register_extra
{
   shift;
   my ( $code ) = @_;
   push @SHOW_EXTRA, $code;
}

sub run
{
   my $self = shift;
   my %opts = %{ +shift };
   my ( $sv ) = @_;

   Devel::MAT::Cmd->printf( "%s with refcount %d%s\n",
      Devel::MAT::Cmd->format_sv( $sv ),
      $sv->refcnt,
      $sv->is_mortal ? ( " " . Devel::MAT::Cmd->format_note( "(mortalized)", 1 ) ) : "",
   );

   my $size = $sv->size;
   if( $size < 1024 ) {
      Devel::MAT::Cmd->printf( "  size %d bytes\n",
         $size,
      );
   }
   else {
      Devel::MAT::Cmd->printf( "  size %s (%d bytes)\n",
         Devel::MAT::Cmd->format_bytes( $size ),
         $size,
      );
   }

   if( my $stash = $sv->blessed ) {
      Devel::MAT::Cmd->printf( "  blessed as %s\n", $stash->stashname );
   }

   if( my $symname = $sv->symname ) {
      Devel::MAT::Cmd->printf( "  named as %s\n",
         Devel::MAT::Cmd->format_symbol( $symname )
      );
   }

   foreach my $magic ( $sv->magic ) {
      my $type = $magic->type;
      $type = "^" . chr( 0x40 + ord $type ) if ord $type < 0x20;

      Devel::MAT::Cmd->printf( "  has %s magic",
         Devel::MAT::Cmd->format_note( $type, 1 ),
      );

      Devel::MAT::Cmd->printf( " with object at %s",
         Devel::MAT::Cmd->format_sv( $magic->obj )
      ) if $magic->obj;

      Devel::MAT::Cmd->printf( " with pointer at %s",
         Devel::MAT::Cmd->format_sv( $magic->ptr )
      ) if $magic->ptr;

      Devel::MAT::Cmd->printf( "\n     with virtual table at %s",
         Devel::MAT::Cmd->format_value( $magic->vtbl, addr => 1 )
      ) if $magic->vtbl;

      Devel::MAT::Cmd->printf( "\n" );
   }

   if( defined( my $serial = $sv->debug_serial ) ) {
      Devel::MAT::Cmd->printf( "  debug serial %d\n", $serial );

      my $file = $sv->debug_file;
      Devel::MAT::Cmd->printf( "  created at %s:%d\n", $file, $sv->debug_line )
         if defined $file;
   }

   foreach my $extra ( @SHOW_EXTRA ) {
      $extra->( $sv ); # TODO: consider opts?
   }

   my $type = $sv->type;
   my $method = "show_$type";
   $self->$method( $sv, \%opts );
}

sub say_with_sv
{
   my ( $str, @args ) = @_;
   my $sv = pop @args;

   Devel::MAT::Cmd->printf( $str . "%s\n",
      @args,
      Devel::MAT::Cmd->format_sv( $sv ),
   );
}

sub show_GLOB
{
   my $self = shift;
   my ( $gv ) = @_;

   if( $gv->name ) {
      Devel::MAT::Cmd->printf( "  name=%s\n", $gv->name );
      Devel::MAT::Cmd->printf( "  name_hek=%s\n", Devel::MAT::Cmd->format_value( $gv->name_hek, addr => 1 ) ) if $gv->name_hek;
   }

   say_with_sv '  stash=', $gv->stash if $gv->stash;

   say_with_sv '  SCALAR=', $gv->scalar if $gv->scalar;
   say_with_sv '  ARRAY=',  $gv->array  if $gv->array;
   say_with_sv '  HASH=',   $gv->hash   if $gv->hash;
   say_with_sv '  CODE=',   $gv->code   if $gv->code;
   say_with_sv '  EGV=',    $gv->egv    if $gv->egv;
   say_with_sv '  IO=',     $gv->io     if $gv->io;
   say_with_sv '  FORM=',   $gv->form   if $gv->form;
}

sub show_SCALAR
{
   my $self = shift;
   my ( $sv, $opts ) = @_;

   Devel::MAT::Cmd->printf( "  UV=%s\n",
      Devel::MAT::Cmd->format_value( $sv->uv, nv => 1 ),
   ) if defined $sv->uv;
   Devel::MAT::Cmd->printf( "  IV=%s\n",
      Devel::MAT::Cmd->format_value( $sv->iv, nv => 1 ),
   ) if defined $sv->iv;
   Devel::MAT::Cmd->printf( "  NV=%s\n",
      Devel::MAT::Cmd->format_value( $sv->nv, nv => 1 ),
   ) if defined $sv->nv;

   if( defined( my $pv = $sv->pv ) ) {
      Devel::MAT::Cmd->printf( "  PV=%s\n",
         Devel::MAT::Cmd->format_value( $pv, pv => 1,
             ( $opts->{full_pv} ? ( maxlen => 0 ) : () ),
         ),
      );
      Devel::MAT::Cmd->printf( "  PVLEN %d\n", $sv->pvlen );

      Devel::MAT::Cmd->printf( "  SHARED_HEK=%s\n",
         Devel::MAT::Cmd->format_value( $sv->shared_hek, addr => 1 ),
      ) if $sv->shared_hek;
   }
}

sub show_BOOL
{
   my $self = shift;
   my ( $sv, $opts ) = @_;

   Devel::MAT::Cmd->printf( "  BOOL=%s\n",
      Devel::MAT::Cmd->format_value( $sv->uv ? "true" : "false" )
   );
}

sub show_REF
{
   my $self = shift;
   my ( $sv ) = @_;

   say_with_sv '  RV=', $sv->rv if $sv->rv;
}

sub show_ARRAY
{
   my $self = shift;
   my ( $av ) = @_;

   Devel::MAT::Cmd->printf( "  %d elements (use 'elems' command to show)\n",
      $av->n_elems,
   );
}

sub show_STASH
{
   my $self = shift;
   my ( $hv ) = @_;

   Devel::MAT::Cmd->printf( "  stashname=%s\n", $hv->stashname );
   $self->show_HASH( $hv );
}

sub show_HASH
{
   my $self = shift;
   my ( $hv ) = @_;

   Devel::MAT::Cmd->printf( "  %d values (use 'values' command to show)\n",
      $hv->n_values,
   );
}

sub show_CODE
{
   my $self = shift;
   my ( $cv, $opts ) = @_;

   $cv->name_hek ? Devel::MAT::Cmd->printf( "  name_hek=%s\n", Devel::MAT::Cmd->format_value( $cv->name_hek, addr => 1 ) )
                 : ();

   $cv->hekname  ? Devel::MAT::Cmd->printf( "  hekname=%s\n", $cv->hekname )
                 : Devel::MAT::Cmd->printf( "  no hekname\n" );

   $cv->stash    ? say_with_sv( "  stash=", $cv->stash )
                 : Devel::MAT::Cmd->printf( "  no stash\n" );

   $cv->glob     ? say_with_sv( "  glob=", $cv->glob )
                 : Devel::MAT::Cmd->printf( "  no glob\n" );

   $cv->location ? Devel::MAT::Cmd->printf( "  location=%s\n", $cv->location )
                 : Devel::MAT::Cmd->printf( "  no location\n" );

   $cv->scope    ? say_with_sv( "  scope=", $cv->scope )
                 : Devel::MAT::Cmd->printf( "  no scope\n" );

   $cv->padlist  ? say_with_sv( "  padlist=", $cv->padlist )
                 : ();

   $cv->padnames_av ? say_with_sv( "  padnames_av=", $cv->padnames_av )
                    : ();

   $cv->protosub ? say_with_sv( "  protosub=", $cv->protosub )
                 : ();

   my @pads = $cv->pads;
   foreach my $depth ( 0 .. $#pads ) {
      next unless $pads[$depth];
      say_with_sv( "  pad[$depth]=", $pads[$depth] );
   }

   if( $opts->{pad} and my $pad0 = ( $cv->pads )[0] ) {
      Devel::MAT::Cmd->printf( "PAD[0]:\n" );
      $self->show_PAD_contents( $pad0 );
   }

   if( my @globs = $cv->globrefs ) {
      Devel::MAT::Cmd->printf( "Referenced globs:\n  " );
      Devel::MAT::Cmd->printf( "%s, ", Devel::MAT::Cmd->format_sv( $_ ) ) for @globs;
      Devel::MAT::Cmd->printf( "\n" );
   }
}

sub show_PAD
{
   my $self = shift;
   my ( $pad ) = @_;

   my $padcv = $pad->padcv;
   $padcv ? say_with_sv( "  padcv=", $padcv )
          : Devel::MAT::Cmd->printf( "  no padcv\n" );

   $self->show_PAD_contents( $pad );
}

sub _join
{
   # Like CORE::join but respects string concat operator
   my ( $sep, @elems ) = @_;
   my $ret = shift @elems;
   $ret = $ret . $sep . $_ for @elems;
   return $ret;
}

sub show_PAD_contents
{
   my $self = shift;
   my ( $pad ) = @_;

   my $padcv = $pad->padcv;

   my @elems = $pad->elems;
   my @padnames = map {
      my $padname = $padcv->padname( $_ );
      # is_outer is always set for is_our; it's only interesting without is_our
      my $is_just_outer = $padname && $padname->is_outer && !$padname->is_our;

      $padname ? _join( " ",
         ( $padname->is_state ? Devel::MAT::Cmd->format_note( "state" ) : () ),
         ( $padname->is_our   ? Devel::MAT::Cmd->format_note( "our" )   : () ),
         ( $padname->is_field ? Devel::MAT::Cmd->format_note( "field" ) : () ),
         Devel::MAT::Cmd->format_note( $padname->name, 1 ),
         ( $is_just_outer     ? Devel::MAT::Cmd->format_note( "*OUTER", 2 ) : () ),
         # is_typed and is_lvalue not indicated
      ) : undef
   } 0 .. $#elems;
   my $idxlen  = length $#elems;
   my $namelen = max map { defined $_ ? length $_ : 0 } @padnames;

   my %padtype;
   if( my $gvix = $padcv->{gvix} ) {
      $padtype{$_} = "GLOB" for @$gvix;
   }
   if( my $constix = $padcv->{constix} ) {
      $padtype{$_} = "CONST" for @$constix;
   }

   Devel::MAT::Cmd->printf( "  [%*d/%-*s]=%s\n",
      $idxlen, 0,
      $namelen, Devel::MAT::Cmd->format_note( '@_', 1 ),
      ( $elems[0] ? Devel::MAT::Cmd->format_sv_with_value( $elems[0] ) : "NULL" ),
   );

   foreach my $padix ( 1 .. $#elems ) {
      my $sv = $elems[$padix];
      if( $padnames[$padix] ) {
         Devel::MAT::Cmd->printf( "  [%*d/%-*s]=%s\n",
            $idxlen, $padix,
            $namelen, $padnames[$padix],
            ( $sv ? Devel::MAT::Cmd->format_sv_with_value( $sv ) : "NULL" ),
         );
      }
      else {
         Devel::MAT::Cmd->printf( "  [%*d %-*s]=%s\n",
            $idxlen, $padix,
            $namelen, $padtype{$padix} // "",
            ( $sv ? Devel::MAT::Cmd->format_sv_with_value( $sv ) : "NULL" ),
         );
      }
   }
}

# TODO: PADLIST

sub show_PADNAMES
{
   my $self = shift;
   my ( $padnames ) = @_;

   $padnames->padcv ? say_with_sv( "  padcv=", $padnames->padcv )
                    : Devel::MAT::Cmd->printf( "  no padcv\n" );

   my @elems = $padnames->elems;
   # Every PADNAMES element is either NULL or a SCALAR(PV)
   # PADIX 0 is always @_
   foreach my $padix ( 1 .. $#elems ) {
      my $slot = $elems[$padix];
      if( $slot and $slot->type eq "SCALAR" ) {
         Devel::MAT::Cmd->printf( "  [%d] is %s\n", $padix, Devel::MAT::Cmd->format_note( $slot->pv, 1 ) );
      }
   }
}

sub show_IO
{
   my $self = shift;
   my ( $io ) = @_;

   Devel::MAT::Cmd->printf( "  ifileno=%d\n", $io->ifileno ) if defined $io->ifileno;
   Devel::MAT::Cmd->printf( "  ofileno=%d\n", $io->ofileno ) if defined $io->ofileno;
}

sub show_OBJECT
{
   my $self = shift;
   my ( $obj ) = @_;

   my @fields = $obj->fields;

   foreach my $field ( $obj->blessed->fields ) {
      my $val = $obj->field( $field->fieldix );

      Devel::MAT::Cmd->printf( "  %s=%s\n",
         Devel::MAT::Cmd->format_note( $field->name, 1 ),
         Devel::MAT::Cmd->format_sv_with_value( $val )
      );
   }
}

sub show_CLASS
{
   my $self = shift;
   my ( $cls ) = @_;

   Devel::MAT::Cmd->printf( "  is CLASS\n" );

   $cls->adjust_blocks ? say_with_sv( "  adjust_blocks=", $cls->adjust_blocks )
                       : ();

   $self->show_STASH( $cls );
}

sub show_C_STRUCT
{
   my $self = shift;
   my ( $struct ) = @_;

   my @fields = $struct->fields;

   while( @fields ) {
      my $field = shift @fields;
      my $val   = shift @fields;

      next unless defined $val;

      if( $field->type == 0x00 ) { # PTR
         Devel::MAT::Cmd->printf( "  %s=%s\n",
            $field->name,
            Devel::MAT::Cmd->format_sv_with_value( $val )
         );
      }
      elsif( $field->type == 0x01 ) { # BOOL
         Devel::MAT::Cmd->printf( "  %s=%s\n",
            $field->name,
            Devel::MAT::Cmd->format_value( $val ? "true" : "false" )
         );
      }
      else { # various number types
         Devel::MAT::Cmd->printf( "  %s=%s\n",
            $field->name,
            Devel::MAT::Cmd->format_value( $val ),
         );
      }
   }
}

package # hide
   Devel::MAT::Tool::Show::_elems;
use base qw( Devel::MAT::Tool );

use List::Util qw( min );

use constant CMD => "elems";
use constant CMD_DESC => "List the elements of an ARRAY SV";

=head2 elems

   pmat> elems endav
     [0] CODE(PP) at 0x562e93222dc8

Prints elements of an ARRAY SV.

Takes the following named options:

=over 4

=item --count, -c MAX

Show at most this number of elements (default 50).

=item --start, -s COUNT

Start at the given index.

=back

=cut

use constant CMD_OPTS => (
   count => { help => "maximum count of elements to print",
              type => "i",
              alias => "c",
              default => 50 },
   start => { help => "starting index",
              type => "i",
              alias => "s" },
);

use constant CMD_ARGS_SV => 1;
use constant CMD_ARGS => (
);

sub run
{
   my $self = shift;
   my %opts = %{ +shift };
   my ( $av ) = @_;

   my $type = $av->type;
   if( $type eq "HASH" or $type eq "STASH" ) {
      die "Cannot 'elems' of a $type - maybe you wanted 'values'?\n";
   }
   elsif( $type ne "ARRAY" ) {
      die "Cannot 'elems' of a non-ARRAY\n";
   }

   my $startidx = $opts{start} // 0;
   my $stopidx = min( $startidx + $opts{count}, $av->n_elems );

   my @rows;
   foreach my $idx ( $startidx .. $stopidx-1 ) {
      my $sv = $av->elem( $idx );
      push @rows, [
         Devel::MAT::Cmd->format_value( $idx, index => 1 ),
         $sv ? Devel::MAT::Cmd->format_sv_with_value( $sv ) : "NULL",
      ];
   }

   Devel::MAT::Cmd->print_table( \@rows, indent => 2 );

   my $morecount = $av->n_elems - $stopidx;
   Devel::MAT::Cmd->printf( "  ... (%d more)\n", $morecount ) if $morecount;
}

package # hide
   Devel::MAT::Tool::Show::_values;
use base qw( Devel::MAT::Tool );

use constant CMD => "values";
use constant CMD_DESC => "List the values of a HASH-like SV";

=head2 values

   pmat> values defstash
     {"\b"}                GLOB($%*) at 0x562e93114eb8
     {"\017"}              GLOB($*) at 0x562e9315a428
     ...

Prints values of a HASH or STASH SV.

Takes the following named options:

=over 4

=item --count, -c MAX

Show at most this number of values (default 50).

=item --skip, -s COUNT

Skip over this number of keys initially before starting to print.

=item --no-sort, -n

Don't bother to sort keys before printing. Keys will be printed in no
particular order (though the order will at least be stable between successive
invocations of the command during the same session).

=back

Takes the following positional arguments:

=over 4

=item *

Optional filter pattern. If present, will only count and display keys matching
the given regexp. Must be specified in the form C</PATTERN/> with optional
trailing flags. The only permitted flags are C<adilmsux>.

=back

=cut

use constant CMD_OPTS => (
   count => { help => "maximum count of values to print",
              type => "i",
              alias => "c",
              default => 50 },
   skip => { help => "count of keys to skip initially before printing",
             type => "i",
             alias => "s" },
   no_sort => { help => "don't sort keys before printing",
                alias => "n" },
   hek => { help => "also show HEK pointers",
            alias => "H" },
);

use constant CMD_ARGS_SV => 1;
use constant CMD_ARGS => (
   { name => "filter", help => "optional pattern to filter keys by" },
);

sub run
{
   my $self = shift;
   my %opts = %{ +shift };
   my ( $hv, $filter ) = @_;

   my $type = $hv->type;
   if( $type eq "ARRAY" ) {
      die "Cannot 'values' of a $type - maybe you wanted 'elems'?\n";
   }
   elsif( $type ne "HASH" and $type ne "STASH" ) {
      die "Cannot 'elems' of a non-HASHlike\n";
   }

   my $skipcount = $opts{skip};
   my $show_heks = $opts{hek};

   my @keys = $hv->keys;
   if( length $filter ) {
      $filter =~ m/^\/(.*)\/([adilmsux]*)$/ or
         die "Filter must be a /PATTERN.../ with optional flags";
      my ( $pattern, $flags ) = ( $1, $2 );
      my $re = qr/(?$flags:$pattern)/;
      @keys = grep { $_ =~ $re } @keys;
   }
   @keys = sort @keys unless $opts{no_sort};
   splice @keys, 0, $skipcount if $skipcount;

   Devel::MAT::Tool::more->paginate( { pagesize => $opts{count} }, sub {
      my ( $count ) = @_;
      my @rows;
      foreach my $key ( splice @keys, 0, $count ) {
         my $sv = $hv->value( $key );
         my $hek = $show_heks ? $hv->hek_at( $key ) : 0;

         push @rows, [
            Devel::MAT::Cmd->format_value( $key, key => 1,
               stash => ( $type eq "STASH" ) ),
            ( $hek ? "HEK at " . Devel::MAT::Cmd->format_value( $hek, addr => 1 ) : () ),
            $sv ? Devel::MAT::Cmd->format_sv_with_value( $sv ) : "NULL",
         ];
      }

      Devel::MAT::Cmd->print_table( \@rows, indent => 2 );

      my $morecount = @keys;
      Devel::MAT::Cmd->printf( "  ... (%d more)\n", $morecount ) if $morecount;
      return $morecount;
   } );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
