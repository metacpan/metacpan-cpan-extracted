use strict;
use warnings;

use Test::More tests => 6;
use POSIX qw(uname);
use Linux::Prctl qw(:constants :functions);

my $arch = uname;

SKIP: {
    skip "get_endian/set_endian are powerpc specific", 6 unless $arch eq 'powerpc';
    for(ENDIAN_BIG, ENDIAN_LITTLE, ENDIAN_PPC_LITTLE) {
        is(set_endian($_), 0, "Setting endianness to $_");
        is(get_endian, $_, "Checking whether endianness is $_")
    }
}
