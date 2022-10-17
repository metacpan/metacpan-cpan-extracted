######################################################################
#
# t/6001_getcode_1oct.t
#
# Copyright (c) 2022 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

sub BEGIN {
    eval q<
        use FindBin;
        use lib "$FindBin::Bin/..";
    >;
}
require 'lib/jacode.pl';

@todo = (
    ("\x00",''),("\x01",''),("\x02",''),("\x03",''),("\x04",''),("\x05",''),("\x06",''),("\x07",''),("\x08",''),("\x09",''),("\x0a",''),("\x0b",''),("\x0c",''),("\x0d",''),("\x0e",''),("\x0f",''),
    ("\x10",''),("\x11",''),("\x12",''),("\x13",''),("\x14",''),("\x15",''),("\x16",''),("\x17",''),("\x18",''),("\x19",''),("\x1a",''),("\x1b",''),("\x1c",''),("\x1d",''),("\x1e",''),("\x1f",''),
    ("\x20",''),("\x21",''),("\x22",''),("\x23",''),("\x24",''),("\x25",''),("\x26",''),("\x27",''),("\x28",''),("\x29",''),("\x2a",''),("\x2b",''),("\x2c",''),("\x2d",''),("\x2e",''),("\x2f",''),
    ("\x30",''),("\x31",''),("\x32",''),("\x33",''),("\x34",''),("\x35",''),("\x36",''),("\x37",''),("\x38",''),("\x39",''),("\x3a",''),("\x3b",''),("\x3c",''),("\x3d",''),("\x3e",''),("\x3f",''),
    ("\x40",''),("\x41",''),("\x42",''),("\x43",''),("\x44",''),("\x45",''),("\x46",''),("\x47",''),("\x48",''),("\x49",''),("\x4a",''),("\x4b",''),("\x4c",''),("\x4d",''),("\x4e",''),("\x4f",''),
    ("\x50",''),("\x51",''),("\x52",''),("\x53",''),("\x54",''),("\x55",''),("\x56",''),("\x57",''),("\x58",''),("\x59",''),("\x5a",''),("\x5b",''),("\x5c",''),("\x5d",''),("\x5e",''),("\x5f",''),
    ("\x60",''),("\x61",''),("\x62",''),("\x63",''),("\x64",''),("\x65",''),("\x66",''),("\x67",''),("\x68",''),("\x69",''),("\x6a",''),("\x6b",''),("\x6c",''),("\x6d",''),("\x6e",''),("\x6f",''),
    ("\x70",''),("\x71",''),("\x72",''),("\x73",''),("\x74",''),("\x75",''),("\x76",''),("\x77",''),("\x78",''),("\x79",''),("\x7a",''),("\x7b",''),("\x7c",''),("\x7d",''),("\x7e",''),("\x7f",''),

    ("\x80",'binary'),("\x81",'binary'),("\x82",'binary'),("\x83",'binary'),("\x84",'binary'),("\x85",'binary'),("\x86",'binary'),("\x87",'binary'),("\x88",'binary'),("\x89",'binary'),("\x8a",'binary'),("\x8b",'binary'),("\x8c",'binary'),("\x8d",'binary'),("\x8e",'binary'),("\x8f",'binary'),
    ("\x90",'binary'),("\x91",'binary'),("\x92",'binary'),("\x93",'binary'),("\x94",'binary'),("\x95",'binary'),("\x96",'binary'),("\x97",'binary'),("\x98",'binary'),("\x99",'binary'),("\x9a",'binary'),("\x9b",'binary'),("\x9c",'binary'),("\x9d",'binary'),("\x9e",'binary'),("\x9f",'binary'),
    ("\xa0",'binary'),

                    ("\xa1",'sjis'),("\xa2",'sjis'),("\xa3",'sjis'),("\xa4",'sjis'),("\xa5",'sjis'),("\xa6",'sjis'),("\xa7",'sjis'),("\xa8",'sjis'),("\xa9",'sjis'),("\xaa",'sjis'),("\xab",'sjis'),("\xac",'sjis'),("\xad",'sjis'),("\xae",'sjis'),("\xaf",'sjis'),
    ("\xb0",'sjis'),("\xb1",'sjis'),("\xb2",'sjis'),("\xb3",'sjis'),("\xb4",'sjis'),("\xb5",'sjis'),("\xb6",'sjis'),("\xb7",'sjis'),("\xb8",'sjis'),("\xb9",'sjis'),("\xba",'sjis'),("\xbb",'sjis'),("\xbc",'sjis'),("\xbd",'sjis'),("\xbe",'sjis'),("\xbf",'sjis'),
    ("\xc0",'sjis'),("\xc1",'sjis'),("\xc2",'sjis'),("\xc3",'sjis'),("\xc4",'sjis'),("\xc5",'sjis'),("\xc6",'sjis'),("\xc7",'sjis'),("\xc8",'sjis'),("\xc9",'sjis'),("\xca",'sjis'),("\xcb",'sjis'),("\xcc",'sjis'),("\xcd",'sjis'),("\xce",'sjis'),("\xcf",'sjis'),
    ("\xd0",'sjis'),("\xd1",'sjis'),("\xd2",'sjis'),("\xd3",'sjis'),("\xd4",'sjis'),("\xd5",'sjis'),("\xd6",'sjis'),("\xd7",'sjis'),("\xd8",'sjis'),("\xd9",'sjis'),("\xda",'sjis'),("\xdb",'sjis'),("\xdc",'sjis'),("\xdd",'sjis'),("\xde",'sjis'),("\xdf",'sjis'),

    ("\xe0",'binary'),("\xe1",'binary'),("\xe2",'binary'),("\xe3",'binary'),("\xe4",'binary'),("\xe5",'binary'),("\xe6",'binary'),("\xe7",'binary'),("\xe8",'binary'),("\xe9",'binary'),("\xea",'binary'),("\xeb",'binary'),("\xec",'binary'),("\xed",'binary'),("\xee",'binary'),("\xef",'binary'),
    ("\xf0",'binary'),("\xf1",'binary'),("\xf2",'binary'),("\xf3",'binary'),("\xf4",'binary'),("\xf5",'binary'),("\xf6",'binary'),("\xf7",'binary'),("\xf8",'binary'),("\xf9",'binary'),("\xfa",'binary'),("\xfb",'binary'),("\xfc",'binary'),("\xfd",'binary'),("\xfe",'binary'),("\xff",'binary'),
);

print "1..", scalar(@todo)/2, "\n";
$tno = 1;

while (($give,$want) = splice(@todo,0,2)) {
    $got = &jacode'getcode(*give);
    if ($got eq $want) {
        printf(    "ok $tno - give=(%s) want=(%s) got=(%s)\n", uc unpack('H*',$give), $want, $got);
    }
    else {
        printf("not ok $tno - give=(%s) want=(%s) got=(%s)\n", uc unpack('H*',$give), $want, $got);
    }
    $tno++;
}

__END__
