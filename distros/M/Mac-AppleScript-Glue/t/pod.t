#!/usr/bin/perl -w

# vim: set filetype=perl :

# some code here borrowed from brian d foy's Mac::PropertyList's
# t/pod.t

use strict;

my %pods;

BEGIN {
    use Pod::Find qw(pod_find);

    %pods = pod_find(
        {
            -verbose => 1,
        },
        'blib'
    );
}

use Test::Pod tests => scalar keys %pods;

for my $pod (keys %pods) {
    pod_file_ok($pod);
}
