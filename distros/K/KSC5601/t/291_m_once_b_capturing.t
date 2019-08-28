# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use strict;
use KSC5601;
print "1..8\n";

my $__FILE__ = __FILE__;

if ('A' =~ ?(A)?) {
    if ($1 eq 'A') {
        print qq{ok - 1 'A' =~ ?(A)? $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 'A' =~ ?(A)? $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 'A' =~ ?(A)? $^X $__FILE__\n};
}

if ('A' =~ ?(A)?b) {
    if ($1 eq 'A') {
        print qq{ok - 2 'A' =~ ?(A)?b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 'A' =~ ?(A)?b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 'A' =~ ?(A)?b $^X $__FILE__\n};
}

if ('A' =~ ?(a)?i) {
    if ($1 eq 'A') {
        print qq{ok - 3 'A' =~ ?(a)?i $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 'A' =~ ?(a)?i $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 'A' =~ ?(a)?i $^X $__FILE__\n};
}

if ('A' =~ ?(a)?ib) {
    if ($1 eq 'A') {
        print qq{ok - 4 'A' =~ ?(a)?ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 'A' =~ ?(a)?ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 'A' =~ ?(a)?ib $^X $__FILE__\n};
}

if ('a' =~ ?(a)?i) {
    if ($1 eq 'a') {
        print qq{ok - 5 'a' =~ ?(a)?i $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 'a' =~ ?(a)?i $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 'a' =~ ?(a)?i $^X $__FILE__\n};
}

if ('a' =~ ?(a)?ib) {
    if ($1 eq 'a') {
        print qq{ok - 6 'a' =~ ?(a)?ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 6 'a' =~ ?(a)?ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 'a' =~ ?(a)?ib $^X $__FILE__\n};
}

if ('、⇒' =~ ?(⇔)?b) {
    if ($1 eq '⇔') {
        print qq{ok - 7 '、⇒' =~ ?(⇔)?b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 7 '、⇒' =~ ?(⇔)?b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 '、⇒' =~ ?(⇔)?b $^X $__FILE__\n};
}

if ('、⇒' =~ ?(⇔)?ib) {
    if ($1 eq '⇔') {
        print qq{ok - 8 '、⇒' =~ ?(⇔)?ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 8 '、⇒' =~ ?(⇔)?ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 '、⇒' =~ ?(⇔)?ib $^X $__FILE__\n};
}

__END__

