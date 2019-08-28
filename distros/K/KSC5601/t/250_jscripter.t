# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

# use strict;
use KSC5601;
print "1..1\n";

my $__FILE__ = __FILE__;

my $a = 'aaa_123';
$a =~ s/[a-z]+_([0-9]+)/$1/g;
if ($a eq '123') {
    print "ok - 1 s///g (without 'use strict') ($a) $^X $__FILE__\n";
}
else {
    print "not ok - 1 s///g (without 'use strict') ($a) $^X $__FILE__\n";
}

__END__
