use v5.10;
use strict;
use warnings;
use Carp;
use Encode qw(decode encode);
use Geo::GDAL::FFI;
use Test::More;
use Data::Dumper;
use JSON;
use FFI::Platypus::Buffer;

my $gdal = Geo::GDAL::FFI->new();
my $band = $gdal->GetDriver('MEM')->Create('', {Width => 7, Height => 15})->GetBand;

my $t = $band->Read;
$t->[5][3] = 1;
$band->Write($t);
$t->[5][3] = 0;

my $pdl = $band->GetPiddle;
my @s = $pdl->dims;
ok($s[0] == 7 && $s[1] == 15, "Piddle size is right (1).");
ok($pdl->at(3,5) == 1, "Piddle data is ok (1).");

$pdl = $band->GetPiddle(1,2,4,4);
@s = $pdl->dims;
ok($s[0] == 4 && $s[1] == 4, "Piddle size is right (2).");
ok($pdl->at(2,3) == 1, "Piddle data is ok (2).");

$pdl += 1;

$band->Write($t); # zero raster
$band->SetPiddle($pdl);
ok($band->Read->[3][2] == 2, "Data from piddle into band at(0,0).");

$band->Write($t); # zero raster
$band->SetPiddle($pdl,1,2);
ok($band->Read->[5][3] == 2, "Data from piddle into band at(1,2).");

$band->Write($t); # zero raster
$band->SetPiddle($pdl,0,0,7,15);
ok($band->Read->[12][4] == 2, "Data from piddle into band (stretched).");

done_testing();
