# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GnuCash-SQLite.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use JSON;
use lib 'lib';

use Test::More tests => 8;
BEGIN { use_ok('JSON::JSend') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my ($jsend, $got, $exp, $msg, $tmp1, $tmp2);
$jsend = JSON::JSend->new();

$got = hashref2str(from_json($jsend->success()));
$exp = hashref2str(from_json('{"status":"success","data":null}'));
$msg = 'Success without data works.';
is($got,$exp,$msg);

$tmp1 = {   post => { 
                id    => 1, 
                title => 'A blog post', 
                body  => 'Some useful content'
            }
        };
$tmp2 = {   status => 'success',
            data   => $tmp1 };
$got = hashref2str(from_json($jsend->success($tmp1)));
$exp = hashref2str($tmp2);
$msg = 'Success with data works.';
is($got,$exp,$msg);

$got = hashref2str(from_json($jsend->fail()));
$exp = hashref2str(from_json('{"status":"fail","data":null}'));
$msg = 'Fail without data works.';
is($got,$exp,$msg);

$tmp1 = { title => 'A title is required' };
$tmp2 = { status => 'fail',
          data   => $tmp1 };
$got = hashref2str(from_json($jsend->fail($tmp1)));
$exp = hashref2str($tmp2);
$msg = 'Fail with data works.';
is($got,$exp,$msg);

my $message = 'Unable to communicate with the database';
my $code = 50001;
my $data = { some_extra_info => 'Extra info goes here' };

$tmp1 = { status  => 'error',
          message => $message };
$got = hashref2str(from_json($jsend->error($message)));
$exp = hashref2str($tmp1);
$msg = 'JSend error() with just message works.';
is($got,$exp,$msg);

$msg = 'JSend error() with message, code and data works.';
$tmp1 = { status  => 'error',
          code => $code,
          data => $data,
          message => $message };
$got = hashref2str(from_json($jsend->error($message,$code,$data)));
$exp = hashref2str($tmp1);
is($got,$exp,$msg);

$msg = 'JSend error() with just message and data works.';
$tmp1 = { status  => 'error',
          data => $data,
          message => $message };
$got = hashref2str(from_json($jsend->error($message,$data)));
$exp = hashref2str($tmp1);
is($got,$exp,$msg);

#------------------------------------------------------------------
# Test Utilities
#------------------------------------------------------------------

# Given a hashref
# Return a string representation that's the same everytime
sub hashref2str {
    my $href = shift;
    my $result = '';

    foreach my $k (sort keys %{$href}) {
        if (defined($href->{$k})) {
            if (ref($href->{$k}) eq 'HASH') {
                $result .= "  $k - " . hashref2str($href->{$k}) . " \n"; 
            } else {
                $result .= "  $k - $href->{$k} \n"; 
            }
        } else {
            $result .= "  $k - undef \n"; 
        }
    }
    return $result;
} 

