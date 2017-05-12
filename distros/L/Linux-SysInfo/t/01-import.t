#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 2;

require Linux::SysInfo;

my %syms = (
 sysinfo         => '',
 LS_HAS_EXTENDED => '',
);

for (keys %syms) {
 eval { Linux::SysInfo->import($_) };
 is $@,            '',        "import $_";
 is prototype($_), $syms{$_}, "prototype $_";
}
