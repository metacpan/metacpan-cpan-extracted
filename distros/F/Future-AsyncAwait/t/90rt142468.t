#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Future;
use Future::AsyncAwait;

# Check that folded constants stored on the pad with the SvPADTMP flag set are
# still copied successfully by cv_copy_flags().
#
#   https://rt.cpan.org/Ticket/Display.html?id=142468

use constant {
   REG_LUXH => 0x03,
   REG_LUXL => 0x04,
};

my @written;

my $ftick;
sub write_then_read
{
   my ( $bytes, $len ) = @_;

   push @written, [ $bytes, $len ];

   return $ftick = Future->new;
}

async sub read_lux
{
   return unpack "S>", join "",
      await write_then_read( ( pack "C", REG_LUXH ), 1 ),
      await write_then_read( ( pack "C", REG_LUXL ), 1 );
}

{
   my $fret = read_lux;

   do { my $f = $ftick; undef $ftick; $f->done } while $ftick;

   is( \@written, [ [ "\x03", 1 ], [ "\x04", 1 ], ],
      'arguments to ->write_then_read' );
}

done_testing;
