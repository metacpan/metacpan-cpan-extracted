#! perl

# copied over from JSON::DWIW and modified to use JSON::XS

# copied over from JSON::XS and modified for JSON::SL (again)

# Creation date: 2007-02-20 21:54:09
# Authors: don

use strict;
use warnings;
use Test;

BEGIN { plan tests => 7 }

use JSON::SL qw(decode_json);

my $json_str = '{"var1":"val1","var2":["first_element",{"sub_element":"sub_val","sub_element2":"sub_val2"}],"var3":"val3"}';

my $data = decode_json($json_str);

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

$json_str = '["val1"]';
$data = decode_json($json_str);
ok($data->[0] eq 'val1');

$json_str = '[567]';
$data = decode_json($json_str);
ok($data->[0] == 567);

$json_str = "[5e1]";
$data = decode_json($json_str);
ok($data->[0] == 50);

$json_str = "[5e3]";
$data = decode_json($json_str);
ok($data->[0] == 5000);

$json_str = "[5e+1]";
$data = decode_json($json_str);
ok($data->[0] == 50);

$json_str = "[5e-1]";
$data = decode_json($json_str);
ok($data->[0] == 0.5);

exit 0;

###############################################################################
# Subroutines

