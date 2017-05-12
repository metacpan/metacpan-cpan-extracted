# *-*-perl-*-*
use Test;
use strict;
$^W = 1;
use IP::Country::Fast;

# uncomment the next line for accurate timings
# use Time::HiRes qw ( time );

BEGIN { plan tests => 1 }

# set to something bigger on a fast machine
my $iter = (2 ** 15) - 1;

# first, populate our array of random IP addresses
my @ip;
for (my $i=0; $i<$iter; $i++)
{
    $ip[$i] = int(rand(256)).'.'.int(rand(256)).'.'
	.int(rand(256)).'.'.int(rand(256));
}

# second, time how long the lookups take
my $reg = IP::Country::Fast->new();
my $t1 = time();
for (my $i=0; $i<$iter; $i++)
{
    $reg->inet_atocc($ip[$i]);
}
my $delta = (time() - $t1) || 1; # avoid zero division

# finally, check the coverage
my $found = 0;
for (my $i=0; $i<$iter; $i++)
{
    $found++ if ($reg->inet_atocc($ip[$i]));
}

ok(1);
print STDERR (" # random find (".int(($found * 100)/$iter)."%, "
	      .int($iter/$delta)." lookups/sec)\n");
# sleep(10);
