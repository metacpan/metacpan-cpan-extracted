#!/usr/bin/perl

use strict;
use lib "./t"; use MakeMakerFix;
WriteMakefile('ModeString.pm', 'VERSION_FROM' => 'VERSION', 'NO_META' => 1,
	      'PREREQ_PM' => {'File::Stat::Bits' => 0},
	     );

