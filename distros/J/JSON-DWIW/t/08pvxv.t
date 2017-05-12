#!/usr/bin/env perl

# Creation date: 2007-04-17 20:39:26
# Authors: don

# Test scalars that have types indicating they can be either a string or another type

use strict;

# main
{
    use Test;
    plan tests => 3;

    use JSON::DWIW;

    # SVt_PVIV
    my $data = {};
    $data->{test_var} = 0;
    $data->{test_var} = 'blah';

    my $str = JSON::DWIW->to_json($data);
    ok($str eq '{"test_var":"blah"}');

    my $data2 = {};
    my $test_val = 0;
    $test_val = 'blah';
    $data2->{test_var} = $test_val;
    $str = JSON::DWIW->to_json($data2);
    ok($str eq '{"test_var":"blah"}');

    # SVt_PVNV
    $data2 = { test_var => 0.5 };
    $data2->{test_var} = 'blah';
    $str = JSON::DWIW->to_json($data2);
    ok($str eq '{"test_var":"blah"}');
}

exit 0;

###############################################################################
# Subroutines

