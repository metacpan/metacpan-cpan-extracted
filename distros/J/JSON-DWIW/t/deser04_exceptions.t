#!/usr/bin/env perl

# Creation date: 2007-04-04 21:57:58
# Authors: don

use strict;
use Test;

# main
{
    use JSON::DWIW;

    if (JSON::DWIW->has_deserialize) {
        plan tests => 1;
    }
    else {
        plan tests => 1;

        print "# deserialize not implemented on this platform\n";
        skip("Skipping on this platform", 0); # skipping on this platform
        exit 0;
    }


    local $SIG{__DIE__};

    my $bad_str = '{"stuff":blah}';
    eval { my $data = JSON::DWIW::deserialize($bad_str, { use_exceptions => 1 }); };

    ok($@);

}

exit 0;

###############################################################################
# Subroutines

