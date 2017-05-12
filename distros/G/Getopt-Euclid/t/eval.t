BEGIN {
    $0 = '-e';
}

use Test::More 'no_plan';

use_ok Getopt::Euclid;

# When running into eval mode, e.g. perl -e 'use Getopt::Euclid', @ARG is empty
# but $0 is '-e'. This leads to the warnings:
#    skipping file: '-e': no matches found
#    Use of uninitialized value in localtime at lib/Getopt/Euclid.pm line 370.

ok 1;


