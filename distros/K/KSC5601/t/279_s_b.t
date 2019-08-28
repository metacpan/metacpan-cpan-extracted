# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use strict;
use KSC5601;
print "1..4\n";

my $__FILE__ = __FILE__;

$_ = '、⇒';
if ($_ =~ s/⇔//) {
    print qq{not ok - 1 \$_ =~ s/⇔// $^X $__FILE__\n};
}
else {
    print qq{ok - 1 \$_ =~ s/⇔// $^X $__FILE__\n};
}

$_ = '、⇒';
if ($_ =~ s/⇔//b) {
    print qq{ok - 2 \$_ =~ s/⇔//b $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$_ =~ s/⇔//b $^X $__FILE__\n};
}

$_ = '、⇒';
if ($_ =~ s/⇔//i) {
    print qq{not ok - 3 \$_ =~ s/⇔//i $^X $__FILE__\n};
}
else {
    print qq{ok - 3 \$_ =~ s/⇔//i $^X $__FILE__\n};
}

$_ = '、⇒';
if ($_ =~ s/⇔//ib) {
    print qq{ok - 4 \$_ =~ s/⇔//ib $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 \$_ =~ s/⇔//ib $^X $__FILE__\n};
}

__END__

