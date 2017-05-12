#!perl
use strict ;

use Data::Dumper ;

use Test::More tests => 1;

## Check module loads ok
use Linux::DVB::DVBT::Advert ;
use Linux::DVB::DVBT::Advert::Constants ;


my %expected = (
          'Advert' => {
                        'detection_method' => {
                                                'AUDIO' => 4,
                                                'LOGO' => 2,
                                                'BANNER' => 8,
                                                'BLACK' => 1
                                              },
                        'detection_method_special' => {
                                                        'MIN' => 1,
                                                        'DEFAULT' => 7
                                                      }
                      },
          'FRAMES_PER_SEC' => 25,
) ;         
          
print Data::Dumper->Dump(['CONSTANTS', \%Linux::DVB::DVBT::Advert::Constants::CONSTANTS]) ;

is_deeply(\%Linux::DVB::DVBT::Advert::Constants::CONSTANTS, \%expected) ;



