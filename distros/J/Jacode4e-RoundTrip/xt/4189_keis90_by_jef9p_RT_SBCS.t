######################################################################
#
# 4189_keis90_by_jef9p_RT_SBCS.t
#
# Copyright (c) 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use vars qw(@test);
    @test = (
        ["\x00\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x00\x00"],
        ["\x00\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x00\x00"],

        ["\x01\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x01\x00"],
        ["\x01\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x01\x00"],

        ["\x02\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x02\x00"],
        ["\x02\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x02\x00"],

        ["\x03\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x03\x00"],
        ["\x03\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x03\x00"],

        ["\x37\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x37\x00"],
        ["\x37\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x37\x00"],

        ["\x2D\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x2D\x00"],
        ["\x2D\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x2D\x00"],

        ["\x2E\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x2E\x00"],
        ["\x2E\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x2E\x00"],

        ["\x2F\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x2F\x00"],
        ["\x2F\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x2F\x00"],

        ["\x16\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x16\x00"],
        ["\x16\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x16\x00"],

        ["\x05\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x05\x00"],
        ["\x05\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x05\x00"],

        ["\x15\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x15\x00"],
        ["\x15\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x15\x00"],

        ["\x0B\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x0B\x00"],
        ["\x0B\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x0B\x00"],

        ["\x0C\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x0C\x00"],
        ["\x0C\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x0C\x00"],

        ["\x0D\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x0D\x00"],
        ["\x0D\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x0D\x00"],

        ["\x0E\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x0E\x00"],
        ["\x0E\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x0E\x00"],

        ["\x0F\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x0F\x00"],
        ["\x0F\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x0F\x00"],

        ["\x10\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x10\x00"],
        ["\x10\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x10\x00"],

        ["\x11\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x11\x00"],
        ["\x11\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x11\x00"],

        ["\x12\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x12\x00"],
        ["\x12\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x12\x00"],

        ["\x13\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x13\x00"],
        ["\x13\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x13\x00"],

        ["\x3C\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x3C\x00"],
        ["\x3C\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x3C\x00"],

        ["\x3D\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x3D\x00"],
        ["\x3D\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x3D\x00"],

        ["\x32\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x32\x00"],
        ["\x32\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x32\x00"],

        ["\x26\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x26\x00"],
        ["\x26\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x26\x00"],

        ["\x18\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x18\x00"],
        ["\x18\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x18\x00"],

        ["\x19\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x19\x00"],
        ["\x19\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x19\x00"],

        ["\x3F\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x3F\x00"],
        ["\x3F\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x3F\x00"],

        ["\x27\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x27\x00"],
        ["\x27\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x27\x00"],

        ["\x1C\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x1C\x00"],
        ["\x1C\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x1C\x00"],

        ["\x1D\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x1D\x00"],
        ["\x1D\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x1D\x00"],

        ["\x1E\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x1E\x00"],
        ["\x1E\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x1E\x00"],

        ["\x1F\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x1F\x00"],
        ["\x1F\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x1F\x00"],

        ["\x40\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x40\x00"],
        ["\x40\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x40\x00"],

        ["\x4F\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x4F\x00"],
        ["\x4F\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x4F\x00"],

        ["\x7F\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x7F\x00"],
        ["\x7F\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x7F\x00"],

        ["\x7B\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x7B\x00"],
        ["\x7B\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x7B\x00"],

        ["\xE0\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xE0\x00"],
        ["\xE0\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xE0\x00"],

        ["\x6C\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x6C\x00"],
        ["\x6C\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x6C\x00"],

        ["\x50\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x50\x00"],
        ["\x50\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x50\x00"],

        ["\x7D\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x7D\x00"],
        ["\x7D\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x7D\x00"],

        ["\x4D\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x4D\x00"],
        ["\x4D\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x4D\x00"],

        ["\x5D\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x5D\x00"],
        ["\x5D\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x5D\x00"],

        ["\x5C\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x5C\x00"],
        ["\x5C\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x5C\x00"],

        ["\x4E\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x4E\x00"],
        ["\x4E\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x4E\x00"],

        ["\x6B\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x6B\x00"],
        ["\x6B\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x6B\x00"],

        ["\x60\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x60\x00"],
        ["\x60\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x60\x00"],

        ["\x4B\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x4B\x00"],
        ["\x4B\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x4B\x00"],

        ["\x61\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x61\x00"],
        ["\x61\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x61\x00"],

        ["\xF0\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xF0\x00"],
        ["\xF0\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xF0\x00"],

        ["\xF1\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xF1\x00"],
        ["\xF1\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xF1\x00"],

        ["\xF2\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xF2\x00"],
        ["\xF2\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xF2\x00"],

        ["\xF3\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xF3\x00"],
        ["\xF3\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xF3\x00"],

        ["\xF4\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xF4\x00"],
        ["\xF4\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xF4\x00"],

        ["\xF5\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xF5\x00"],
        ["\xF5\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xF5\x00"],

        ["\xF6\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xF6\x00"],
        ["\xF6\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xF6\x00"],

        ["\xF7\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xF7\x00"],
        ["\xF7\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xF7\x00"],

        ["\xF8\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xF8\x00"],
        ["\xF8\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xF8\x00"],

        ["\xF9\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xF9\x00"],
        ["\xF9\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xF9\x00"],

        ["\x7A\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x7A\x00"],
        ["\x7A\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x7A\x00"],

        ["\x5E\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x5E\x00"],
        ["\x5E\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x5E\x00"],

        ["\x4C\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x4C\x00"],
        ["\x4C\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x4C\x00"],

        ["\x7E\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x7E\x00"],
        ["\x7E\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x7E\x00"],

        ["\x6E\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x6E\x00"],
        ["\x6E\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x6E\x00"],

        ["\x6F\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x6F\x00"],
        ["\x6F\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x6F\x00"],

        ["\x7C\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x7C\x00"],
        ["\x7C\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x7C\x00"],

        ["\xC1\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xC1\x00"],
        ["\xC1\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xC1\x00"],

        ["\xC2\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xC2\x00"],
        ["\xC2\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xC2\x00"],

        ["\xC3\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xC3\x00"],
        ["\xC3\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xC3\x00"],

        ["\xC4\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xC4\x00"],
        ["\xC4\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xC4\x00"],

        ["\xC5\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xC5\x00"],
        ["\xC5\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xC5\x00"],

        ["\xC6\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xC6\x00"],
        ["\xC6\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xC6\x00"],

        ["\xC7\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xC7\x00"],
        ["\xC7\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xC7\x00"],

        ["\xC8\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xC8\x00"],
        ["\xC8\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xC8\x00"],

        ["\xC9\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xC9\x00"],
        ["\xC9\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xC9\x00"],

        ["\xD1\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xD1\x00"],
        ["\xD1\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xD1\x00"],

        ["\xD2\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xD2\x00"],
        ["\xD2\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xD2\x00"],

        ["\xD3\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xD3\x00"],
        ["\xD3\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xD3\x00"],

        ["\xD4\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xD4\x00"],
        ["\xD4\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xD4\x00"],

        ["\xD5\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xD5\x00"],
        ["\xD5\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xD5\x00"],

        ["\xD6\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xD6\x00"],
        ["\xD6\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xD6\x00"],

        ["\xD7\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xD7\x00"],
        ["\xD7\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xD7\x00"],

        ["\xD8\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xD8\x00"],
        ["\xD8\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xD8\x00"],

        ["\xD9\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xD9\x00"],
        ["\xD9\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xD9\x00"],

        ["\xE2\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xE2\x00"],
        ["\xE2\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xE2\x00"],

        ["\xE3\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xE3\x00"],
        ["\xE3\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xE3\x00"],

        ["\xE4\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xE4\x00"],
        ["\xE4\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xE4\x00"],

        ["\xE5\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xE5\x00"],
        ["\xE5\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xE5\x00"],

        ["\xE6\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xE6\x00"],
        ["\xE6\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xE6\x00"],

        ["\xE7\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xE7\x00"],
        ["\xE7\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xE7\x00"],

        ["\xE8\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xE8\x00"],
        ["\xE8\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xE8\x00"],

        ["\xE9\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xE9\x00"],
        ["\xE9\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xE9\x00"],

        ["\x4A\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x4A\x00"],
        ["\x4A\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x4A\x00"],

        ["\x5B\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x5B\x00"],
        ["\x5B\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x5B\x00"],

        ["\x5A\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x5A\x00"],
        ["\x5A\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x5A\x00"],

        ["\x5F\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x5F\x00"],
        ["\x5F\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x5F\x00"],

        ["\x6D\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x6D\x00"],
        ["\x6D\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x6D\x00"],

        ["\x79\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x79\x00"],
        ["\x79\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x79\x00"],

        ["\x59\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x59\x00"],
        ["\x59\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x59\x00"],

        ["\x62\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x62\x00"],
        ["\x62\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x62\x00"],

        ["\x63\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x63\x00"],
        ["\x63\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x63\x00"],

        ["\x64\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x64\x00"],
        ["\x64\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x64\x00"],

        ["\x65\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x65\x00"],
        ["\x65\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x65\x00"],

        ["\x66\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x66\x00"],
        ["\x66\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x66\x00"],

        ["\x67\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x67\x00"],
        ["\x67\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x67\x00"],

        ["\x68\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x68\x00"],
        ["\x68\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x68\x00"],

        ["\x69\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x69\x00"],
        ["\x69\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x69\x00"],

        ["\x70\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x70\x00"],
        ["\x70\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x70\x00"],

        ["\x71\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x71\x00"],
        ["\x71\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x71\x00"],

        ["\x72\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x72\x00"],
        ["\x72\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x72\x00"],

        ["\x73\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x73\x00"],
        ["\x73\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x73\x00"],

        ["\x74\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x74\x00"],
        ["\x74\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x74\x00"],

        ["\x75\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x75\x00"],
        ["\x75\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x75\x00"],

        ["\x76\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x76\x00"],
        ["\x76\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x76\x00"],

        ["\x77\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x77\x00"],
        ["\x77\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x77\x00"],

        ["\x78\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x78\x00"],
        ["\x78\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x78\x00"],

        ["\x80\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x80\x00"],
        ["\x80\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x80\x00"],

        ["\x8B\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x8B\x00"],
        ["\x8B\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x8B\x00"],

        ["\x9B\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x9B\x00"],
        ["\x9B\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x9B\x00"],

        ["\x9C\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x9C\x00"],
        ["\x9C\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x9C\x00"],

        ["\xA0\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xA0\x00"],
        ["\xA0\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xA0\x00"],

        ["\xAB\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xAB\x00"],
        ["\xAB\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xAB\x00"],

        ["\xB0\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xB0\x00"],
        ["\xB0\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xB0\x00"],

        ["\xB1\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xB1\x00"],
        ["\xB1\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xB1\x00"],

        ["\xC0\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xC0\x00"],
        ["\xC0\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xC0\x00"],

        ["\x6A\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x6A\x00"],
        ["\x6A\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x6A\x00"],

        ["\xD0\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xD0\x00"],
        ["\xD0\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xD0\x00"],

        ["\xA1\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xA1\x00"],
        ["\xA1\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xA1\x00"],

        ["\x07\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x07\x00"],
        ["\x07\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x07\x00"],

        ["\x20\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x20\x00"],
        ["\x20\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x20\x00"],

        ["\x21\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x21\x00"],
        ["\x21\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x21\x00"],

        ["\x22\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x22\x00"],
        ["\x22\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x22\x00"],

        ["\x23\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x23\x00"],
        ["\x23\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x23\x00"],

        ["\x24\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x24\x00"],
        ["\x24\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x24\x00"],

        ["\x25\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x25\x00"],
        ["\x25\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x25\x00"],

        ["\x06\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x06\x00"],
        ["\x06\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x06\x00"],

        ["\x17\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x17\x00"],
        ["\x17\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x17\x00"],

        ["\x28\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x28\x00"],
        ["\x28\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x28\x00"],

        ["\x29\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x29\x00"],
        ["\x29\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x29\x00"],

        ["\x2A\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x2A\x00"],
        ["\x2A\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x2A\x00"],

        ["\x2B\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x2B\x00"],
        ["\x2B\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x2B\x00"],

        ["\x2C\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x2C\x00"],
        ["\x2C\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x2C\x00"],

        ["\x09\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x09\x00"],
        ["\x09\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x09\x00"],

        ["\x0A\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x0A\x00"],
        ["\x0A\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x0A\x00"],

        ["\x1B\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x1B\x00"],
        ["\x1B\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x1B\x00"],

        ["\x30\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x30\x00"],
        ["\x30\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x30\x00"],

        ["\x31\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x31\x00"],
        ["\x31\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x31\x00"],

        ["\x1A\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x1A\x00"],
        ["\x1A\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x1A\x00"],

        ["\x33\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x33\x00"],
        ["\x33\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x33\x00"],

        ["\x34\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x34\x00"],
        ["\x34\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x34\x00"],

        ["\x35\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x35\x00"],
        ["\x35\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x35\x00"],

        ["\x36\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x36\x00"],
        ["\x36\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x36\x00"],

        ["\x08\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x08\x00"],
        ["\x08\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x08\x00"],

        ["\x38\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x38\x00"],
        ["\x38\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x38\x00"],

        ["\x39\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x39\x00"],
        ["\x39\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x39\x00"],

        ["\x3A\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x3A\x00"],
        ["\x3A\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x3A\x00"],

        ["\x3B\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x3B\x00"],
        ["\x3B\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x3B\x00"],

        ["\x04\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x04\x00"],
        ["\x04\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x04\x00"],

        ["\x14\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x14\x00"],
        ["\x14\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x14\x00"],

        ["\x3E\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x3E\x00"],
        ["\x3E\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x3E\x00"],

        ["\xE1\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xE1\x00"],
        ["\xE1\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xE1\x00"],

        ["\x57\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x57\x00"],
        ["\x57\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x57\x00"],

        ["\x41\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x41\x00"],
        ["\x41\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x41\x00"],

        ["\x42\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x42\x00"],
        ["\x42\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x42\x00"],

        ["\x43\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x43\x00"],
        ["\x43\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x43\x00"],

        ["\x44\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x44\x00"],
        ["\x44\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x44\x00"],

        ["\x45\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x45\x00"],
        ["\x45\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x45\x00"],

        ["\x46\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x46\x00"],
        ["\x46\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x46\x00"],

        ["\x47\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x47\x00"],
        ["\x47\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x47\x00"],

        ["\x48\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x48\x00"],
        ["\x48\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x48\x00"],

        ["\x49\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x49\x00"],
        ["\x49\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x49\x00"],

        ["\x51\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x51\x00"],
        ["\x51\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x51\x00"],

        ["\x52\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x52\x00"],
        ["\x52\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x52\x00"],

        ["\x53\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x53\x00"],
        ["\x53\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x53\x00"],

        ["\x54\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x54\x00"],
        ["\x54\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x54\x00"],

        ["\x55\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x55\x00"],
        ["\x55\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x55\x00"],

        ["\x56\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x56\x00"],
        ["\x56\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x56\x00"],

        ["\x58\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x58\x00"],
        ["\x58\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x58\x00"],

        ["\x81\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x81\x00"],
        ["\x81\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x81\x00"],

        ["\x82\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x82\x00"],
        ["\x82\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x82\x00"],

        ["\x83\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x83\x00"],
        ["\x83\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x83\x00"],

        ["\x84\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x84\x00"],
        ["\x84\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x84\x00"],

        ["\x85\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x85\x00"],
        ["\x85\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x85\x00"],

        ["\x86\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x86\x00"],
        ["\x86\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x86\x00"],

        ["\x87\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x87\x00"],
        ["\x87\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x87\x00"],

        ["\x88\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x88\x00"],
        ["\x88\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x88\x00"],

        ["\x89\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x89\x00"],
        ["\x89\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x89\x00"],

        ["\x8A\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x8A\x00"],
        ["\x8A\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x8A\x00"],

        ["\x8C\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x8C\x00"],
        ["\x8C\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x8C\x00"],

        ["\x8D\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x8D\x00"],
        ["\x8D\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x8D\x00"],

        ["\x8E\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x8E\x00"],
        ["\x8E\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x8E\x00"],

        ["\x8F\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x8F\x00"],
        ["\x8F\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x8F\x00"],

        ["\x90\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x90\x00"],
        ["\x90\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x90\x00"],

        ["\x91\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x91\x00"],
        ["\x91\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x91\x00"],

        ["\x92\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x92\x00"],
        ["\x92\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x92\x00"],

        ["\x93\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x93\x00"],
        ["\x93\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x93\x00"],

        ["\x94\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x94\x00"],
        ["\x94\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x94\x00"],

        ["\x95\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x95\x00"],
        ["\x95\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x95\x00"],

        ["\x96\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x96\x00"],
        ["\x96\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x96\x00"],

        ["\x97\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x97\x00"],
        ["\x97\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x97\x00"],

        ["\x98\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x98\x00"],
        ["\x98\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x98\x00"],

        ["\x99\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x99\x00"],
        ["\x99\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x99\x00"],

        ["\x9A\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x9A\x00"],
        ["\x9A\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x9A\x00"],

        ["\x9D\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x9D\x00"],
        ["\x9D\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x9D\x00"],

        ["\x9E\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x9E\x00"],
        ["\x9E\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x9E\x00"],

        ["\x9F\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\x9F\x00"],
        ["\x9F\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\x9F\x00"],

        ["\xA2\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xA2\x00"],
        ["\xA2\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xA2\x00"],

        ["\xA3\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xA3\x00"],
        ["\xA3\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xA3\x00"],

        ["\xA4\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xA4\x00"],
        ["\xA4\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xA4\x00"],

        ["\xA5\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xA5\x00"],
        ["\xA5\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xA5\x00"],

        ["\xA6\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xA6\x00"],
        ["\xA6\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xA6\x00"],

        ["\xA7\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xA7\x00"],
        ["\xA7\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xA7\x00"],

        ["\xA8\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xA8\x00"],
        ["\xA8\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xA8\x00"],

        ["\xA9\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xA9\x00"],
        ["\xA9\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xA9\x00"],

        ["\xAA\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xAA\x00"],
        ["\xAA\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xAA\x00"],

        ["\xAC\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xAC\x00"],
        ["\xAC\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xAC\x00"],

        ["\xAD\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xAD\x00"],
        ["\xAD\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xAD\x00"],

        ["\xAE\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xAE\x00"],
        ["\xAE\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xAE\x00"],

        ["\xAF\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xAF\x00"],
        ["\xAF\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xAF\x00"],

        ["\xBA\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xBA\x00"],
        ["\xBA\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xBA\x00"],

        ["\xBB\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xBB\x00"],
        ["\xBB\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xBB\x00"],

        ["\xBC\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xBC\x00"],
        ["\xBC\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xBC\x00"],

        ["\xBD\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xBD\x00"],
        ["\xBD\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xBD\x00"],

        ["\xBE\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xBE\x00"],
        ["\xBE\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xBE\x00"],

        ["\xBF\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xBF\x00"],
        ["\xBF\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xBF\x00"],

        ["\xB2\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xB2\x00"],
        ["\xB2\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xB2\x00"],

        ["\xB3\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xB3\x00"],
        ["\xB3\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xB3\x00"],

        ["\xB4\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xB4\x00"],
        ["\xB4\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xB4\x00"],

        ["\xB5\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xB5\x00"],
        ["\xB5\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xB5\x00"],

        ["\xB6\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xB6\x00"],
        ["\xB6\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xB6\x00"],

        ["\xB7\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xB7\x00"],
        ["\xB7\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xB7\x00"],

        ["\xB8\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xB8\x00"],
        ["\xB8\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xB8\x00"],

        ["\xB9\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xB9\x00"],
        ["\xB9\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xB9\x00"],

        ["\xCA\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xCA\x00"],
        ["\xCA\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xCA\x00"],

        ["\xCB\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xCB\x00"],
        ["\xCB\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xCB\x00"],

        ["\xCC\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xCC\x00"],
        ["\xCC\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xCC\x00"],

        ["\xCD\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xCD\x00"],
        ["\xCD\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xCD\x00"],

        ["\xCE\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xCE\x00"],
        ["\xCE\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xCE\x00"],

        ["\xCF\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xCF\x00"],
        ["\xCF\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xCF\x00"],

        ["\xDA\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xDA\x00"],
        ["\xDA\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xDA\x00"],

        ["\xDB\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xDB\x00"],
        ["\xDB\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xDB\x00"],

        ["\xDC\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xDC\x00"],
        ["\xDC\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xDC\x00"],

        ["\xDD\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xDD\x00"],
        ["\xDD\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xDD\x00"],

        ["\xDE\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xDE\x00"],
        ["\xDE\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xDE\x00"],

        ["\xDF\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xDF\x00"],
        ["\xDF\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xDF\x00"],

        ["\xEA\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xEA\x00"],
        ["\xEA\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xEA\x00"],

        ["\xEB\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xEB\x00"],
        ["\xEB\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xEB\x00"],

        ["\xEC\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xEC\x00"],
        ["\xEC\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xEC\x00"],

        ["\xED\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xED\x00"],
        ["\xED\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xED\x00"],

        ["\xEE\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xEE\x00"],
        ["\xEE\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xEE\x00"],

        ["\xEF\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xEF\x00"],
        ["\xEF\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xEF\x00"],

        ["\xFA\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xFA\x00"],
        ["\xFA\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xFA\x00"],

        ["\xFB\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xFB\x00"],
        ["\xFB\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xFB\x00"],

        ["\xFC\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xFC\x00"],
        ["\xFC\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xFC\x00"],

        ["\xFD\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xFD\x00"],
        ["\xFD\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xFD\x00"],

        ["\xFE\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xFE\x00"],
        ["\xFE\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xFE\x00"],

        ["\xFF\x00",'keis90','jef',{'INPUT_LAYOUT'=>'SS'},"\xFF\x00"],
        ["\xFF\x00",'jef','keis90',{'INPUT_LAYOUT'=>'SS'},"\xFF\x00"],

    );
    $|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }
}

