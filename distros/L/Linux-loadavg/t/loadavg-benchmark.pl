#
# $Id: benchmark.pl,v 1.1 2007/07/18 23:15:10 perlboy Exp $
#
use strict;
use warnings;
use Benchmark qw/cmpthese timethese/;
use Linux::loadavg;
cmpthese(
    timethese(
        0,
        {
            command => sub {
                my @loadavg =
                  ( qx(uptime) =~ /([\.\d]+)\s+([\.\d]+)\s+([\.\d]+)/ );
                return @loadavg;
            },
            XS => sub {
		my @loadavg = loadavg();
                return @loadavg;
              }
        }
    )
);
