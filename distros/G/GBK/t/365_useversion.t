# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

my $__FILE__ = __FILE__;

use 5.00503;
use GBK;
print "1..1\n";

print "ok - 1 $^X $__FILE__\n";

__END__
