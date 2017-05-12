#!/usr/bin/perl

#file: useApartament.plx

use warnings;
use strict;
use lib "/home/mhcrnl/MyPerlCode/Indexuri-Apartament/lib/";
use Indexuri::Apartament;

my $septembrie2015 = new Indexuri::Apartament(234, 345, 400, 500, 999, 6261, 6262, 6263);

print $septembrie2015->getIApaBucRece()."\n";
print $septembrie2015->getIApaBucCalda()."\n";
print $septembrie2015->getIApaBaiRece()."\n";
print $septembrie2015->getIApaBaiCalda()."\n";
print $septembrie2015->getIGaze()."\n";
print $septembrie2015->getICal6261()."\n";
print $septembrie2015->getICal6262()."\n";
print $septembrie2015->getICal6263()."\n";

$septembrie2015->setIApaBucRece(432);
print $septembrie2015->getIApaBucRece()."\n";

$septembrie2015->setIApaBucCalda(900);
print $septembrie2015->getIApaBucCalda()."\n";

$septembrie2015->setIApaBaiRece(200);
print $septembrie2015->getIApaBaiRece()."\n";

$septembrie2015->setIApaBaiCalda(555);
print $septembrie2015->getIApaBaiCalda()."\n";

$septembrie2015->setIGaze(1111);
print $septembrie2015->getIGaze()."\n";

$septembrie2015->setICal6261(11111111);
print $septembrie2015->getICal6261()."\n";

$septembrie2015->setICal6262(11111111222);
print $septembrie2015->getICal6262()."\n";

$septembrie2015->setICal6263(111111112223333);
print $septembrie2015->getICal6263()."\n";