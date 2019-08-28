# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;

print "1..1\n";
if ($] < 5.022) {
    for my $tno (1..1) {
        print qq{ok - $tno SKIP $^X @{[__FILE__]}\n};
    }
    exit;
}

local $_ = eval q{ '' =~ /(re|regexp)/n };
if (not $@) {
    print qq{ok - 1 /(re|regexp)/n $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 /(re|regexp)/n $^X @{[__FILE__]}\n};
}

__END__
