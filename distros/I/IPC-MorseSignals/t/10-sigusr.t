#!perl -T

use strict;
use warnings;

use Test::More tests => 4;

use POSIX qw/SIGUSR1 SIGUSR2/;

my ($a, $b) = (0, 0);

local $SIG{'USR1'} = sub { ++$a };
local $SIG{'USR2'} = sub { ++$b };

kill SIGUSR1 => $$;
is($a, 1, 'SIGUSR1 triggers $SIG{USR1}');
is($b, 0, 'SIGUSR1 doesn\'t trigger $SIG{USR2}');

kill SIGUSR2 => $$;
is($a, 1, 'SIGUSR2 doesn\'t trigger $SIG{USR1}');
is($b, 1, 'SIGUSR2 triggers $SIG{USR2}');
