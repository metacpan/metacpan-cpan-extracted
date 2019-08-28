# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

my $__FILE__ = __FILE__;

use 5.005;
use KSC5601;
print "1..1\n";

print "ok - 1 $^X $__FILE__\n";

__END__
