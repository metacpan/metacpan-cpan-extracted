#!perl
use v5.12;
use warnings;
use GStreamer1;
use Devel::Symdump;

# Dump out everything under the GStreamer1:: namespace recursively

my $dump = Devel::Symdump->rnew( 'GStreamer1' );
say $_ for sort $dump->functions;
