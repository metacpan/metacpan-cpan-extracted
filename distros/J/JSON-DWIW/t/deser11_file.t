#!/usr/bin/env perl

# Creation date: 2007-09-12 19:27:49
# Authors: don

use strict;
use warnings;
use Test;

# main
{
    use JSON::DWIW;

    if (JSON::DWIW::skip_deserialize_file()) {
        plan tests => 1;
        skip("Not ready for production", 0);
        exit 0;
    }
    else {
        plan tests => 22;
    }


    my $data = JSON::DWIW::deserialize_file("t/parse_file/pass0.json");
    ok($data and $data->{var1} eq 'val1');

    $data = JSON::DWIW::deserialize_file("t/parse_file/pass0.json");
    ok($data and $data->{var1} eq 'val1');

    my $error = JSON::DWIW->get_error_string;
    
    $data = JSON::DWIW::deserialize_file("t/parse_file/pass0.json");
    $error = JSON::DWIW->get_error_string;
    ok(not $error and $data and $data->{var1} eq 'val1');

    $data = JSON::DWIW::deserialize_file("t/non_existent_file.json");
    $error = JSON::DWIW->get_error_string;
    ok($error and $error =~ /couldn't open input file/);

    $data = JSON::DWIW::deserialize_file("t/parse_file/pass1.json");
    $error = JSON::DWIW->get_error_string;
    ok($data and not $error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/pass2.json");
    $error = JSON::DWIW->get_error_string;
    ok($data and not $error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/pass3.json");
    $error = JSON::DWIW->get_error_string;
    ok($data and not $error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/fail2.json");
    $error = JSON::DWIW->get_error_string;
    ok($error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/fail2.json");
    $error = JSON::DWIW->get_error_string;
    ok($error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/fail2.json");
    $error = JSON::DWIW->get_error_string;
    ok($error);

#     $data = JSON::DWIW::deserialize_file("t/parse_file/fail7.json");
#     $error = JSON::DWIW->get_error_string;
#     ok($error);

#     $data = JSON::DWIW::deserialize_file("t/parse_file/fail8.json");
#     $error = JSON::DWIW->get_error_string;
#     ok($error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/fail10.json");
    $error = JSON::DWIW->get_error_string;
    ok($error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/fail11.json");
    $error = JSON::DWIW->get_error_string;
    ok($error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/fail12.json");
    $error = JSON::DWIW->get_error_string;
    ok($error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/fail14.json");
    $error = JSON::DWIW->get_error_string;
    ok($error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/fail16.json");
    $error = JSON::DWIW->get_error_string;
    ok($error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/fail19.json");
    $error = JSON::DWIW->get_error_string;
    ok($error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/fail20.json");
    $error = JSON::DWIW->get_error_string;
    ok($error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/fail21.json");
    $error = JSON::DWIW->get_error_string;
    ok($error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/fail22.json");
    $error = JSON::DWIW->get_error_string;
    ok($error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/fail31.json");
    $error = JSON::DWIW->get_error_string;
    ok($error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/fail32.json");
    $error = JSON::DWIW->get_error_string;
    ok($error);

    $data = JSON::DWIW::deserialize_file("t/parse_file/fail33.json");
    $error = JSON::DWIW->get_error_string;
    ok($error);

}

exit 0;

###############################################################################
# Subroutines

