#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Show;

use strict;
use warnings;
use base qw( Devel::MAT::Tool );

our $VERSION = '0.27';

use List::Util qw( max );

use constant CMD => "show";

use Getopt::Long qw( GetOptionsFromArray );

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

Takes the following named options:

=over 4

=item --count, -c MAX

Show at most this number of elements of ARRAYs or HASHes (default 50).

=back

=cut

sub run_cmd
{
   my $self = shift;

   my $MAXCOUNT = 50;

   GetOptionsFromArray( \@_,
      'count|c=i' => \$MAXCOUNT,
   ) or return;

   my ( $addr ) = @_;
   my $sv = $self->get_sv( $addr );

   Devel::MAT::Cmd->print_sv( $sv );

   Devel::MAT::Cmd->printf( " with refcount %d\n", $sv->refcnt );

   if( my $stash = $sv->blessed ) {
      Devel::MAT::Cmd->printf( "  blessed as %s\n", $stash->stashname );
   }

   my $type = ref $sv; $type =~ s/^Devel::MAT::SV:://;
   my $method = "show_$type";
   $self->$method( $sv, maxcount => $MAXCOUNT );
}

sub say_with_sv
{
   my ( $str, $sv ) = @_;

   Devel::MAT::Cmd->printf( "%s", $str );
   Devel::MAT::Cmd->print_sv( $sv );
   Devel::MAT::Cmd->printf( "\n" );
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
   my ( $av, %opts ) = @_;

   my @elems = $av->elems;
   foreach my $idx ( 0 .. $#elems ) {
      if( defined $opts{maxcount} and $idx > $opts{maxcount} ) {
         Devel::MAT::Cmd->printf( "  ...\n" );
         last;
      }

      if( $elems[$idx] ) {
         say_with_sv( "  [$idx]=", $elems[$idx] );
      }
      else {
         Devel::MAT::Cmd->printf( "  [%d]=NULL\n", $idx );
      }
   }
}

sub show_STASH
{
   my $self = shift;
   my ( $hv, %opts ) = @_;

   Devel::MAT::Cmd->printf( "  stashname=%s\n", $hv->stashname );
   $self->show_HASH( $hv, %opts, maxcount => undef );
}

sub show_HASH
{
   my $self = shift;
   my ( $hv, %opts ) = @_;

   my $count = 0;
   foreach my $key ( sort $hv->keys ) {
      if( defined $opts{maxcount} and $count > $opts{maxcount} ) {
         Devel::MAT::Cmd->printf( "  ...\n" );
         last;
      }

      my $strkey = $key;
      if( $strkey !~ m/^[a-zA-Z_][a-zA-Z0-9_]*$/ ) {
         $strkey =~ s(([\\"\$\@]))(\\$1)g;
         $strkey =~ s{([\x00-\x1f])}{sprintf "\\x%02x", ord $1}eg;
         $strkey = qq("$strkey");
      }

      my $sv = $hv->value( $key );
      if( $sv ) {
         say_with_sv( "  {$strkey}=", $sv );
      }
      else {
         Devel::MAT::Cmd->printf( "  {%s}=NULL\n", $strkey );
      }

      $count++;
   }
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
      Devel::MAT::Cmd->print_sv( $_ ), Devel::MAT::Cmd->printf( ", " ) for @globs;
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
         Devel::MAT::Cmd->printf( "  [%3d/%*s]=", $padix, $maxname, $padnames[$padix] );
         $sv ? Devel::MAT::Cmd->print_sv( $sv ) : Devel::MAT::Cmd->printf( "NULL" );
         Devel::MAT::Cmd->printf( "\n" );
      }
      else {
         Devel::MAT::Cmd->printf( "  [%3d %*s]=", $padix, $maxname, $padtype{$padix} // "" );
         $sv ? Devel::MAT::Cmd->print_sv( $sv ) : Devel::MAT::Cmd->printf( "NULL" );
         Devel::MAT::Cmd->printf( "\n" );
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

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
