#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016-2017 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Show;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );

our $VERSION = '0.30';

use List::Util qw( max );

use constant CMD => "show";
use constant CMD_DESC => "Show information about a given SV";

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

sub run
{
   my $self = shift;
   my ( $sv ) = @_;

   Devel::MAT::Cmd->printf( "%s with refcount %d\n",
      Devel::MAT::Cmd->format_sv( $sv ),
      $sv->refcnt,
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

   my $type = ref $sv; $type =~ s/^Devel::MAT::SV:://;
   my $method = "show_$type";
   $self->$method( $sv );
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
   my ( $sv ) = @_;

   Devel::MAT::Cmd->printf( "  UV=%d\n", $sv->uv ) if defined $sv->uv;
   Devel::MAT::Cmd->printf( "  IV=%d\n", $sv->iv ) if defined $sv->iv;
   Devel::MAT::Cmd->printf( "  NV=%f\n", $sv->nv ) if defined $sv->nv;

   if( defined( my $pv = $sv->pv ) ) {
      Devel::MAT::Cmd->printf( "  PV=%s\n", $pv ) if length $pv < 40 and $pv !~ m/[\0-\x1f\x80-\x9f]/;
      Devel::MAT::Cmd->printf( "  PVLEN %d\n", $sv->pvlen );
   }
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
   my ( $cv ) = @_;

   $cv->name     ? Devel::MAT::Cmd->printf( "  name=%s\n", $cv->name )
                 : Devel::MAT::Cmd->printf( "  no name\n" );

   $cv->stash    ? say_with_sv( "  stash=", $cv->stash )
                 : Devel::MAT::Cmd->printf( "  no stash\n" );

   $cv->glob     ? say_with_sv( "  glob=", $cv->glob )
                 : Devel::MAT::Cmd->printf( "  no glob\n" );

   $cv->location ? Devel::MAT::Cmd->printf( "  location=%s\n", $cv->location )
                 : Devel::MAT::Cmd->printf( "  no location\n" );

   $cv->scope    ? say_with_sv( "  scope=", $cv->scope )
                 : Devel::MAT::Cmd->printf( "  no scope\n" );

   $cv->padlist  ? say_with_sv( "  padlist=", $cv->padlist )
                 : Devel::MAT::Cmd->printf( "  no padlist\n" );

   $cv->padnames ? say_with_sv( "  padnames=", $cv->padnames )
                 : Devel::MAT::Cmd->printf( "  no padnames\n" );

   my @pads = $cv->pads;
   foreach my $depth ( 0 .. $#pads ) {
      next unless $pads[$depth];
      say_with_sv( "  pad[$depth]=", $pads[$depth] );
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

   my @elems = $pad->elems;
   my @padnames = map {
      my $padname = $padcv->padname( $_ );
      $padname ? $padname->name : undef
   } 0 .. $#elems;
   my $maxname = max map { defined $_ ? length $_ : 0 } @padnames;

   my %padtype;
   if( my $gvix = $padcv->{gvix} ) {
      $padtype{$_} = "GLOB" for @$gvix;
   }
   if( my $constix = $padcv->{constix} ) {
      $padtype{$_} = "CONST" for @$constix;
   }

   foreach my $padix ( 1 .. $#elems ) {
      my $sv = $elems[$padix];
      if( $padnames[$padix] ) {
         Devel::MAT::Cmd->printf( "  [%3d/%*s]=%s\n",
            $padix,
            $maxname, $padnames[$padix],
            ( $sv ? Devel::MAT::Cmd->format_sv( $sv ) : "NULL" ),
         );
      }
      else {
         Devel::MAT::Cmd->printf( "  [%3d %*s]=%s\n",
            $padix,
            $maxname, $padtype{$padix} // "",
            ( $sv ? Devel::MAT::Cmd->format_sv( $sv ) : "NULL" ),
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
         Devel::MAT::Cmd->printf( "  [%d] is %s\n", $padix, $slot->pv );
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

=back

Takes the following positional arguments:

=over 4

=item *

Optional start index (default 0).

=back

=cut

use constant CMD_OPTS => (
   count => { help => "maximum count of elements to print",
              type => "i",
              alias => "c",
              default => 50 },
);

use constant CMD_ARGS_SV => 1;
use constant CMD_ARGS => (
   { name => "startidx", help => "starting index" },
);

sub run
{
   my $self = shift;
   my %opts = %{ +shift };
   my ( $av, $startidx ) = @_;

   my $type = $av->type;
   if( $type eq "HASH" or $type eq "STASH" ) {
      die "Cannot 'elems' of a $type - maybe you wanted 'values'?\n";
   }
   elsif( $type ne "ARRAY" ) {
      die "Cannot 'elems' of a non-ARRAY\n";
   }

   $startidx //= 0;
   my $stopidx = min( $startidx + $opts{count}, $av->n_elems );

   my @rows;
   foreach my $idx ( $startidx .. $stopidx-1 ) {
      my $sv = $av->elem( $idx );
      push @rows, [
         "  " . Devel::MAT::Cmd->format_value( $idx, index => 1 ),
         $sv ? Devel::MAT::Cmd->format_sv( $sv ) : "NULL",
      ];
   }

   Devel::MAT::Cmd->print_table( \@rows );

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

=back

Takes the following positional arguments:

=over 4

=item *

Optional skip count (default 0). If present, will skip over this number of
keys initially to show more of them.

=back

=cut

use constant CMD_OPTS => (
   count => { help => "maximum count of values to print",
              type => "i",
              alias => "c",
              default => 50 },
);

use constant CMD_ARGS_SV => 1;
use constant CMD_ARGS => (
   { name => "skipcount", help => "skip over this many keys initially" },
);

sub run
{
   my $self = shift;
   my %opts = %{ +shift };
   my ( $hv, $skipcount ) = @_;

   my $type = $hv->type;
   if( $type eq "ARRAY" ) {
      die "Cannot 'values' of a $type - maybe you wanted 'elems'?\n";
   }
   elsif( $type ne "HASH" and $type ne "STASH" ) {
      die "Cannot 'elems' of a non-HASHlike\n";
   }

   # TODO: control of sorting, start at, filtering
   my @keys = sort $hv->keys;
   splice @keys, 0, $skipcount if $skipcount;

   my @rows;
   my $count = 0;
   foreach my $key ( @keys ) {
      last if $count == $opts{count};
      my $sv = $hv->value( $key );
      push @rows, [
         "  " . Devel::MAT::Cmd->format_value( $key, key => 1,
               stash => ( $type eq "STASH" ) ),
         $sv ? Devel::MAT::Cmd->format_sv( $sv ) : "NULL",
      ];
      $count++;
   }

   Devel::MAT::Cmd->print_table( \@rows );

   my $morecount = @keys - $count;
   Devel::MAT::Cmd->printf( "  ... (%d more)\n", $morecount ) if $morecount;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
