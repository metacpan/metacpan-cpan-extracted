use lib "./t";
use ExtUtils::TBone;
use strict;

use Geo::GNUPlot;

#Create checker
my $T=ExtUtils::TBone->typical();
$T->begin(1);

$T->msg('hi there jimmy');
$T->ok('hi there john');

#End testing
$T->end();
