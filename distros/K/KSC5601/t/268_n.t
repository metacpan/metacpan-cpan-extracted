# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use strict;
use KSC5601;
print "1..4\n";

my $__FILE__ = __FILE__;

$_ = "ㄲ\nㄻㄽㄿㅁㅃ";

if (/(\N{3})/ and ("<$1>" eq "<ㄻㄽㄿ>")) {
    print qq{ok - 1 $^X $__FILE__ ($1)\n};
}
else {
    print qq{not ok - 1 $^X $__FILE__ ($1)\n};
}

if (/(\N{3,5})/ and ("<$1>" eq "<ㄻㄽㄿㅁㅃ>")) {
    print qq{ok - 2 $^X $__FILE__ ($1)\n};
}
else {
    print qq{not ok - 2 $^X $__FILE__ ($1)\n};
}

$_ = "ㄲ\nㄻㄽ\nㄿㅁㅃ";

if (/(\N{3,})/ and ("<$1>" eq "<ㄿㅁㅃ>")) {
    print qq{ok - 3 $^X $__FILE__ ($1)\n};
}
else {
    print qq{not ok - 3 $^X $__FILE__ ($1)\n};
}

$_ = "\n\n\nㄻㄽ\nㄿㅁㅃ";

if (/(\N+)/ and ("<$1>" eq "<ㄻㄽ>")) {
    print qq{ok - 4 $^X $__FILE__ ($1)\n};
}
else {
    print qq{not ok - 4 $^X $__FILE__ ($1)\n};
}

__END__
