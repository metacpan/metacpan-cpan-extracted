#!/usr/bin/perl

use strict;
use FindBin;
use Time::HiRes qw[ usleep ];
use lib "$FindBin::Bin/../lib";

use Device::Arduino::LCD;

my $lcd = Device::Arduino::LCD->new;
$lcd->clear;

my $ret = $lcd->convert_to_char(0,
				[ qw[ . . x x . ] ],
				[ qw[ . x x . . ] ],
				[ qw[ x x . . x ] ],
				[ qw[ x . . x x ] ],
				[ qw[ . . x x . ] ],
				[ qw[ . x x . . ] ],
				[ qw[ x x . . x ] ],
				[ qw[ x . . x x ] ]);

my $ret = $lcd->convert_to_char(1,
				[ qw[ . x x . . ] ],
				[ qw[ x x . . x ] ],
				[ qw[ x . . x x ] ],
				[ qw[ . . x x . ] ],
				[ qw[ . x x . . ] ],
				[ qw[ x x . . x ] ],
				[ qw[ x . . x x ] ],
				[ qw[ . . x x . ] ]);

my $ret = $lcd->convert_to_char(2,
				[ qw[ x x . . x ] ],
				[ qw[ x . . x x ] ],
				[ qw[ . . x x . ] ],
				[ qw[ . x x . . ] ],
				[ qw[ x x . . x ] ],
				[ qw[ x . . x x ] ],
				[ qw[ . . x x . ] ],
				[ qw[ . x x . . ] ]);

my $ret = $lcd->convert_to_char(3,
				[ qw[ x . . x x ] ],
				[ qw[ . . x x . ] ],
				[ qw[ . x x . . ] ],
				[ qw[ x x . . x ] ],
				[ qw[ x . . x x ] ],
				[ qw[ . . x x . ] ],
				[ qw[ . x x . . ] ],
				[ qw[ x x . . x ] ]);


while (1) {
  for (0 .. 3) {
    $lcd->write_ascii($_, 1, 8);
    $lcd->write_ascii($_, 2, 8);
    usleep 500_000;
  }
}
