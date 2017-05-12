#!/usr/bin/perl -w

# Name:   pod.t
# Author: wd (Wolfgang.Dobler@ucalgary.ca)
# Date:   30-Mar-2005
# Description:
#   Part of test suite for Namelist module:
#   Test documentation for syntactical correctness.

use strict;
use Test::More;

# Construct list of (internal)subroutines that do not need POD
# documentation.
# We could use something like
#   my @trustme = qw{ '_$', '^add_array_bracket$' }
# here, but that is a bit tedious and also results in a
# `Possible attempt to separate words with commas' warning.

my @nodoc_nlist
  = qw {
        add_array_bracket
        assign_slot_val
        debug
        encaps_logical_idl
        encapsulate_values
        format_slots
        aggregate_slots
        extract_nl_name
        get_value
        elucidate_type
        infer_data_type
        parse_namelist
        printable_substring
        quote_string
        quote_string_f90
        show_error
        strip_space_and_comment
    };

my @trustme;
# push @trustme, "'_\$',";        # private methods end in _ (do they?)
push @trustme, wrap_subnames(@nodoc_nlist);

# eval "use Test::Distribution";
eval "use Test::Distribution podcoveropts => {trustme => [@trustme]}";
if ($@) {
    my @mesg = map { substr($_,79) = ''; $_ } $@;  # truncate to 79 chars
    plan skip_all => "Test::Distribution not installed: @mesg";
}

# ---------------------------------------------------------------------- #
sub wrap_subnames {
#
#  Takes list of subroutine names <sub> and surrounds each with a few
#  characters to become '^<sub>$', as required for use in our eval line.
#
    return map { s{(.*)}{'^$1\$',}; $_ } @_;
}
# ---------------------------------------------------------------------- #

# End of file pod.t
