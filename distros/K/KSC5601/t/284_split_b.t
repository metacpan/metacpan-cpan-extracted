# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use strict;
use KSC5601;
print "1..12\n";

my $__FILE__ = __FILE__;

my @split = ();

@split = split(m/A/, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 1 split(m/A/, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 split(m/A/, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/a/i, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 2 split(m/a/i, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 split(m/a/i, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/A/, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 3 split(m/A/, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 3 split(m/A/, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/a/i, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 4 split(m/a/i, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 split(m/a/i, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/⇔/, join('、⇒', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 5 split(m/⇔/, join('、⇒', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 5 split(m/⇔/, join('、⇒', 1..10)) $^X $__FILE__\n};
}

@split = split(m/⇔/i, join('、⇒', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 6 split(m/⇔/i, join('、⇒', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 6 split(m/⇔/i, join('、⇒', 1..10)) $^X $__FILE__\n};
}

@split = split(m/A/b, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 7 split(m/A/b, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 split(m/A/b, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/A/b, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{not ok - 8 split(m/A/b, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{ok - 8 split(m/A/b, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/⇔/b, join('、⇒', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 9 split(m/⇔/b, join('、⇒', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 split(m/⇔/b, join('、⇒', 1..10)) $^X $__FILE__\n};
}

@split = split(m/a/ib, join('A', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 10 split(m/a/ib, join('A', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 split(m/a/ib, join('A', 1..10)) $^X $__FILE__\n};
}

@split = split(m/a/ib, join('a', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 11 split(m/a/ib, join('a', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 split(m/a/ib, join('a', 1..10)) $^X $__FILE__\n};
}

@split = split(m/⇔/ib, join('、⇒', 1..10));
if (scalar(@split) == 10) {
    print qq{ok - 12 split(m/⇔/ib, join('、⇒', 1..10)) $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 split(m/⇔/ib, join('、⇒', 1..10)) $^X $__FILE__\n};
}

__END__

