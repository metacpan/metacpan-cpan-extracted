######################################################################
#
# 0020_cp932_multicoded_test.t
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use vars qw(@test);
    @test = (
        ["\x81\xE6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xE6"],
        ["\x87\x9A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xE6"],
        ["\xFA\x5B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xE6"],

        ["\x81\xCA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xCA"],
        ["\xEE\xF9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xCA"],
        ["\xFA\x54",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xCA"],

        ["\x81\xE0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xE0"],
        ["\x87\x90",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xE0"],

        ["\x81\xDF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xDF"],
        ["\x87\x91",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xDF"],

        ["\x81\xE7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xE7"],
        ["\x87\x92",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xE7"],

        ["\x81\xE3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xE3"],
        ["\x87\x95",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xE3"],

        ["\x81\xDB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xDB"],
        ["\x87\x96",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xDB"],

        ["\x81\xDA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xDA"],
        ["\x87\x97",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xDA"],

        ["\x81\xBF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xBF"],
        ["\x87\x9B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xBF"],

        ["\x81\xBE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xBE"],
        ["\x87\x9C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xBE"],

        ["\x87\x54",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x54"],
        ["\xFA\x4A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x54"],

        ["\x87\x55",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x55"],
        ["\xFA\x4B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x55"],

        ["\x87\x56",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x56"],
        ["\xFA\x4C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x56"],

        ["\x87\x57",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x57"],
        ["\xFA\x4D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x57"],

        ["\x87\x58",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x58"],
        ["\xFA\x4E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x58"],

        ["\x87\x59",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x59"],
        ["\xFA\x4F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x59"],

        ["\x87\x5A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x5A"],
        ["\xFA\x50",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x5A"],

        ["\x87\x5B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x5B"],
        ["\xFA\x51",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x5B"],

        ["\x87\x5C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x5C"],
        ["\xFA\x52",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x5C"],

        ["\x87\x5D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x5D"],
        ["\xFA\x53",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x5D"],

        ["\x87\x82",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x82"],
        ["\xFA\x59",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x82"],

        ["\x87\x84",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x84"],
        ["\xFA\x5A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x84"],

        ["\x87\x8A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x8A"],
        ["\xFA\x58",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\x87\x8A"],

        ["\xEE\xEF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x40"],
        ["\xFA\x40",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x40"],

        ["\xEE\xF0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x41"],
        ["\xFA\x41",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x41"],

        ["\xEE\xF1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x42"],
        ["\xFA\x42",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x42"],

        ["\xEE\xF2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x43"],
        ["\xFA\x43",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x43"],

        ["\xEE\xF3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x44"],
        ["\xFA\x44",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x44"],

        ["\xEE\xF4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x45"],
        ["\xFA\x45",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x45"],

        ["\xEE\xF5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x46"],
        ["\xFA\x46",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x46"],

        ["\xEE\xF6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x47"],
        ["\xFA\x47",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x47"],

        ["\xEE\xF7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x48"],
        ["\xFA\x48",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x48"],

        ["\xEE\xF8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x49"],
        ["\xFA\x49",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x49"],

        ["\xEE\xFA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x55"],
        ["\xFA\x55",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x55"],

        ["\xEE\xFB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x56"],
        ["\xFA\x56",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x56"],

        ["\xEE\xFC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x57"],
        ["\xFA\x57",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x57"],

        ["\xED\x40",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x5C"],
        ["\xFA\x5C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x5C"],

        ["\xED\x41",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x5D"],
        ["\xFA\x5D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x5D"],

        ["\xED\x42",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x5E"],
        ["\xFA\x5E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x5E"],

        ["\xED\x43",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x5F"],
        ["\xFA\x5F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x5F"],

        ["\xED\x44",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x60"],
        ["\xFA\x60",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x60"],

        ["\xED\x45",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x61"],
        ["\xFA\x61",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x61"],

        ["\xED\x46",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x62"],
        ["\xFA\x62",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x62"],

        ["\xED\x47",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x63"],
        ["\xFA\x63",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x63"],

        ["\xED\x48",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x64"],
        ["\xFA\x64",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x64"],

        ["\xED\x49",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x65"],
        ["\xFA\x65",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x65"],

        ["\xED\x4A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x66"],
        ["\xFA\x66",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x66"],

        ["\xED\x4B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x67"],
        ["\xFA\x67",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x67"],

        ["\xED\x4C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x68"],
        ["\xFA\x68",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x68"],

        ["\xED\x4D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x69"],
        ["\xFA\x69",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x69"],

        ["\xED\x4E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x6A"],
        ["\xFA\x6A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x6A"],

        ["\xED\x4F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x6B"],
        ["\xFA\x6B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x6B"],

        ["\xED\x50",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x6C"],
        ["\xFA\x6C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x6C"],

        ["\xED\x51",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x6D"],
        ["\xFA\x6D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x6D"],

        ["\xED\x52",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x6E"],
        ["\xFA\x6E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x6E"],

        ["\xED\x53",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x6F"],
        ["\xFA\x6F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x6F"],

        ["\xED\x54",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x70"],
        ["\xFA\x70",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x70"],

        ["\xED\x55",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x71"],
        ["\xFA\x71",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x71"],

        ["\xED\x56",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x72"],
        ["\xFA\x72",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x72"],

        ["\xED\x57",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x73"],
        ["\xFA\x73",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x73"],

        ["\xED\x58",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x74"],
        ["\xFA\x74",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x74"],

        ["\xED\x59",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x75"],
        ["\xFA\x75",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x75"],

        ["\xED\x5A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x76"],
        ["\xFA\x76",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x76"],

        ["\xED\x5B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x77"],
        ["\xFA\x77",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x77"],

        ["\xED\x5C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x78"],
        ["\xFA\x78",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x78"],

        ["\xED\x5D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x79"],
        ["\xFA\x79",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x79"],

        ["\xED\x5E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x7A"],
        ["\xFA\x7A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x7A"],

        ["\xED\x5F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x7B"],
        ["\xFA\x7B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x7B"],

        ["\xED\x60",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x7C"],
        ["\xFA\x7C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x7C"],

        ["\xED\x61",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x7D"],
        ["\xFA\x7D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x7D"],

        ["\xED\x62",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x7E"],
        ["\xFA\x7E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x7E"],

        ["\xED\x63",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x80"],
        ["\xFA\x80",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x80"],

        ["\xED\x64",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x81"],
        ["\xFA\x81",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x81"],

        ["\xED\x65",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x82"],
        ["\xFA\x82",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x82"],

        ["\xED\x66",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x83"],
        ["\xFA\x83",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x83"],

        ["\xED\x67",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x84"],
        ["\xFA\x84",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x84"],

        ["\xED\x68",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x85"],
        ["\xFA\x85",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x85"],

        ["\xED\x69",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x86"],
        ["\xFA\x86",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x86"],

        ["\xED\x6A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x87"],
        ["\xFA\x87",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x87"],

        ["\xED\x6B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x88"],
        ["\xFA\x88",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x88"],

        ["\xED\x6C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x89"],
        ["\xFA\x89",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x89"],

        ["\xED\x6D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x8A"],
        ["\xFA\x8A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x8A"],

        ["\xED\x6E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x8B"],
        ["\xFA\x8B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x8B"],

        ["\xED\x6F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x8C"],
        ["\xFA\x8C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x8C"],

        ["\xED\x70",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x8D"],
        ["\xFA\x8D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x8D"],

        ["\xED\x71",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x8E"],
        ["\xFA\x8E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x8E"],

        ["\xED\x72",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x8F"],
        ["\xFA\x8F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x8F"],

        ["\xED\x73",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x90"],
        ["\xFA\x90",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x90"],

        ["\xED\x74",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x91"],
        ["\xFA\x91",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x91"],

        ["\xED\x75",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x92"],
        ["\xFA\x92",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x92"],

        ["\xED\x76",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x93"],
        ["\xFA\x93",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x93"],

        ["\xED\x77",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x94"],
        ["\xFA\x94",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x94"],

        ["\xED\x78",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x95"],
        ["\xFA\x95",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x95"],

        ["\xED\x79",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x96"],
        ["\xFA\x96",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x96"],

        ["\xED\x7A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x97"],
        ["\xFA\x97",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x97"],

        ["\xED\x7B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x98"],
        ["\xFA\x98",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x98"],

        ["\xED\x7C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x99"],
        ["\xFA\x99",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x99"],

        ["\xED\x7D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x9A"],
        ["\xFA\x9A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x9A"],

        ["\xED\x7E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x9B"],
        ["\xFA\x9B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x9B"],

        ["\xED\x80",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x9C"],
        ["\xFA\x9C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x9C"],

        ["\xED\x81",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x9D"],
        ["\xFA\x9D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x9D"],

        ["\xED\x82",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x9E"],
        ["\xFA\x9E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x9E"],

        ["\xED\x83",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x9F"],
        ["\xFA\x9F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\x9F"],

        ["\xED\x84",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA0"],
        ["\xFA\xA0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA0"],

        ["\xED\x85",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA1"],
        ["\xFA\xA1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA1"],

        ["\xED\x86",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA2"],
        ["\xFA\xA2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA2"],

        ["\xED\x87",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA3"],
        ["\xFA\xA3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA3"],

        ["\xED\x88",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA4"],
        ["\xFA\xA4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA4"],

        ["\xED\x89",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA5"],
        ["\xFA\xA5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA5"],

        ["\xED\x8A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA6"],
        ["\xFA\xA6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA6"],

        ["\xED\x8B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA7"],
        ["\xFA\xA7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA7"],

        ["\xED\x8C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA8"],
        ["\xFA\xA8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA8"],

        ["\xED\x8D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA9"],
        ["\xFA\xA9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xA9"],

        ["\xED\x8E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xAA"],
        ["\xFA\xAA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xAA"],

        ["\xED\x8F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xAB"],
        ["\xFA\xAB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xAB"],

        ["\xED\x90",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xAC"],
        ["\xFA\xAC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xAC"],

        ["\xED\x91",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xAD"],
        ["\xFA\xAD",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xAD"],

        ["\xED\x92",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xAE"],
        ["\xFA\xAE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xAE"],

        ["\xED\x93",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xAF"],
        ["\xFA\xAF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xAF"],

        ["\xED\x94",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB0"],
        ["\xFA\xB0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB0"],

        ["\xED\x95",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB1"],
        ["\xFA\xB1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB1"],

        ["\xED\x96",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB2"],
        ["\xFA\xB2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB2"],

        ["\xED\x97",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB3"],
        ["\xFA\xB3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB3"],

        ["\xED\x98",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB4"],
        ["\xFA\xB4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB4"],

        ["\xED\x99",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB5"],
        ["\xFA\xB5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB5"],

        ["\xED\x9A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB6"],
        ["\xFA\xB6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB6"],

        ["\xED\x9B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB7"],
        ["\xFA\xB7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB7"],

        ["\xED\x9C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB8"],
        ["\xFA\xB8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB8"],

        ["\xED\x9D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB9"],
        ["\xFA\xB9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xB9"],

        ["\xED\x9E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xBA"],
        ["\xFA\xBA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xBA"],

        ["\xED\x9F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xBB"],
        ["\xFA\xBB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xBB"],

        ["\xED\xA0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xBC"],
        ["\xFA\xBC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xBC"],

        ["\xED\xA1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xBD"],
        ["\xFA\xBD",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xBD"],

        ["\xED\xA2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xBE"],
        ["\xFA\xBE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xBE"],

        ["\xED\xA3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xBF"],
        ["\xFA\xBF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xBF"],

        ["\xED\xA4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC0"],
        ["\xFA\xC0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC0"],

        ["\xED\xA5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC1"],
        ["\xFA\xC1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC1"],

        ["\xED\xA6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC2"],
        ["\xFA\xC2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC2"],

        ["\xED\xA7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC3"],
        ["\xFA\xC3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC3"],

        ["\xED\xA8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC4"],
        ["\xFA\xC4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC4"],

        ["\xED\xA9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC5"],
        ["\xFA\xC5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC5"],

        ["\xED\xAA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC6"],
        ["\xFA\xC6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC6"],

        ["\xED\xAB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC7"],
        ["\xFA\xC7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC7"],

        ["\xED\xAC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC8"],
        ["\xFA\xC8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC8"],

        ["\xED\xAD",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC9"],
        ["\xFA\xC9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xC9"],

        ["\xED\xAE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xCA"],
        ["\xFA\xCA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xCA"],

        ["\xED\xAF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xCB"],
        ["\xFA\xCB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xCB"],

        ["\xED\xB0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xCC"],
        ["\xFA\xCC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xCC"],

        ["\xED\xB1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xCD"],
        ["\xFA\xCD",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xCD"],

        ["\xED\xB2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xCE"],
        ["\xFA\xCE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xCE"],

        ["\xED\xB3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xCF"],
        ["\xFA\xCF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xCF"],

        ["\xED\xB4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD0"],
        ["\xFA\xD0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD0"],

        ["\xED\xB5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD1"],
        ["\xFA\xD1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD1"],

        ["\xED\xB6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD2"],
        ["\xFA\xD2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD2"],

        ["\xED\xB7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD3"],
        ["\xFA\xD3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD3"],

        ["\xED\xB8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD4"],
        ["\xFA\xD4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD4"],

        ["\xED\xB9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD5"],
        ["\xFA\xD5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD5"],

        ["\xED\xBA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD6"],
        ["\xFA\xD6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD6"],

        ["\xED\xBB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD7"],
        ["\xFA\xD7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD7"],

        ["\xED\xBC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD8"],
        ["\xFA\xD8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD8"],

        ["\xED\xBD",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD9"],
        ["\xFA\xD9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xD9"],

        ["\xED\xBE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xDA"],
        ["\xFA\xDA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xDA"],

        ["\xED\xBF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xDB"],
        ["\xFA\xDB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xDB"],

        ["\xED\xC0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xDC"],
        ["\xFA\xDC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xDC"],

        ["\xED\xC1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xDD"],
        ["\xFA\xDD",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xDD"],

        ["\xED\xC2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xDE"],
        ["\xFA\xDE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xDE"],

        ["\xED\xC3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xDF"],
        ["\xFA\xDF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xDF"],

        ["\xED\xC4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE0"],
        ["\xFA\xE0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE0"],

        ["\xED\xC5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE1"],
        ["\xFA\xE1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE1"],

        ["\xED\xC6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE2"],
        ["\xFA\xE2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE2"],

        ["\xED\xC7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE3"],
        ["\xFA\xE3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE3"],

        ["\xED\xC8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE4"],
        ["\xFA\xE4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE4"],

        ["\xED\xC9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE5"],
        ["\xFA\xE5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE5"],

        ["\xED\xCA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE6"],
        ["\xFA\xE6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE6"],

        ["\xED\xCB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE7"],
        ["\xFA\xE7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE7"],

        ["\xED\xCC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE8"],
        ["\xFA\xE8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE8"],

        ["\xED\xCD",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE9"],
        ["\xFA\xE9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xE9"],

        ["\xED\xCE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xEA"],
        ["\xFA\xEA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xEA"],

        ["\xED\xCF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xEB"],
        ["\xFA\xEB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xEB"],

        ["\xED\xD0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xEC"],
        ["\xFA\xEC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xEC"],

        ["\xED\xD1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xED"],
        ["\xFA\xED",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xED"],

        ["\xED\xD2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xEE"],
        ["\xFA\xEE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xEE"],

        ["\xED\xD3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xEF"],
        ["\xFA\xEF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xEF"],

        ["\xED\xD4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF0"],
        ["\xFA\xF0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF0"],

        ["\xED\xD5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF1"],
        ["\xFA\xF1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF1"],

        ["\xED\xD6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF2"],
        ["\xFA\xF2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF2"],

        ["\xED\xD7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF3"],
        ["\xFA\xF3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF3"],

        ["\xED\xD8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF4"],
        ["\xFA\xF4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF4"],

        ["\xED\xD9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF5"],
        ["\xFA\xF5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF5"],

        ["\xED\xDA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF6"],
        ["\xFA\xF6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF6"],

        ["\xED\xDB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF7"],
        ["\xFA\xF7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF7"],

        ["\xED\xDC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF8"],
        ["\xFA\xF8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF8"],

        ["\xED\xDD",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF9"],
        ["\xFA\xF9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xF9"],

        ["\xED\xDE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xFA"],
        ["\xFA\xFA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xFA"],

        ["\xED\xDF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xFB"],
        ["\xFA\xFB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xFB"],

        ["\xED\xE0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xFC"],
        ["\xFA\xFC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFA\xFC"],

        ["\xED\xE1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x40"],
        ["\xFB\x40",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x40"],

        ["\xED\xE2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x41"],
        ["\xFB\x41",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x41"],

        ["\xED\xE3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x42"],
        ["\xFB\x42",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x42"],

        ["\xED\xE4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x43"],
        ["\xFB\x43",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x43"],

        ["\xED\xE5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x44"],
        ["\xFB\x44",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x44"],

        ["\xED\xE6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x45"],
        ["\xFB\x45",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x45"],

        ["\xED\xE7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x46"],
        ["\xFB\x46",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x46"],

        ["\xED\xE8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x47"],
        ["\xFB\x47",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x47"],

        ["\xED\xE9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x48"],
        ["\xFB\x48",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x48"],

        ["\xED\xEA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x49"],
        ["\xFB\x49",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x49"],

        ["\xED\xEB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x4A"],
        ["\xFB\x4A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x4A"],

        ["\xED\xEC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x4B"],
        ["\xFB\x4B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x4B"],

        ["\xED\xED",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x4C"],
        ["\xFB\x4C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x4C"],

        ["\xED\xEE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x4D"],
        ["\xFB\x4D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x4D"],

        ["\xED\xEF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x4E"],
        ["\xFB\x4E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x4E"],

        ["\xED\xF0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x4F"],
        ["\xFB\x4F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x4F"],

        ["\xED\xF1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x50"],
        ["\xFB\x50",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x50"],

        ["\xED\xF2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x51"],
        ["\xFB\x51",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x51"],

        ["\xED\xF3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x52"],
        ["\xFB\x52",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x52"],

        ["\xED\xF4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x53"],
        ["\xFB\x53",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x53"],

        ["\xED\xF5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x54"],
        ["\xFB\x54",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x54"],

        ["\xED\xF6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x55"],
        ["\xFB\x55",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x55"],

        ["\xED\xF7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x56"],
        ["\xFB\x56",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x56"],

        ["\xED\xF8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x57"],
        ["\xFB\x57",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x57"],

        ["\xED\xF9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x58"],
        ["\xFB\x58",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x58"],

        ["\xED\xFA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x59"],
        ["\xFB\x59",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x59"],

        ["\xED\xFB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x5A"],
        ["\xFB\x5A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x5A"],

        ["\xED\xFC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x5B"],
        ["\xFB\x5B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x5B"],

        ["\xEE\x40",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x5C"],
        ["\xFB\x5C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x5C"],

        ["\xEE\x41",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x5D"],
        ["\xFB\x5D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x5D"],

        ["\xEE\x42",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x5E"],
        ["\xFB\x5E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x5E"],

        ["\xEE\x43",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x5F"],
        ["\xFB\x5F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x5F"],

        ["\xEE\x44",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x60"],
        ["\xFB\x60",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x60"],

        ["\xEE\x45",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x61"],
        ["\xFB\x61",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x61"],

        ["\xEE\x46",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x62"],
        ["\xFB\x62",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x62"],

        ["\xEE\x47",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x63"],
        ["\xFB\x63",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x63"],

        ["\xEE\x48",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x64"],
        ["\xFB\x64",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x64"],

        ["\xEE\x49",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x65"],
        ["\xFB\x65",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x65"],

        ["\xEE\x4A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x66"],
        ["\xFB\x66",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x66"],

        ["\xEE\x4B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x67"],
        ["\xFB\x67",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x67"],

        ["\xEE\x4C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x68"],
        ["\xFB\x68",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x68"],

        ["\xEE\x4D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x69"],
        ["\xFB\x69",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x69"],

        ["\xEE\x4E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x6A"],
        ["\xFB\x6A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x6A"],

        ["\xEE\x4F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x6B"],
        ["\xFB\x6B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x6B"],

        ["\xEE\x50",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x6C"],
        ["\xFB\x6C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x6C"],

        ["\xEE\x51",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x6D"],
        ["\xFB\x6D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x6D"],

        ["\xEE\x52",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x6E"],
        ["\xFB\x6E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x6E"],

        ["\xEE\x53",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x6F"],
        ["\xFB\x6F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x6F"],

        ["\xEE\x54",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x70"],
        ["\xFB\x70",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x70"],

        ["\xEE\x55",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x71"],
        ["\xFB\x71",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x71"],

        ["\xEE\x56",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x72"],
        ["\xFB\x72",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x72"],

        ["\xEE\x57",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x73"],
        ["\xFB\x73",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x73"],

        ["\xEE\x58",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x74"],
        ["\xFB\x74",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x74"],

        ["\xEE\x59",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x75"],
        ["\xFB\x75",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x75"],

        ["\xEE\x5A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x76"],
        ["\xFB\x76",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x76"],

        ["\xEE\x5B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x77"],
        ["\xFB\x77",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x77"],

        ["\xEE\x5C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x78"],
        ["\xFB\x78",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x78"],

        ["\xEE\x5D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x79"],
        ["\xFB\x79",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x79"],

        ["\xEE\x5E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x7A"],
        ["\xFB\x7A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x7A"],

        ["\xEE\x5F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x7B"],
        ["\xFB\x7B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x7B"],

        ["\xEE\x60",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x7C"],
        ["\xFB\x7C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x7C"],

        ["\xEE\x61",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x7D"],
        ["\xFB\x7D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x7D"],

        ["\xEE\x62",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x7E"],
        ["\xFB\x7E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x7E"],

        ["\xEE\x63",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x80"],
        ["\xFB\x80",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x80"],

        ["\xEE\x64",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x81"],
        ["\xFB\x81",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x81"],

        ["\xEE\x65",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x82"],
        ["\xFB\x82",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x82"],

        ["\xEE\x66",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x83"],
        ["\xFB\x83",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x83"],

        ["\xEE\x67",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x84"],
        ["\xFB\x84",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x84"],

        ["\xEE\x68",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x85"],
        ["\xFB\x85",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x85"],

        ["\xEE\x69",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x86"],
        ["\xFB\x86",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x86"],

        ["\xEE\x6A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x87"],
        ["\xFB\x87",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x87"],

        ["\xEE\x6B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x88"],
        ["\xFB\x88",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x88"],

        ["\xEE\x6C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x89"],
        ["\xFB\x89",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x89"],

        ["\xEE\x6D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x8A"],
        ["\xFB\x8A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x8A"],

        ["\xEE\x6E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x8B"],
        ["\xFB\x8B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x8B"],

        ["\xEE\x6F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x8C"],
        ["\xFB\x8C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x8C"],

        ["\xEE\x70",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x8D"],
        ["\xFB\x8D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x8D"],

        ["\xEE\x71",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x8E"],
        ["\xFB\x8E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x8E"],

        ["\xEE\x72",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x8F"],
        ["\xFB\x8F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x8F"],

        ["\xEE\x73",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x90"],
        ["\xFB\x90",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x90"],

        ["\xEE\x74",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x91"],
        ["\xFB\x91",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x91"],

        ["\xEE\x75",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x92"],
        ["\xFB\x92",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x92"],

        ["\xEE\x76",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x93"],
        ["\xFB\x93",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x93"],

        ["\xEE\x77",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x94"],
        ["\xFB\x94",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x94"],

        ["\xEE\x78",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x95"],
        ["\xFB\x95",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x95"],

        ["\xEE\x79",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x96"],
        ["\xFB\x96",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x96"],

        ["\xEE\x7A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x97"],
        ["\xFB\x97",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x97"],

        ["\xEE\x7B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x98"],
        ["\xFB\x98",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x98"],

        ["\xEE\x7C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x99"],
        ["\xFB\x99",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x99"],

        ["\xEE\x7D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x9A"],
        ["\xFB\x9A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x9A"],

        ["\xEE\x7E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x9B"],
        ["\xFB\x9B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x9B"],

        ["\xEE\x80",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x9C"],
        ["\xFB\x9C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x9C"],

        ["\xEE\x81",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x9D"],
        ["\xFB\x9D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x9D"],

        ["\xEE\x82",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x9E"],
        ["\xFB\x9E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x9E"],

        ["\xEE\x83",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x9F"],
        ["\xFB\x9F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\x9F"],

        ["\xEE\x84",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA0"],
        ["\xFB\xA0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA0"],

        ["\xEE\x85",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA1"],
        ["\xFB\xA1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA1"],

        ["\xEE\x86",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA2"],
        ["\xFB\xA2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA2"],

        ["\xEE\x87",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA3"],
        ["\xFB\xA3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA3"],

        ["\xEE\x88",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA4"],
        ["\xFB\xA4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA4"],

        ["\xEE\x89",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA5"],
        ["\xFB\xA5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA5"],

        ["\xEE\x8A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA6"],
        ["\xFB\xA6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA6"],

        ["\xEE\x8B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA7"],
        ["\xFB\xA7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA7"],

        ["\xEE\x8C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA8"],
        ["\xFB\xA8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA8"],

        ["\xEE\x8D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA9"],
        ["\xFB\xA9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xA9"],

        ["\xEE\x8E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xAA"],
        ["\xFB\xAA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xAA"],

        ["\xEE\x8F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xAB"],
        ["\xFB\xAB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xAB"],

        ["\xEE\x90",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xAC"],
        ["\xFB\xAC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xAC"],

        ["\xEE\x91",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xAD"],
        ["\xFB\xAD",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xAD"],

        ["\xEE\x92",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xAE"],
        ["\xFB\xAE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xAE"],

        ["\xEE\x93",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xAF"],
        ["\xFB\xAF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xAF"],

        ["\xEE\x94",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB0"],
        ["\xFB\xB0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB0"],

        ["\xEE\x95",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB1"],
        ["\xFB\xB1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB1"],

        ["\xEE\x96",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB2"],
        ["\xFB\xB2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB2"],

        ["\xEE\x97",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB3"],
        ["\xFB\xB3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB3"],

        ["\xEE\x98",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB4"],
        ["\xFB\xB4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB4"],

        ["\xEE\x99",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB5"],
        ["\xFB\xB5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB5"],

        ["\xEE\x9A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB6"],
        ["\xFB\xB6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB6"],

        ["\xEE\x9B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB7"],
        ["\xFB\xB7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB7"],

        ["\xEE\x9C",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB8"],
        ["\xFB\xB8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB8"],

        ["\xEE\x9D",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB9"],
        ["\xFB\xB9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xB9"],

        ["\xEE\x9E",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xBA"],
        ["\xFB\xBA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xBA"],

        ["\xEE\x9F",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xBB"],
        ["\xFB\xBB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xBB"],

        ["\xEE\xA0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xBC"],
        ["\xFB\xBC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xBC"],

        ["\xEE\xA1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xBD"],
        ["\xFB\xBD",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xBD"],

        ["\xEE\xA2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xBE"],
        ["\xFB\xBE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xBE"],

        ["\xEE\xA3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xBF"],
        ["\xFB\xBF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xBF"],

        ["\xEE\xA4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC0"],
        ["\xFB\xC0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC0"],

        ["\xEE\xA5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC1"],
        ["\xFB\xC1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC1"],

        ["\xEE\xA6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC2"],
        ["\xFB\xC2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC2"],

        ["\xEE\xA7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC3"],
        ["\xFB\xC3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC3"],

        ["\xEE\xA8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC4"],
        ["\xFB\xC4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC4"],

        ["\xEE\xA9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC5"],
        ["\xFB\xC5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC5"],

        ["\xEE\xAA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC6"],
        ["\xFB\xC6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC6"],

        ["\xEE\xAB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC7"],
        ["\xFB\xC7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC7"],

        ["\xEE\xAC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC8"],
        ["\xFB\xC8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC8"],

        ["\xEE\xAD",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC9"],
        ["\xFB\xC9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xC9"],

        ["\xEE\xAE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xCA"],
        ["\xFB\xCA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xCA"],

        ["\xEE\xAF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xCB"],
        ["\xFB\xCB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xCB"],

        ["\xEE\xB0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xCC"],
        ["\xFB\xCC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xCC"],

        ["\xEE\xB1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xCD"],
        ["\xFB\xCD",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xCD"],

        ["\xEE\xB2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xCE"],
        ["\xFB\xCE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xCE"],

        ["\xEE\xB3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xCF"],
        ["\xFB\xCF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xCF"],

        ["\xEE\xB4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD0"],
        ["\xFB\xD0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD0"],

        ["\xEE\xB5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD1"],
        ["\xFB\xD1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD1"],

        ["\xEE\xB6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD2"],
        ["\xFB\xD2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD2"],

        ["\xEE\xB7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD3"],
        ["\xFB\xD3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD3"],

        ["\xEE\xB8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD4"],
        ["\xFB\xD4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD4"],

        ["\xEE\xB9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD5"],
        ["\xFB\xD5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD5"],

        ["\xEE\xBA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD6"],
        ["\xFB\xD6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD6"],

        ["\xEE\xBB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD7"],
        ["\xFB\xD7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD7"],

        ["\xEE\xBC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD8"],
        ["\xFB\xD8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD8"],

        ["\xEE\xBD",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD9"],
        ["\xFB\xD9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xD9"],

        ["\xEE\xBE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xDA"],
        ["\xFB\xDA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xDA"],

        ["\xEE\xBF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xDB"],
        ["\xFB\xDB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xDB"],

        ["\xEE\xC0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xDC"],
        ["\xFB\xDC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xDC"],

        ["\xEE\xC1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xDD"],
        ["\xFB\xDD",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xDD"],

        ["\xEE\xC2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xDE"],
        ["\xFB\xDE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xDE"],

        ["\xEE\xC3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xDF"],
        ["\xFB\xDF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xDF"],

        ["\xEE\xC4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE0"],
        ["\xFB\xE0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE0"],

        ["\xEE\xC5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE1"],
        ["\xFB\xE1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE1"],

        ["\xEE\xC6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE2"],
        ["\xFB\xE2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE2"],

        ["\xEE\xC7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE3"],
        ["\xFB\xE3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE3"],

        ["\xEE\xC8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE4"],
        ["\xFB\xE4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE4"],

        ["\xEE\xC9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE5"],
        ["\xFB\xE5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE5"],

        ["\xEE\xCA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE6"],
        ["\xFB\xE6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE6"],

        ["\xEE\xCB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE7"],
        ["\xFB\xE7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE7"],

        ["\xEE\xCC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE8"],
        ["\xFB\xE8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE8"],

        ["\xEE\xCD",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE9"],
        ["\xFB\xE9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xE9"],

        ["\xEE\xCE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xEA"],
        ["\xFB\xEA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xEA"],

        ["\xEE\xCF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xEB"],
        ["\xFB\xEB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xEB"],

        ["\xEE\xD0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xEC"],
        ["\xFB\xEC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xEC"],

        ["\xEE\xD1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xED"],
        ["\xFB\xED",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xED"],

        ["\xEE\xD2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xEE"],
        ["\xFB\xEE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xEE"],

        ["\xEE\xD3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xEF"],
        ["\xFB\xEF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xEF"],

        ["\xEE\xD4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF0"],
        ["\xFB\xF0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF0"],

        ["\xEE\xD5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF1"],
        ["\xFB\xF1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF1"],

        ["\xEE\xD6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF2"],
        ["\xFB\xF2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF2"],

        ["\xEE\xD7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF3"],
        ["\xFB\xF3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF3"],

        ["\xEE\xD8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF4"],
        ["\xFB\xF4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF4"],

        ["\xEE\xD9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF5"],
        ["\xFB\xF5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF5"],

        ["\xEE\xDA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF6"],
        ["\xFB\xF6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF6"],

        ["\xEE\xDB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF7"],
        ["\xFB\xF7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF7"],

        ["\xEE\xDC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF8"],
        ["\xFB\xF8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF8"],

        ["\xEE\xDD",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF9"],
        ["\xFB\xF9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xF9"],

        ["\xEE\xDE",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xFA"],
        ["\xFB\xFA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xFA"],

        ["\xEE\xDF",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xFB"],
        ["\xFB\xFB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xFB"],

        ["\xEE\xE0",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xFC"],
        ["\xFB\xFC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFB\xFC"],

        ["\xEE\xE1",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x40"],
        ["\xFC\x40",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x40"],

        ["\xEE\xE2",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x41"],
        ["\xFC\x41",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x41"],

        ["\xEE\xE3",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x42"],
        ["\xFC\x42",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x42"],

        ["\xEE\xE4",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x43"],
        ["\xFC\x43",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x43"],

        ["\xEE\xE5",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x44"],
        ["\xFC\x44",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x44"],

        ["\xEE\xE6",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x45"],
        ["\xFC\x45",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x45"],

        ["\xEE\xE7",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x46"],
        ["\xFC\x46",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x46"],

        ["\xEE\xE8",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x47"],
        ["\xFC\x47",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x47"],

        ["\xEE\xE9",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x48"],
        ["\xFC\x48",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x48"],

        ["\xEE\xEA",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x49"],
        ["\xFC\x49",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x49"],

        ["\xEE\xEB",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x4A"],
        ["\xFC\x4A",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x4A"],

        ["\xEE\xEC",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x4B"],
        ["\xFC\x4B",'cp932x','cp932x',{'INPUT_LAYOUT'=>'D'},"\xFC\x4B"],
    );
    $|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }
}

use Jacode4e;

for my $test (@test) {
    my($give,$OUTPUT_encoding,$INPUT_encoding,$option,$want) = @{$test};
    my $got = $give;
    my $return = Jacode4e::convert(\$got,$OUTPUT_encoding,$INPUT_encoding,$option);

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
