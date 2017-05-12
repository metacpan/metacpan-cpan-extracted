#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 1;

require Mac::NSGetExecutablePath;

my %syms = (
 'NSGetExecutablePath' => '',
);

for (sort keys %syms) {
 eval { Mac::NSGetExecutablePath->import($_) };
 is $@,            '',        "import $_";
 is prototype($_), $syms{$_}, "prototype $_";
}
