#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Show;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );

our $VERSION = '0.26';

use List::Util qw( max );

use constant CMD => "show";

=head1 NAME

C<Devel::MAT::Tool::Show> - show information about a given SV

=head1 DESCRIPTION

This C<Devel::MAT> tool provides a command that prints interesting information
from within an SV. Its exact output will depend on the type of SV it is
applied to.

=cut

# NOT perl's one
sub say
{
   Devel::MAT::Cmd->printf( "%s\n", join " ", @_ );
}

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

sub run_cmd
{
   my $self = shift;
   my ( $addr ) = @_;

   my $df = $self->{df};

   $addr = $df->defstash->addr if $addr eq "defstash";
   $addr = hex $addr if $addr =~ m/^0x/;

   my $sv = $df->sv_at( $addr );
   $sv or die sprintf "No SV at %#x\n", $addr;

   say $sv->desc_addr . " with refcount " . $sv->refcnt;
   say "  blessed as " . $sv->blessed->stashname if $sv->blessed;

   my $type = ref $sv; $type =~ s/^Devel::MAT::SV:://;
   if( $type eq "GLOB" ) {
      say '  stash=' . $sv->stash->desc_addr if $sv->stash;

      say '  SCALAR=' . $sv->scalar->desc_addr if $sv->scalar;
      say '  ARRAY='  . $sv->array->desc_addr  if $sv->array;
      say '  HASH='   . $sv->hash->desc_addr   if $sv->hash;
      say '  CODE='   . $sv->code->desc_addr   if $sv->code;
      say '  EGV='    . $sv->egv->desc_addr    if $sv->egv;
      say '  IO='     . $sv->io->desc_addr     if $sv->io;
      say '  FORM='   . $sv->form->desc_addr   if $sv->form;
   }
   elsif( $type eq "SCALAR" ) {
      say '  UV=' . $sv->uv if defined $sv->uv;
      say '  IV=' . $sv->iv if defined $sv->iv;
      say '  NV=' . $sv->nv if defined $sv->nv;
      if( defined( my $pv = $sv->pv ) ) {
         say '  PV=' . $pv if length $pv < 40 and $pv !~ m/[\0-\x1f\x80-\x9f]/;
         say '  PVLEN ' . $sv->pvlen;
      }
   }
   elsif( $type eq "REF" ) {
      say '  RV=' . $sv->rv->desc_addr if $sv->rv;
   }
   elsif( $type eq "ARRAY" ) {
      my @elems = $sv->elems;
      say "  [$_]=" . ( $elems[$_] ? $elems[$_]->desc_addr : "NULL" ) for 0 .. $#elems;
   }
   elsif( $type eq "HASH" or $type eq "STASH" ) {
      if( $type eq "STASH" ) {
         say '  stashname=' . $sv->stashname;
      }
      foreach my $key ( sort $sv->keys ) {
         my $v = $sv->value($key);
         say $v ?  "  {$key}=" . $v->desc_addr : "  {$key} undef";
      }
   }
   elsif( $type eq "CODE" ) {
      say $sv->name    ? "  name=" . $sv->name : "  no name";
      say $sv->stash   ? "  stash=" . $sv->stash->desc_addr : "  no stash";
      say $sv->glob    ? "  glob="  . $sv->glob->desc_addr  : "  no glob";
      say                "  location=" . $sv->location;
      say $sv->scope   ? "  scope=" . $sv->scope->desc_addr : "  no scope";
      say $sv->padlist ? "  padlist=" . $sv->padlist->desc_addr : "  no padlist";
      say $sv->padnames ? "  padnames=" . $sv->padnames->desc_addr : "  no padnames";

      my @pads = $sv->pads;
      foreach my $depth ( 0 .. $#pads ) {
         next unless $pads[$depth];
         say "  pad[$depth]=" . $pads[$depth]->desc_addr;
      }

      if( my @globs = $sv->globrefs ) {
         say "Referenced globs:";
         say "  " . join( ", ", map { $_->desc_addr } @globs );
      }
   }
   elsif( $type eq "PADNAMES" ) {
      say $sv->padcv ? "  padcv=" . $sv->padcv->desc_addr : "  no padcv";

      my @elems = $sv->elems;
      # Every PADNAMES element is either NULL or a SCALAR(PV)
      # PADIX 0 is always @_
      foreach my $padix ( 1 .. $#elems ) {
         my $slot = $elems[$padix];
         if( $slot and $slot->type eq "SCALAR" ) {
            say "  [$padix] is " . $slot->pv;
         }
         else {
            say "  [$padix] unused";
         }
      }
   }
   elsif( $type eq "PAD" ) {
      my $padcv = $sv->padcv;
      say $padcv ? "  padcv=" . $padcv->desc_addr : "  no padcv";

      my @elems = $sv->elems;
      my @padnames = map { $padcv->padname( $_ ) } 0 .. $#elems;
      my $maxname = max map { defined $_ ? length $_ : 0 } @padnames;

      my %padtype;
      if( my $gvix = $padcv->{gvix} ) {
         $padtype{$_} = "GLOB" for @$gvix;
      }
      if( my $constix = $padcv->{constix} ) {
         $padtype{$_} = "CONST" for @$constix;
      }

      foreach my $padix ( 1 .. $#elems ) {
         my $padsv = $elems[$padix];
         if( $padnames[$padix] ) {
            printf "  [%3d/%*s]=%s\n", $padix, $maxname, $padnames[$padix],
               $padsv ? $padsv->desc_addr : "NULL";
         }
         else {
            printf "  [%3d %*s]=%s\n", $padix, $maxname,
               $padtype{$padix} // "",
               $padsv ? $padsv->desc_addr : "NULL";
         }
      }
   }
   elsif( $type eq "IO" ) {
      say "  ifileno=" . $sv->ifileno if $sv->ifileno != -1;
      say "  ofileno=" . $sv->ofileno if $sv->ofileno != -1;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
