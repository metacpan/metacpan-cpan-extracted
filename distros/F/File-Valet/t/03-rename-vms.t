#!/bin/env perl

use strict;
use warnings;
use Test::Most;

use lib "./lib";
use File::Valet;

# tests for find_temp (kind of weak; needs improvement):
isnt find_temp(),  undef,     'find_temp found something at all';
ok   find_temp() =~ /t/i,     'find_temp found something likely';
is $File::Valet::OK,    'OK', 'find_temp sets OK on success';
is $File::Valet::ERROR, '',   'find_temp sets error on success';
is $File::Valet::ERRNO, '',   'find_temp sets errno on success';

# tests for find_bin (also weak):
if ($^O eq 'MSWin32') {
    isnt find_bin('cmd.exe'), undef,       'find_bin found anything at all for cmd.exe';
    ok   find_bin('cmd.exe') =~ /cmd.exe/, 'find_bin found likely cmd.exe';
}
else {
    isnt find_bin('sh'), undef,      'find_bin found anything at all for sh';
    ok   find_bin('sh') =~ /bin.sh/, 'find_bin found likely /bin/sh';
}
is $File::Valet::OK,    'OK', 'find_bin sets OK on success';
is $File::Valet::ERROR, '',   'find_bin sets error on success';
is $File::Valet::ERRNO, '',   'find_bin sets errno on success';

done_testing();
exit(0);
