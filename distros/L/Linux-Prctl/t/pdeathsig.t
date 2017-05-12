use strict;
use warnings;

use Test::More tests => 5;
use POSIX qw(SIGHUP);
use Linux::Prctl qw(:constants :functions);

is(get_pdeathsig, 0, "Checking the default pdeathsig");
is(set_pdeathsig(SIGHUP), 0, "Setting pdeathsig to SIGHUP");
is(get_pdeathsig, SIGHUP, "Checking whether pdeasthsig is SIGHUP");
is(set_pdeathsig(0), 0, "Setting pdeathsig to 0");
is(get_pdeathsig, 0, "Checking whether pdeasthsig is 0");
