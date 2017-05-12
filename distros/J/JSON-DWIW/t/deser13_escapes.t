#!/usr/bin/env perl

# Creation date: 2008-03-22 14:33:38
# Authors: don

use strict;
use warnings;

use Test;

use JSON::DWIW;

if (JSON::DWIW->has_deserialize) {
    plan tests => 26;
}
else {
    plan tests => 1;
    
    print "# deserialize not implemented on this platform\n";
    skip("Skipping on this platform", 0); # skipping on this platform
    exit 0;
}

my $json_str = '{"key":"\x76al"}';

ok($json_str =~ /x/); # make sure no programmer error -- want the string to have \x76 in it

my $data = JSON::DWIW::deserialize($json_str);

ok($data and $data->{key} eq 'val');

$json_str = '{"key":"\u0076al"}';
ok($json_str =~ /u/); # make sure no programmer error -- want the string to have \u0076 in it
$data = JSON::DWIW::deserialize($json_str);
ok($data and $data->{key} eq 'val');

# \u706b should convert to the octet sequence \xe7\x81\xab
$json_str = '{"key":"val\u706b4_1"}';
ok($json_str =~ /u/); # make sure no programmer error -- want the string to have \u706b in it
$data = JSON::DWIW::deserialize($json_str);
{
    # be sure to compare byte by byte
    use bytes;
    ok($data and $data->{key} eq "val\xe7\x81\xab4_1");
}

# backspace
$json_str = '{"key":"val\b"}';
ok($json_str =~ /b/); # dummy check
$data = JSON::DWIW::deserialize($json_str);
ok($data and $data->{key} eq "val\x08");

# line feed
$json_str = '{"key":"val\n"}';
ok($json_str =~ /n/); # dummy check
$data = JSON::DWIW::deserialize($json_str);
ok($data and $data->{key} eq "val\x0a");

# vertical tab
$json_str = '{"key":"bal\v"}';
ok($json_str =~ /v/); # dummy check
$data = JSON::DWIW::deserialize($json_str);
ok($data and $data->{key} eq "bal\x0b");

# form feed
$json_str = '{"key":"val\f"}';
ok($json_str =~ /f/); # dummy check
$data = JSON::DWIW::deserialize($json_str);
ok($data and $data->{key} eq "val\x0c");

# carriage return
$json_str = '{"key":"val\r"}';
ok($json_str =~ /r/); # dummy check
$data = JSON::DWIW::deserialize($json_str);
ok($data and $data->{key} eq "val\x0d");

# tab
$json_str = '{"key":"val\t"}';
ok($json_str =~ /t/); # dummy check
$data = JSON::DWIW::deserialize($json_str);
ok($data and $data->{key} eq "val\x09");

# backslash
$json_str = '{"key":"val\\\\"}';
ok($json_str =~ /\x5c\x5c/); # dummy check
$data = JSON::DWIW::deserialize($json_str);
ok($data and $data->{key} eq "val\x5c");

# slash/solidus
$json_str = '{"key":"val\\/"}';
ok($json_str =~ /\x5c\x2f/); # dummy check
$data = JSON::DWIW::deserialize($json_str);
ok($data and $data->{key} eq "val\x2f");

# double quote
$json_str = '{"key":"val\""}';
ok($json_str =~ /\x5c\x22/); # dummy check
$data = JSON::DWIW::deserialize($json_str);
ok($data and $data->{key} eq "val\x22");

# single quote
$json_str = '{"key":"val\\\'"}';
ok($json_str =~ /\x5c\x27/); # dummy check
$data = JSON::DWIW::deserialize($json_str);
ok($data and $data->{key} eq "val\x27");

