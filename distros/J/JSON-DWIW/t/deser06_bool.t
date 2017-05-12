#!/usr/bin/env perl

# Creation date: 2007-05-10 21:02:13
# Authors: don

use strict;
use Test;

# main
{
    use JSON::DWIW;

    if (JSON::DWIW->has_deserialize) {
        plan tests => 4;
    }
    else {
        plan tests => 1;

        print "# deserialize not implemented on this platform\n";
        skip("Skipping on this platform", 0); # skipping on this platform
        exit 0;
    }


    my $data;
    my $str;

    $str = '{"var1":false}';
    $data = JSON::DWIW::deserialize($str, { convert_bool => 1 });
    my $bool = $data->{var1};
    ok(ref($bool) eq 'JSON::DWIW::Boolean' and not $bool);

    $str = '{"var1":true}';
    $data = JSON::DWIW::deserialize($str, { convert_bool => 1 });
    $bool = $data->{var1};
    ok(ref($bool) eq 'JSON::DWIW::Boolean' and $bool);

    # non conversions
    $str = '{"var1":false}';
    $data = JSON::DWIW::deserialize($str);
    $bool = $data->{var1};
    ok(not ref($bool));
    
    $str = '{"var1":true}';
    $data = JSON::DWIW::deserialize($str);
    $bool = $data->{var1};
    ok(not ref($bool));
}

exit 0;

###############################################################################
# Subroutines

