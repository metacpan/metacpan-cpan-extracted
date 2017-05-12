#!/usr/bin/env perl

# Creation date: 2007-02-20 21:54:09
# Authors: don

use strict;
use warnings;
use Test;

# main
{
    use JSON::DWIW;

    if (JSON::DWIW->has_deserialize) {
        plan tests => 13;
    }
    else {
        plan tests => 1;

        print "# deserialize not implemented on this platform\n";
        skip("Skipping on this platform", 0); # skipping on this platform
        exit 0;
    }

    my $json_str = '{"var1":"val1","var2":["first_element",{"sub_element":"sub_val","sub_element2":"sub_val2"}],"var3":"val3"}';

    my $data = JSON::DWIW::deserialize($json_str);

    # complex value
    my $pass = 1;
    if ($data->{var1} eq 'val1' and $data->{var3} eq 'val3') {
        if ($data->{var2}) {
            my $array = $data->{var2};
            if (ref($array) eq 'ARRAY') {
                if ($array->[0] eq 'first_element') {
                    my $hash = $array->[1];
                    if (ref($hash) eq 'HASH') {
                        unless ($hash->{sub_element} eq 'sub_val'
                                and $hash->{sub_element2} eq 'sub_val2') {
                            $pass = 0;
                        }
                    }
                    else {
                        $pass = 0;
                    }
                }
                else {
                    $pass = 0;
                }
            }
            else {
                $pass = 0;
            }
        }
        else {
            $pass = 0;
        }
    }
    
    ok($pass);

    # string
    $json_str = '"val1"';
    $data = JSON::DWIW::deserialize($json_str);
    ok($data eq 'val1');

    # numbers
    $json_str = '567';
    $data = JSON::DWIW::deserialize($json_str);
    ok($data == 567);

    $json_str = "5e1";
    $data = JSON::DWIW::deserialize($json_str);
    ok($data == 50);

    $json_str = "5e3";
    $data = JSON::DWIW::deserialize($json_str);
    ok($data == 5000);

    $json_str = "5e+1";
    $data = JSON::DWIW::deserialize($json_str);
    ok($data == 50);

    $json_str = "5e-1";
    $data = JSON::DWIW::deserialize($json_str);
    ok($data == 0.5);

    # empty array
    $json_str = '[]';
    $data = JSON::DWIW::deserialize($json_str);
    ok(ref($data) eq 'ARRAY' and scalar(@$data) == 0);

    # empty hash
    $json_str = '{}';
    $data = JSON::DWIW::deserialize($json_str);
    ok(ref($data) eq 'HASH' and scalar(keys(%$data)) == 0);

    # empty array as value in hash
    $json_str = '{"test_empty":[]}';
    $data = JSON::DWIW::deserialize($json_str);
    ok(ref($data) eq 'HASH' and scalar(keys(%$data)) == 1 and ref($data->{test_empty}) eq 'ARRAY'
      and scalar(@{$data->{test_empty}}) == 0);

    # empty hash as value in a hash
    $json_str = '{"test_empty":{}}';
    $data = JSON::DWIW::deserialize($json_str);
    ok(ref($data) eq 'HASH' and scalar(keys(%$data)) == 1 and ref($data->{test_empty}) eq 'HASH'
       and scalar(keys %{$data->{test_empty}}) == 0);

    $json_str = '{"test_empty_hash":{},"test_empty_array":[]}';
    $data = JSON::DWIW::deserialize($json_str);
    ok(ref($data) eq 'HASH' and scalar(keys(%$data)) == 2
       and ref($data->{test_empty_hash}) eq 'HASH'
       and scalar(keys %{$data->{test_empty_hash}}) == 0
       and ref($data->{test_empty_array}) eq 'ARRAY'
       and scalar(@{$data->{test_empty_array}}) == 0
      );


    # comment
    $json_str = '{"test_empty_hash":{} /*,"test_empty_array":[] */}';
    $data = JSON::DWIW::deserialize($json_str);
    ok(ref($data) eq 'HASH' and scalar(keys(%$data)) == 1
       and ref($data->{test_empty_hash}) eq 'HASH'
       and scalar(keys %{$data->{test_empty_hash}}) == 0);
    
}

exit 0;

###############################################################################
# Subroutines

