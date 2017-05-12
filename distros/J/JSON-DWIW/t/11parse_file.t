#!/usr/bin/env perl

# Creation date: 2007-09-12 19:27:49
# Authors: don

use strict;
use warnings;
use Test;

# main
{
    plan tests => 22;

    use JSON::DWIW;
    my $json_obj = JSON::DWIW->new;

    my $data = $json_obj->from_json_file("t/parse_file/pass0.json");
    ok($data and $data->{var1} eq 'val1');

    $data = JSON::DWIW->from_json_file("t/parse_file/pass0.json");
    ok($data and $data->{var1} eq 'val1');

    my $error;
    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/pass0.json");
    ok(not $error and $data and $data->{var1} eq 'val1');

    ($data, $error) = JSON::DWIW->from_json_file("t/non_existent_file.json");
    ok($error and $error =~ /couldn't open input file/);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/pass1.json");
    ok($data and not $error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/pass2.json");
    ok($data and not $error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/pass3.json");
    ok($data and not $error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail2.json");
    ok($error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail2.json");
    ok($error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail2.json");
    ok($error);

#     ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail7.json");
#     ok($error);

#     ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail8.json");
#     ok($error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail10.json");
    ok($error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail11.json");
    ok($error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail12.json");
    ok($error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail14.json");
    ok($error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail16.json");
    ok($error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail19.json");
    ok($error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail20.json");
    ok($error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail21.json");
    ok($error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail22.json");
    ok($error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail31.json");
    ok($error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail32.json");
    ok($error);

    ($data, $error) = JSON::DWIW->from_json_file("t/parse_file/fail33.json");
    ok($error);

}

exit 0;

###############################################################################
# Subroutines

