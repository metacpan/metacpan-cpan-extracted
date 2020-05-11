#
# $Id$
#
# binjitsu::pattern Brik
#
package Metabrik::Binjitsu::Pattern;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'ZadYree <zadyree[at]gmail.com>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         output => [ qw(file) ],
         max_size => [ qw(size) ],
      },
      attributes_default => {
         max_size => 65535,
      },
      commands => {
         create => [ qw(size file|OPTIONAL) ],
         offset => [ qw(point) ],
      },
      require_modules => {
         'Metabrik::String::Hexa' => [ ],
         'Path::Tiny' => [ ],
      },
   };
}

sub create {
   my $self = shift;
   my $count = int(shift) || 16;

   my ($flw);
   if ( $self->output ) {
      $flw = Path::Tiny->new( $self->datadir )->child( $self->output );
   }

   $self->log->error("create: Too large pattern :("), die
      unless $count < $self->max_size;
   my $set = {
      ALPHA_LOWER => [ "a" .. "z" ],
      ALPHA_UPPER => [ "A" .. "Z" ],
      NUMS => [ 0 .. 9 ],
   };

   my $patt = "";
   for my $chr0 ( @{ $set->{ALPHA_UPPER} } ) {
      last unless ( length($patt) < $count );
      for my $chr1 ( @{ $set->{ALPHA_UPPER} } ) {
         for my $chr2 ( @{ $set->{NUMS} } ) {
            for my $chr3 ( @{ $set->{ALPHA_LOWER} } ) {
               $patt .= $chr0 . $chr1 . $chr2 . $chr3;
            }
         }
      }
   }

   $patt = substr( $patt, 0, $count );
   if ($flw) {
      $self->log->info( "create: Writing pattern to " . $flw->stringify );
      $flw->spew($patt);
      return 1;
   }

   return \$patt;
}

sub offset {
   my $self = shift;
   my $point = shift;

   $self->brik_help_run_undef_arg( 'offset', $point ) or return;

   $self->log->verbose(
      "offset: Finding offset for $point. /!\\ This is experimental (really!) /!\\");

   $point =~ s/0x//;

   my ($idx);
   my ($chrs);
   if ( length($point) == 8 ) {
      $chrs = [ split( /(..)/, substr( $point, 0, 8 ) ) ];
      $chrs = pack( 'V', hex( join( '', @$chrs ) ) );

      $idx = index( ${ $self->create( $self->max_size - 1 ) }, $chrs );
   }
   elsif ( length($point) == 16 ) {
      $chrs = [ split( /(..)/, substr( $point, 0, 16 ) ) ];
      $chrs = pack( 'L!', hex( join( '', @$chrs ) ) );

      $idx = index( ${ $self->create( $self->max_size - 1 ) }, $chrs );
   }
   else { $self->log->error("offset: Bad address size."); return; }

   if ( $idx != -1 ) {
      return {
         pattern => $chrs,
         position => $idx,
      };
   }
   else {
      $self->log->error("offset: Couldn't find typed offset pattern [ $point ]");
      return;
   }
}

1;

__END__

=head1 NAME

Metabrik::Binjitsu::Pattern - binjitsu::pattern Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, ZadYree

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

ZadYree

=cut
