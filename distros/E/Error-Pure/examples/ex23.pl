#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure qw(err);
use Error::Pure::Utils qw(err_msg_hr);

# Error in eval.
eval {
        err 'Error',
                'key1', 'val1',
                'key2', 'val2';
};
if ($EVAL_ERROR) {
        print $EVAL_ERROR;
        my $err_msg_hr = err_msg_hr();
        foreach my $key (sort keys %{$err_msg_hr}) {
                print "$key: $err_msg_hr->{$key}\n";
        }
}

# Output:
# Error
# key1: val1
# key2: val2