#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure qw(err);
use Error::Pure::Utils qw(err_msg);

# Error in eval.
eval {
        err 'Error', 'item1', 'item2', 'item3', 'item4';
};
if ($EVAL_ERROR) {
        my @err_msg = err_msg();
        foreach my $item (@err_msg) {
                print "$item\n";
        }
}

# Output:
# Error
# item1
# item2
# item3
# item4