#!perl
###########################################################################
#
#   format.t
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

use Test;
use Log::Agent;

BEGIN { plan tests => 7 }

open(FOO, "t/frank");
my $errstr = $!;
eval { logdie "error: %m" };
ok($@ =~ /Error: $errstr/i);
close FOO;

eval { logdie "100%% pure, %s lard", "snowy" };
ok($@ =~ /100\% pure, snowy lard/);

eval { logdie "5%% Nation of Lumps in My Oatmeal" };
ok($@ =~ /5% Nation of Lumps in My Oatmeal/);

eval { logdie "10%% inspiration, 90%% frustration" };
ok($@ =~ /10% inspiration, 90% frustration/);

eval { logdie "%-10s, %10s", 'near', 'far' };
ok($@ =~ /Near      ,        far/);

eval { logdie "because %d is the magic number", 0x03 };
ok($@ =~ /Because 3 is the magic number/);

eval { logdie 'night of the living %*2$x', 233495723, 4 };
skip($] < 5.008 ? "pre 5.8.0" : 0, $@ =~ /Night of the living dead/);
