#!perl
#
# 'Borrowed' from DMAKI's File-MMagic-XS

use strict;
use warnings;

use Test::More;

use Encoding::FixLatin qw(fix_latin);
use Encoding::FixLatin::XS;

BEGIN {
    if (! $ENV{TEST_MEMLEAK}) {
        plan skip_all => "TEST_MEMLEAK is not set";
    }
}
use Test::Requires
    'Test::Valgrind',
    'XML::Parser',
;


while ( my $f = <t/*.t> ) {
    subtest $f => sub { do $f };
}

while ( my $f = <t/*.t> ) {
    for my $i (1..10) {
        subtest $f => sub { do $f };
    }
}

done_testing;

