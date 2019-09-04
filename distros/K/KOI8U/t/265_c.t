# encoding: KOI8U
# This file is encoded in KOI8-U.
die "This file is not encoded in KOI8-U.\n" if q{‚ } ne "\x82\xa0";

use strict;
use KOI8U;
print "1..256\n";

my $__FILE__ = __FILE__;

my $tno = 1;
for my $hexchr (0x00 .. 0xFF) {
    my $char = pack('C',$hexchr);
    if($char =~ /\C/){
        printf qq{ok - $tno "\\x%02X" =~ /\\C/ $^X $__FILE__\n}, $hexchr;
    }
    else{
        printf qq{not ok - $tno "\\x%02X" =~ /\\C/ $^X $__FILE__\n}, $hexchr;
    }
    $tno++;
}

__END__
