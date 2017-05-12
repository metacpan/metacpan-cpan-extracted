use strict;
use warnings FATAL => "all";
use Test::More;
use List::Util qw(sum);

plan skip_all => "This only works on Linux" unless $^O eq "linux";
plan 'no_plan';

use_ok 'Linux::Smaps::Tiny';

my @fields = qw(
    KernelPageSize
    MMUPageSize
    Private_Clean
    Private_Dirty
    Pss
    Referenced
    Rss
    Shared_Clean
    Shared_Dirty
    Size
    Swap
);

for my $arg ([], [$$]) {
    my $smaps = Linux::Smaps::Tiny::get_smaps_summary(@$arg);
    cmp_ok(ref($smaps), "eq", "HASH", "We got a hash back");


    for my $thing (@fields) {
        ok(exists $smaps->{$thing}, "The $thing entry exists");
    }

    cmp_ok(sum(values %$smaps), ">", 0, "We got some memory reported");
}

eval {
    Linux::Smaps::Tiny::get_smaps_summary("HELLO THERE");
    1;
};
my $err = $@;
like($err, qr[failed to read '/proc/HELLO THERE/smaps'], "Sensible error messages");
