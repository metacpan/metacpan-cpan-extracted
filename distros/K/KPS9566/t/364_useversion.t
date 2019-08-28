# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{‚ } ne "\x82\xa0";

my $__FILE__ = __FILE__;

use 5.005;
use KPS9566;
print "1..1\n";

print "ok - 1 $^X $__FILE__\n";

__END__
