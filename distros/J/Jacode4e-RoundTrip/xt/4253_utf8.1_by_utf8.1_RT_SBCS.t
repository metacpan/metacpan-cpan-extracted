######################################################################
#
# 4253_utf8.1_by_utf8.1_RT_SBCS.t
#
# Copyright (c) 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use vars qw(@test);
    @test = (
        ["\x00\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x00\x00"],
        ["\x00\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x00\x00"],

        ["\x01\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x01\x00"],
        ["\x01\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x01\x00"],

        ["\x02\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x02\x00"],
        ["\x02\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x02\x00"],

        ["\x03\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x03\x00"],
        ["\x03\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x03\x00"],

        ["\x04\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x04\x00"],
        ["\x04\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x04\x00"],

        ["\x05\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x05\x00"],
        ["\x05\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x05\x00"],

        ["\x06\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x06\x00"],
        ["\x06\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x06\x00"],

        ["\x07\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x07\x00"],
        ["\x07\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x07\x00"],

        ["\x08\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x08\x00"],
        ["\x08\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x08\x00"],

        ["\x09\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x09\x00"],
        ["\x09\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x09\x00"],

        ["\x0A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x0A\x00"],
        ["\x0A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x0A\x00"],

        ["\x0B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x0B\x00"],
        ["\x0B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x0B\x00"],

        ["\x0C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x0C\x00"],
        ["\x0C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x0C\x00"],

        ["\x0D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x0D\x00"],
        ["\x0D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x0D\x00"],

        ["\x0E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x0E\x00"],
        ["\x0E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x0E\x00"],

        ["\x0F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x0F\x00"],
        ["\x0F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x0F\x00"],

        ["\x10\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x10\x00"],
        ["\x10\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x10\x00"],

        ["\x11\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x11\x00"],
        ["\x11\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x11\x00"],

        ["\x12\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x12\x00"],
        ["\x12\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x12\x00"],

        ["\x13\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x13\x00"],
        ["\x13\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x13\x00"],

        ["\x14\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x14\x00"],
        ["\x14\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x14\x00"],

        ["\x15\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x15\x00"],
        ["\x15\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x15\x00"],

        ["\x16\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x16\x00"],
        ["\x16\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x16\x00"],

        ["\x17\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x17\x00"],
        ["\x17\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x17\x00"],

        ["\x18\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x18\x00"],
        ["\x18\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x18\x00"],

        ["\x19\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x19\x00"],
        ["\x19\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x19\x00"],

        ["\x1A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x1A\x00"],
        ["\x1A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x1A\x00"],

        ["\x1B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x1B\x00"],
        ["\x1B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x1B\x00"],

        ["\x1C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x1C\x00"],
        ["\x1C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x1C\x00"],

        ["\x1D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x1D\x00"],
        ["\x1D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x1D\x00"],

        ["\x1E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x1E\x00"],
        ["\x1E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x1E\x00"],

        ["\x1F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x1F\x00"],
        ["\x1F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x1F\x00"],

        ["\x20\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x20\x00"],
        ["\x20\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x20\x00"],

        ["\x21\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x21\x00"],
        ["\x21\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x21\x00"],

        ["\x22\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x22\x00"],
        ["\x22\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x22\x00"],

        ["\x23\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x23\x00"],
        ["\x23\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x23\x00"],

        ["\x24\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x24\x00"],
        ["\x24\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x24\x00"],

        ["\x25\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x25\x00"],
        ["\x25\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x25\x00"],

        ["\x26\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x26\x00"],
        ["\x26\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x26\x00"],

        ["\x27\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x27\x00"],
        ["\x27\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x27\x00"],

        ["\x28\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x28\x00"],
        ["\x28\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x28\x00"],

        ["\x29\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x29\x00"],
        ["\x29\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x29\x00"],

        ["\x2A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x2A\x00"],
        ["\x2A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x2A\x00"],

        ["\x2B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x2B\x00"],
        ["\x2B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x2B\x00"],

        ["\x2C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x2C\x00"],
        ["\x2C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x2C\x00"],

        ["\x2D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x2D\x00"],
        ["\x2D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x2D\x00"],

        ["\x2E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x2E\x00"],
        ["\x2E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x2E\x00"],

        ["\x2F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x2F\x00"],
        ["\x2F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x2F\x00"],

        ["\x30\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x30\x00"],
        ["\x30\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x30\x00"],

        ["\x31\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x31\x00"],
        ["\x31\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x31\x00"],

        ["\x32\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x32\x00"],
        ["\x32\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x32\x00"],

        ["\x33\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x33\x00"],
        ["\x33\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x33\x00"],

        ["\x34\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x34\x00"],
        ["\x34\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x34\x00"],

        ["\x35\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x35\x00"],
        ["\x35\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x35\x00"],

        ["\x36\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x36\x00"],
        ["\x36\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x36\x00"],

        ["\x37\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x37\x00"],
        ["\x37\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x37\x00"],

        ["\x38\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x38\x00"],
        ["\x38\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x38\x00"],

        ["\x39\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x39\x00"],
        ["\x39\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x39\x00"],

        ["\x3A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x3A\x00"],
        ["\x3A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x3A\x00"],

        ["\x3B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x3B\x00"],
        ["\x3B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x3B\x00"],

        ["\x3C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x3C\x00"],
        ["\x3C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x3C\x00"],

        ["\x3D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x3D\x00"],
        ["\x3D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x3D\x00"],

        ["\x3E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x3E\x00"],
        ["\x3E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x3E\x00"],

        ["\x3F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x3F\x00"],
        ["\x3F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x3F\x00"],

        ["\x40\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x40\x00"],
        ["\x40\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x40\x00"],

        ["\x41\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x41\x00"],
        ["\x41\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x41\x00"],

        ["\x42\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x42\x00"],
        ["\x42\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x42\x00"],

        ["\x43\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x43\x00"],
        ["\x43\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x43\x00"],

        ["\x44\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x44\x00"],
        ["\x44\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x44\x00"],

        ["\x45\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x45\x00"],
        ["\x45\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x45\x00"],

        ["\x46\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x46\x00"],
        ["\x46\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x46\x00"],

        ["\x47\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x47\x00"],
        ["\x47\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x47\x00"],

        ["\x48\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x48\x00"],
        ["\x48\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x48\x00"],

        ["\x49\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x49\x00"],
        ["\x49\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x49\x00"],

        ["\x4A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x4A\x00"],
        ["\x4A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x4A\x00"],

        ["\x4B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x4B\x00"],
        ["\x4B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x4B\x00"],

        ["\x4C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x4C\x00"],
        ["\x4C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x4C\x00"],

        ["\x4D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x4D\x00"],
        ["\x4D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x4D\x00"],

        ["\x4E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x4E\x00"],
        ["\x4E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x4E\x00"],

        ["\x4F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x4F\x00"],
        ["\x4F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x4F\x00"],

        ["\x50\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x50\x00"],
        ["\x50\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x50\x00"],

        ["\x51\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x51\x00"],
        ["\x51\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x51\x00"],

        ["\x52\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x52\x00"],
        ["\x52\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x52\x00"],

        ["\x53\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x53\x00"],
        ["\x53\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x53\x00"],

        ["\x54\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x54\x00"],
        ["\x54\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x54\x00"],

        ["\x55\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x55\x00"],
        ["\x55\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x55\x00"],

        ["\x56\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x56\x00"],
        ["\x56\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x56\x00"],

        ["\x57\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x57\x00"],
        ["\x57\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x57\x00"],

        ["\x58\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x58\x00"],
        ["\x58\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x58\x00"],

        ["\x59\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x59\x00"],
        ["\x59\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x59\x00"],

        ["\x5A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x5A\x00"],
        ["\x5A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x5A\x00"],

        ["\x5B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x5B\x00"],
        ["\x5B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x5B\x00"],

        ["\x5C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x5C\x00"],
        ["\x5C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x5C\x00"],

        ["\x5D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x5D\x00"],
        ["\x5D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x5D\x00"],

        ["\x5E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x5E\x00"],
        ["\x5E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x5E\x00"],

        ["\x5F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x5F\x00"],
        ["\x5F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x5F\x00"],

        ["\x60\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x60\x00"],
        ["\x60\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x60\x00"],

        ["\x61\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x61\x00"],
        ["\x61\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x61\x00"],

        ["\x62\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x62\x00"],
        ["\x62\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x62\x00"],

        ["\x63\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x63\x00"],
        ["\x63\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x63\x00"],

        ["\x64\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x64\x00"],
        ["\x64\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x64\x00"],

        ["\x65\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x65\x00"],
        ["\x65\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x65\x00"],

        ["\x66\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x66\x00"],
        ["\x66\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x66\x00"],

        ["\x67\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x67\x00"],
        ["\x67\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x67\x00"],

        ["\x68\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x68\x00"],
        ["\x68\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x68\x00"],

        ["\x69\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x69\x00"],
        ["\x69\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x69\x00"],

        ["\x6A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x6A\x00"],
        ["\x6A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x6A\x00"],

        ["\x6B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x6B\x00"],
        ["\x6B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x6B\x00"],

        ["\x6C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x6C\x00"],
        ["\x6C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x6C\x00"],

        ["\x6D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x6D\x00"],
        ["\x6D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x6D\x00"],

        ["\x6E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x6E\x00"],
        ["\x6E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x6E\x00"],

        ["\x6F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x6F\x00"],
        ["\x6F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x6F\x00"],

        ["\x70\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x70\x00"],
        ["\x70\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x70\x00"],

        ["\x71\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x71\x00"],
        ["\x71\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x71\x00"],

        ["\x72\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x72\x00"],
        ["\x72\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x72\x00"],

        ["\x73\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x73\x00"],
        ["\x73\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x73\x00"],

        ["\x74\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x74\x00"],
        ["\x74\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x74\x00"],

        ["\x75\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x75\x00"],
        ["\x75\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x75\x00"],

        ["\x76\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x76\x00"],
        ["\x76\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x76\x00"],

        ["\x77\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x77\x00"],
        ["\x77\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x77\x00"],

        ["\x78\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x78\x00"],
        ["\x78\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x78\x00"],

        ["\x79\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x79\x00"],
        ["\x79\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x79\x00"],

        ["\x7A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x7A\x00"],
        ["\x7A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x7A\x00"],

        ["\x7B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x7B\x00"],
        ["\x7B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x7B\x00"],

        ["\x7C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x7C\x00"],
        ["\x7C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x7C\x00"],

        ["\x7D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x7D\x00"],
        ["\x7D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x7D\x00"],

        ["\x7E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x7E\x00"],
        ["\x7E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x7E\x00"],

        ["\x7F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x7F\x00"],
        ["\x7F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\x7F\x00"],

        ["\xEE\x80\x80\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x80\x00"],
        ["\xEE\x80\x80\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x80\x00"],

        ["\xEE\x80\x81\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x81\x00"],
        ["\xEE\x80\x81\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x81\x00"],

        ["\xEE\x80\x82\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x82\x00"],
        ["\xEE\x80\x82\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x82\x00"],

        ["\xEE\x80\x83\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x83\x00"],
        ["\xEE\x80\x83\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x83\x00"],

        ["\xEE\x80\x84\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x84\x00"],
        ["\xEE\x80\x84\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x84\x00"],

        ["\xEE\x80\x85\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x85\x00"],
        ["\xEE\x80\x85\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x85\x00"],

        ["\xEE\x80\x86\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x86\x00"],
        ["\xEE\x80\x86\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x86\x00"],

        ["\xEE\x80\x87\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x87\x00"],
        ["\xEE\x80\x87\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x87\x00"],

        ["\xEE\x80\x88\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x88\x00"],
        ["\xEE\x80\x88\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x88\x00"],

        ["\xEE\x80\x89\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x89\x00"],
        ["\xEE\x80\x89\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x89\x00"],

        ["\xEE\x80\x8A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x8A\x00"],
        ["\xEE\x80\x8A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x8A\x00"],

        ["\xEE\x80\x8B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x8B\x00"],
        ["\xEE\x80\x8B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x8B\x00"],

        ["\xEE\x80\x8C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x8C\x00"],
        ["\xEE\x80\x8C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x8C\x00"],

        ["\xEE\x80\x8D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x8D\x00"],
        ["\xEE\x80\x8D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x8D\x00"],

        ["\xEE\x80\x8E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x8E\x00"],
        ["\xEE\x80\x8E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x8E\x00"],

        ["\xEE\x80\x8F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x8F\x00"],
        ["\xEE\x80\x8F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x8F\x00"],

        ["\xEE\x80\x90\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x90\x00"],
        ["\xEE\x80\x90\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x90\x00"],

        ["\xEE\x80\x91\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x91\x00"],
        ["\xEE\x80\x91\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x91\x00"],

        ["\xEE\x80\x92\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x92\x00"],
        ["\xEE\x80\x92\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x92\x00"],

        ["\xEE\x80\x93\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x93\x00"],
        ["\xEE\x80\x93\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x93\x00"],

        ["\xEE\x80\x94\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x94\x00"],
        ["\xEE\x80\x94\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x94\x00"],

        ["\xEE\x80\x95\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x95\x00"],
        ["\xEE\x80\x95\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x95\x00"],

        ["\xEE\x80\x96\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x96\x00"],
        ["\xEE\x80\x96\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x96\x00"],

        ["\xEE\x80\x97\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x97\x00"],
        ["\xEE\x80\x97\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x97\x00"],

        ["\xEE\x80\x98\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x98\x00"],
        ["\xEE\x80\x98\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x98\x00"],

        ["\xEE\x80\x99\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x99\x00"],
        ["\xEE\x80\x99\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x99\x00"],

        ["\xEE\x80\x9A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x9A\x00"],
        ["\xEE\x80\x9A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x9A\x00"],

        ["\xEE\x80\x9B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x9B\x00"],
        ["\xEE\x80\x9B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x9B\x00"],

        ["\xEE\x80\x9C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x9C\x00"],
        ["\xEE\x80\x9C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x9C\x00"],

        ["\xEE\x80\x9D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x9D\x00"],
        ["\xEE\x80\x9D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x9D\x00"],

        ["\xEE\x80\x9E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x9E\x00"],
        ["\xEE\x80\x9E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x9E\x00"],

        ["\xEE\x80\x9F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x9F\x00"],
        ["\xEE\x80\x9F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\x9F\x00"],

        ["\xEE\x80\xA0\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA0\x00"],
        ["\xEE\x80\xA0\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA0\x00"],

        ["\xEF\xBD\xA1\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA1\x00"],
        ["\xEF\xBD\xA1\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA1\x00"],

        ["\xEF\xBD\xA2\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA2\x00"],
        ["\xEF\xBD\xA2\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA2\x00"],

        ["\xEF\xBD\xA3\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA3\x00"],
        ["\xEF\xBD\xA3\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA3\x00"],

        ["\xEF\xBD\xA4\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA4\x00"],
        ["\xEF\xBD\xA4\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA4\x00"],

        ["\xEF\xBD\xA5\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA5\x00"],
        ["\xEF\xBD\xA5\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA5\x00"],

        ["\xEF\xBD\xA6\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA6\x00"],
        ["\xEF\xBD\xA6\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA6\x00"],

        ["\xEF\xBD\xA7\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA7\x00"],
        ["\xEF\xBD\xA7\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA7\x00"],

        ["\xEF\xBD\xA8\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA8\x00"],
        ["\xEF\xBD\xA8\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA8\x00"],

        ["\xEF\xBD\xA9\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA9\x00"],
        ["\xEF\xBD\xA9\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xA9\x00"],

        ["\xEF\xBD\xAA\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xAA\x00"],
        ["\xEF\xBD\xAA\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xAA\x00"],

        ["\xEF\xBD\xAB\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xAB\x00"],
        ["\xEF\xBD\xAB\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xAB\x00"],

        ["\xEF\xBD\xAC\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xAC\x00"],
        ["\xEF\xBD\xAC\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xAC\x00"],

        ["\xEF\xBD\xAD\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xAD\x00"],
        ["\xEF\xBD\xAD\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xAD\x00"],

        ["\xEF\xBD\xAE\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xAE\x00"],
        ["\xEF\xBD\xAE\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xAE\x00"],

        ["\xEF\xBD\xAF\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xAF\x00"],
        ["\xEF\xBD\xAF\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xAF\x00"],

        ["\xEF\xBD\xB0\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB0\x00"],
        ["\xEF\xBD\xB0\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB0\x00"],

        ["\xEF\xBD\xB1\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB1\x00"],
        ["\xEF\xBD\xB1\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB1\x00"],

        ["\xEF\xBD\xB2\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB2\x00"],
        ["\xEF\xBD\xB2\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB2\x00"],

        ["\xEF\xBD\xB3\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB3\x00"],
        ["\xEF\xBD\xB3\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB3\x00"],

        ["\xEF\xBD\xB4\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB4\x00"],
        ["\xEF\xBD\xB4\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB4\x00"],

        ["\xEF\xBD\xB5\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB5\x00"],
        ["\xEF\xBD\xB5\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB5\x00"],

        ["\xEF\xBD\xB6\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB6\x00"],
        ["\xEF\xBD\xB6\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB6\x00"],

        ["\xEF\xBD\xB7\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB7\x00"],
        ["\xEF\xBD\xB7\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB7\x00"],

        ["\xEF\xBD\xB8\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB8\x00"],
        ["\xEF\xBD\xB8\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB8\x00"],

        ["\xEF\xBD\xB9\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB9\x00"],
        ["\xEF\xBD\xB9\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xB9\x00"],

        ["\xEF\xBD\xBA\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xBA\x00"],
        ["\xEF\xBD\xBA\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xBA\x00"],

        ["\xEF\xBD\xBB\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xBB\x00"],
        ["\xEF\xBD\xBB\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xBB\x00"],

        ["\xEF\xBD\xBC\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xBC\x00"],
        ["\xEF\xBD\xBC\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xBC\x00"],

        ["\xEF\xBD\xBD\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xBD\x00"],
        ["\xEF\xBD\xBD\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xBD\x00"],

        ["\xEF\xBD\xBE\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xBE\x00"],
        ["\xEF\xBD\xBE\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xBE\x00"],

        ["\xEF\xBD\xBF\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xBF\x00"],
        ["\xEF\xBD\xBF\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBD\xBF\x00"],

        ["\xEF\xBE\x80\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x80\x00"],
        ["\xEF\xBE\x80\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x80\x00"],

        ["\xEF\xBE\x81\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x81\x00"],
        ["\xEF\xBE\x81\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x81\x00"],

        ["\xEF\xBE\x82\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x82\x00"],
        ["\xEF\xBE\x82\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x82\x00"],

        ["\xEF\xBE\x83\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x83\x00"],
        ["\xEF\xBE\x83\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x83\x00"],

        ["\xEF\xBE\x84\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x84\x00"],
        ["\xEF\xBE\x84\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x84\x00"],

        ["\xEF\xBE\x85\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x85\x00"],
        ["\xEF\xBE\x85\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x85\x00"],

        ["\xEF\xBE\x86\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x86\x00"],
        ["\xEF\xBE\x86\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x86\x00"],

        ["\xEF\xBE\x87\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x87\x00"],
        ["\xEF\xBE\x87\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x87\x00"],

        ["\xEF\xBE\x88\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x88\x00"],
        ["\xEF\xBE\x88\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x88\x00"],

        ["\xEF\xBE\x89\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x89\x00"],
        ["\xEF\xBE\x89\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x89\x00"],

        ["\xEF\xBE\x8A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x8A\x00"],
        ["\xEF\xBE\x8A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x8A\x00"],

        ["\xEF\xBE\x8B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x8B\x00"],
        ["\xEF\xBE\x8B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x8B\x00"],

        ["\xEF\xBE\x8C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x8C\x00"],
        ["\xEF\xBE\x8C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x8C\x00"],

        ["\xEF\xBE\x8D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x8D\x00"],
        ["\xEF\xBE\x8D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x8D\x00"],

        ["\xEF\xBE\x8E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x8E\x00"],
        ["\xEF\xBE\x8E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x8E\x00"],

        ["\xEF\xBE\x8F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x8F\x00"],
        ["\xEF\xBE\x8F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x8F\x00"],

        ["\xEF\xBE\x90\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x90\x00"],
        ["\xEF\xBE\x90\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x90\x00"],

        ["\xEF\xBE\x91\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x91\x00"],
        ["\xEF\xBE\x91\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x91\x00"],

        ["\xEF\xBE\x92\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x92\x00"],
        ["\xEF\xBE\x92\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x92\x00"],

        ["\xEF\xBE\x93\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x93\x00"],
        ["\xEF\xBE\x93\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x93\x00"],

        ["\xEF\xBE\x94\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x94\x00"],
        ["\xEF\xBE\x94\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x94\x00"],

        ["\xEF\xBE\x95\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x95\x00"],
        ["\xEF\xBE\x95\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x95\x00"],

        ["\xEF\xBE\x96\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x96\x00"],
        ["\xEF\xBE\x96\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x96\x00"],

        ["\xEF\xBE\x97\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x97\x00"],
        ["\xEF\xBE\x97\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x97\x00"],

        ["\xEF\xBE\x98\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x98\x00"],
        ["\xEF\xBE\x98\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x98\x00"],

        ["\xEF\xBE\x99\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x99\x00"],
        ["\xEF\xBE\x99\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x99\x00"],

        ["\xEF\xBE\x9A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x9A\x00"],
        ["\xEF\xBE\x9A\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x9A\x00"],

        ["\xEF\xBE\x9B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x9B\x00"],
        ["\xEF\xBE\x9B\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x9B\x00"],

        ["\xEF\xBE\x9C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x9C\x00"],
        ["\xEF\xBE\x9C\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x9C\x00"],

        ["\xEF\xBE\x9D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x9D\x00"],
        ["\xEF\xBE\x9D\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x9D\x00"],

        ["\xEF\xBE\x9E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x9E\x00"],
        ["\xEF\xBE\x9E\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x9E\x00"],

        ["\xEF\xBE\x9F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x9F\x00"],
        ["\xEF\xBE\x9F\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEF\xBE\x9F\x00"],

        ["\xEE\x80\xA1\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA1\x00"],
        ["\xEE\x80\xA1\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA1\x00"],

        ["\xEE\x80\xA2\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA2\x00"],
        ["\xEE\x80\xA2\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA2\x00"],

        ["\xEE\x80\xA3\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA3\x00"],
        ["\xEE\x80\xA3\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA3\x00"],

        ["\xEE\x80\xA4\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA4\x00"],
        ["\xEE\x80\xA4\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA4\x00"],

        ["\xEE\x80\xA5\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA5\x00"],
        ["\xEE\x80\xA5\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA5\x00"],

        ["\xEE\x80\xA6\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA6\x00"],
        ["\xEE\x80\xA6\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA6\x00"],

        ["\xEE\x80\xA7\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA7\x00"],
        ["\xEE\x80\xA7\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA7\x00"],

        ["\xEE\x80\xA8\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA8\x00"],
        ["\xEE\x80\xA8\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA8\x00"],

        ["\xEE\x80\xA9\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA9\x00"],
        ["\xEE\x80\xA9\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xA9\x00"],

        ["\xEE\x80\xAA\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xAA\x00"],
        ["\xEE\x80\xAA\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xAA\x00"],

        ["\xEE\x80\xAB\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xAB\x00"],
        ["\xEE\x80\xAB\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xAB\x00"],

        ["\xEE\x80\xAC\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xAC\x00"],
        ["\xEE\x80\xAC\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xAC\x00"],

        ["\xEE\x80\xAD\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xAD\x00"],
        ["\xEE\x80\xAD\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xAD\x00"],

        ["\xEE\x80\xAE\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xAE\x00"],
        ["\xEE\x80\xAE\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xAE\x00"],

        ["\xEE\x80\xAF\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xAF\x00"],
        ["\xEE\x80\xAF\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xAF\x00"],

        ["\xEE\x80\xB0\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB0\x00"],
        ["\xEE\x80\xB0\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB0\x00"],

        ["\xEE\x80\xB1\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB1\x00"],
        ["\xEE\x80\xB1\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB1\x00"],

        ["\xEE\x80\xB2\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB2\x00"],
        ["\xEE\x80\xB2\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB2\x00"],

        ["\xEE\x80\xB3\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB3\x00"],
        ["\xEE\x80\xB3\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB3\x00"],

        ["\xEE\x80\xB4\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB4\x00"],
        ["\xEE\x80\xB4\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB4\x00"],

        ["\xEE\x80\xB5\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB5\x00"],
        ["\xEE\x80\xB5\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB5\x00"],

        ["\xEE\x80\xB6\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB6\x00"],
        ["\xEE\x80\xB6\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB6\x00"],

        ["\xEE\x80\xB7\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB7\x00"],
        ["\xEE\x80\xB7\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB7\x00"],

        ["\xEE\x80\xB8\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB8\x00"],
        ["\xEE\x80\xB8\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB8\x00"],

        ["\xEE\x80\xB9\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB9\x00"],
        ["\xEE\x80\xB9\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xB9\x00"],

        ["\xEE\x80\xBA\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xBA\x00"],
        ["\xEE\x80\xBA\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xBA\x00"],

        ["\xEE\x80\xBB\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xBB\x00"],
        ["\xEE\x80\xBB\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xBB\x00"],

        ["\xEE\x80\xBC\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xBC\x00"],
        ["\xEE\x80\xBC\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xBC\x00"],

        ["\xEE\x80\xBD\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xBD\x00"],
        ["\xEE\x80\xBD\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xBD\x00"],

        ["\xEE\x80\xBE\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xBE\x00"],
        ["\xEE\x80\xBE\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xBE\x00"],

        ["\xEE\x80\xBF\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xBF\x00"],
        ["\xEE\x80\xBF\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x80\xBF\x00"],

        ["\xEE\x81\x80\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x81\x80\x00"],
        ["\xEE\x81\x80\x00",'utf8.1','utf8.1',{'INPUT_LAYOUT'=>'SS'},"\xEE\x81\x80\x00"],

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
