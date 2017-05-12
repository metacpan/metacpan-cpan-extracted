#!/usr/bin/env perl

# Creation date: 2007-05-10 21:02:13
# Authors: don

use strict;
use Test;

# main
{
    plan tests => 8;

    use JSON::DWIW;

    my $data;
    my $str;

    $data = { var1 => JSON::DWIW::Boolean->true, };
    $str = JSON::DWIW->to_json($data);
    ok($str eq '{"var1":true}');

    $data = { var1 => JSON::DWIW::Boolean->false, };
    $str = JSON::DWIW->to_json($data);
    ok($str eq '{"var1":false}');

    $data = { var1 => JSON::DWIW->true, };
    $str = JSON::DWIW->to_json($data);
    ok($str eq '{"var1":true}');

    $data = { var1 => JSON::DWIW->false, };
    $str = JSON::DWIW->to_json($data);
    ok($str eq '{"var1":false}');

    my $json_obj = JSON::DWIW->new;
    $data = { var1 => JSON::DWIW::Boolean->true, };
    $str = $json_obj->to_json($data);
    ok($str eq '{"var1":true}');

    $data = { var1 => JSON::DWIW::Boolean->false, };
    $str = $json_obj->to_json($data);
    ok($str eq '{"var1":false}');

    $str = '{"var1":false}';
    $data = JSON::DWIW->from_json($str, { convert_bool => 1 });
    my $bool = $data->{var1};
    ok(ref($bool) eq 'JSON::DWIW::Boolean' and not $bool);

    $str = '{"var1":true}';
    $data = JSON::DWIW->from_json($str, { convert_bool => 1 });
    $bool = $data->{var1};
    ok(ref($bool) eq 'JSON::DWIW::Boolean' and $bool);

}

exit 0;

###############################################################################
# Subroutines