use Jacode4e::RoundTrip;

for my $test (@test) {
    my($give,$OUTPUT_encoding,$INPUT_encoding,$option,$want) = @{$test};
    my $got = $give;
    my $return = Jacode4e::RoundTrip::convert(\$got,$OUTPUT_encoding,$INPUT_encoding,$option);

    my $option_content = '';
    if (defined $option) {
        $option_content .= qq{INPUT_LAYOUT=>$option->{'INPUT_LAYOUT'}}        if exists $option->{'INPUT_LAYOUT'};
        $option_content .= qq{OUTPUT_SHIFTING=>$option->{'OUTPUT_SHIFTING'}}  if exists $option->{'OUTPUT_SHIFTING'};
        $option_content .= qq{SPACE=>@{[uc unpack('H*',$option->{'SPACE'})]}} if exists $option->{'SPACE'};
        $option_content .= qq{GETA=>@{[uc unpack('H*',$option->{'GETA'})]}}   if exists $option->{'GETA'};
        $option_content = "{$option_content}";
    }

    ok(($return > 0) and ($got eq $want),
        sprintf(qq{$INPUT_encoding(%s) to $OUTPUT_encoding(%s), $option_content => return=$return,got=(%s)},
            uc unpack('H*',$give),
            uc unpack('H*',$want),
            uc unpack('H*',$got),
        )
    );
}

__END__
