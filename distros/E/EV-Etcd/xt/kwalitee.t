#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Copy ();
use File::Spec;
use File::Glob ':bsd_glob';

eval "use Test::Kwalitee 1.28 'kwalitee_ok'; 1"
    or plan skip_all => 'Test::Kwalitee 1.28 required';

# Test::Kwalitee runs against the working directory and expects META.yml /
# META.json there. MakeMaker writes those into the dist staging dir on
# `make distmeta`, not the project root. Stage them at the root for the
# duration of the test so we don't need a full `make dist` to run kwalitee.
my $had_meta = -e 'META.yml' && -e 'META.json';
unless ($had_meta) {
    plan skip_all => 'no Makefile — run perl Makefile.PL first' unless -e 'Makefile';
    system($ENV{MAKE} || 'make', 'distmeta') == 0
        or plan skip_all => 'make distmeta failed';

    my ($dist_dir) = bsd_glob('EV-Etcd-*/');
    if ($dist_dir && -e "${dist_dir}META.yml" && -e "${dist_dir}META.json") {
        File::Copy::copy("${dist_dir}META.yml",  'META.yml')  or plan skip_all => "copy META.yml: $!";
        File::Copy::copy("${dist_dir}META.json", 'META.json') or plan skip_all => "copy META.json: $!";
    } else {
        plan skip_all => 'distmeta did not produce META files';
    }
}

kwalitee_ok();
done_testing();

END {
    # Always tear down the dist staging dir — `make distmeta` leaves it behind
    # and a stale copy from a prior run shadows the next one.
    for my $d (bsd_glob('EV-Etcd-*/')) {
        system('rm', '-rf', $d);
    }
    # Only remove META.{yml,json} if WE generated them — preserve any
    # pre-existing copies.
    unless ($had_meta) {
        unlink 'META.yml', 'META.json';
    }
}
