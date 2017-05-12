#!/usr/bin/env perl

# Creation date: 2007-10-02 18:51:38
# Authors: don

use strict;
use warnings;

# main
{
    use Test;

    use JSON::DWIW;
    
    if (JSON::DWIW->has_deserialize) {
        plan tests => 19;
    }
    else {
        plan tests => 1;

        print "# deserialize not implemented on this platform\n";
        skip("Skipping on this platform", 0); # skipping on this platform
        exit 0;
    }

    
    my $str = qq{{"test":"\xc3\xa4","funky":"\\u70":"key":"val"}};
    my ($data, $error);

    $data = JSON::DWIW::deserialize($str);
    $error = JSON::DWIW::get_error_string();

    ok($error);

    ok(defined $error and $error =~ /bad unicode character specification/);
    ok(defined $error and $error =~ /char 25/);
    ok(defined $error and $error =~ /byte 26/);
    ok(defined $error and $error =~ /line 1/);
    ok(defined $error and $error =~ /, col 25/);
    ok(defined $error and $error =~ /byte col 26/);
    ok(defined JSON::DWIW->get_error_string);
    ok(defined $error and $error =~ /JSON::DWIW/);
    
    $data = JSON::DWIW::deserialize($str);
    $error = JSON::DWIW->get_error_string;

    $str = qq{{"test":"\xc3\xa4",\n"funky":"\\u70":"key":"val"}};
    $data = JSON::DWIW::deserialize($str);
    $error = JSON::DWIW->get_error_string;

    ok(defined $error and $error =~ /char 26/);
    ok(defined $error and $error =~ /byte 27/);
    ok(defined $error and $error =~ /line 2/);
    ok(defined $error and $error =~ /, col 13/);
    ok(defined $error and $error =~ /byte col 13/);

    $str = qq{{"test":"\xc3\xa4","test2":"}};
    $data = JSON::DWIW::deserialize($str);
    $error = JSON::DWIW->get_error_string;
    ok(defined $error and $error =~ /unterminated string/);
    ok(defined $error and $error =~ /byte 22/);
    ok(defined $error and $error =~ /char 21/);
    ok(defined $error and $error =~ /byte col 22/);

    $str = qq|{"var1":1,"var2":"val2","var3":[1,2,3,4,5], "test":true, "check":null}\n{"var4":"val4"}|;
    $data = JSON::DWIW::deserialize($str);
    $error = JSON::DWIW->get_error_string;
    ok(defined $error);

}

exit 0;

###############################################################################
# Subroutines

