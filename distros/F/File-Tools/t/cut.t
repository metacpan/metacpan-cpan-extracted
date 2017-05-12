#!/usr/bin/perl -w
use strict;

use Test::More;
use Test::NoWarnings;
use File::Tools ':all';

plan tests => 1 + 4;

is File::Tools::cut ({bytes => 1}, "123456789abcdf"), "1",    "bytes => 1";
is File::Tools::cut ({bytes => 4}, "123456789abcdf"), "4",    "bytes => 4";
is File::Tools::cut ({bytes => 10}, "123456789abcdf"), "a",   "bytes => 10";
is File::Tools::cut ({bytes => 14}, "123456789abcdf"), "f",   "bytes => 15";
# is File::Tools::cut ({bytes => 15}, "123456789abcdf"), "f", ;
#is File::Tools::cut ({bytes => "1,3"}, "123456789abcdf"), "13";
#is File::Tools::cut ({bytes => "1,15"}, "123456789abcdf"), "1f";
#is File::Tools::cut ({bytes => "15,1"}, "123456789abcdf"), "1f";
#is File::Tools::cut ({bytes => "-5,1"}, "123456789abcdf"), "12345";
#is File::Tools::cut ({bytes => "-5,15"}, "123456789abcdf"), "12345f";
#is File::Tools::cut ({bytes => "15,-5"}, "123456789abcdf"), "12345f";



