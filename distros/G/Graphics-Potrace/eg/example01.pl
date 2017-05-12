#!/opt/perl/bin/perl 
use strict;
use warnings;
use English qw( -no_match_vars );
use Data::Dumper;
$Data::Dumper::Indent = 1;

use lib qw( lib blib/lib blib/arch );
use Graphics::Potrace         ();
use Graphics::Potrace::Raster ();

my ($width, $height) = (0, 0);
my @vectors = map {
   my $bitmap = Graphics::Potrace::Raster->new();
   $bitmap->dwim_load($_);
   $width = $bitmap->width() if $width < $bitmap->width();
   $height = $bitmap->height() if $height < $bitmap->height();
   $bitmap->trace();
} @ARGV;

my $saver = Graphics::Potrace::Vectorial->create_exporter(
   'Svg',
   fh     => \*STDOUT,
   height => $height,
   width  => $width,
);
$saver->save(@vectors);
