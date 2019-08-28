# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{Ç†} ne "\x82\xa0";

use strict;
use KPS9566;
print "1..18\n";

my $__FILE__ = __FILE__;

$_ = 'A';
if ($_ =~ s'(A)'') {
    if ($1 eq 'A') {
        print qq{ok - 1 'A' =~ s'(A)'' 1:($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 'A' =~ s'(A)'' 2:($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 'A' =~ s'(A)'' 3:($1) $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s'(A)''b) {
    if ($1 eq 'A') {
        print qq{ok - 2 'A' =~ s'(A)''b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 'A' =~ s'(A)''b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 'A' =~ s'(A)''b $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s'(a)''i) {
    if ($1 eq 'A') {
        print qq{ok - 3 'A' =~ s'(a)''i $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 'A' =~ s'(a)''i $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 'A' =~ s'(a)''i $^X $__FILE__\n};
}

$_ = 'A';
if ($_ =~ s'(a)''ib) {
    if ($1 eq 'A') {
        print qq{ok - 4 'A' =~ s'(a)''ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 'A' =~ s'(a)''ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 'A' =~ s'(a)''ib $^X $__FILE__\n};
}

$_ = 'a';
if ($_ =~ s'(a)''i) {
    if ($1 eq 'a') {
        print qq{ok - 5 'a' =~ s'(a)''i $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 'a' =~ s'(a)''i $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 'a' =~ s'(a)''i $^X $__FILE__\n};
}

$_ = 'a';
if ($_ =~ s'(a)''ib) {
    if ($1 eq 'a') {
        print qq{ok - 6 'a' =~ s'(a)''ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 6 'a' =~ s'(a)''ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 'a' =~ s'(a)''ib $^X $__FILE__\n};
}

$_ = 'ÉA';
if ($_ =~ s'(A)''b) {
    if ($1 eq 'A') {
        print qq{ok - 7 'ÉA' =~ s'(A)''b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 7 'ÉA' =~ s'(A)''b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 'ÉA' =~ s'(A)''b $^X $__FILE__\n};
}

$_ = 'ÉA';
if ($_ =~ s'(A)''ib) {
    if ($1 eq 'A') {
        print qq{ok - 8 'ÉA' =~ s'(A)''ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 8 'ÉA' =~ s'(A)''ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 'ÉA' =~ s'(A)''ib $^X $__FILE__\n};
}

$_ = 'ÉA';
if ($_ =~ s'(a)''ib) {
    if ($1 eq 'A') {
        print qq{ok - 9 'ÉA' =~ s'(a)''ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 9 'ÉA' =~ s'(a)''ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 9 'ÉA' =~ s'(a)''ib $^X $__FILE__\n};
}

$_ = 'Éa';
if ($_ =~ s'(A)''ib) {
    if ($1 eq 'a') {
        print qq{ok - 10 'Éa' =~ s'(A)''ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 'Éa' =~ s'(A)''ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 'Éa' =~ s'(A)''ib $^X $__FILE__\n};
}

$_ = 'Éa';
if ($_ =~ s'(a)''b) {
    if ($1 eq 'a') {
        print qq{ok - 11 'Éa' =~ s'(a)''b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 11 'Éa' =~ s'(a)''b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 11 'Éa' =~ s'(a)''b $^X $__FILE__\n};
}

$_ = 'Éa';
if ($_ =~ s'(a)''ib) {
    if ($1 eq 'a') {
        print qq{ok - 12 'Éa' =~ s'(a)''ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 12 'Éa' =~ s'(a)''ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 12 'Éa' =~ s'(a)''ib $^X $__FILE__\n};
}

$_ = 'ÉÉA';
if ($_ =~ s'(ÉA)''b) {
    if ($1 eq 'ÉA') {
        print qq{ok - 13 'ÉÉA' =~ s'(ÉA)''b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 13 'ÉÉA' =~ s'(ÉA)''b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 13 'ÉÉA' =~ s'(ÉA)''b $^X $__FILE__\n};
}

$_ = 'ÉÉA';
if ($_ =~ s'(ÉA)''ib) {
    if ($1 eq 'ÉA') {
        print qq{ok - 14 'ÉÉA' =~ s'(ÉA)''ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 14 'ÉÉA' =~ s'(ÉA)''ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 14 'ÉÉA' =~ s'(ÉA)''ib $^X $__FILE__\n};
}

$_ = 'ÉÉA';
if ($_ =~ s'(Éa)''ib) {
    if ($1 eq 'ÉA') {
        print qq{ok - 15 'ÉÉA' =~ s'(Éa)''ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 15 'ÉÉA' =~ s'(Éa)''ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 15 'ÉÉA' =~ s'(Éa)''ib $^X $__FILE__\n};
}

$_ = 'ÉÉa';
if ($_ =~ s'(ÉA)''ib) {
    if ($1 eq 'Éa') {
        print qq{ok - 16 'ÉÉa' =~ s'(ÉA)''ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 16 'ÉÉa' =~ s'(ÉA)''ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 16 'ÉÉa' =~ s'(ÉA)''ib $^X $__FILE__\n};
}

$_ = 'ÉÉa';
if ($_ =~ s'(Éa)''b) {
    if ($1 eq 'Éa') {
        print qq{ok - 17 'ÉÉa' =~ s'(Éa)''b $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 17 'ÉÉa' =~ s'(Éa)''b $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 17 'ÉÉa' =~ s'(Éa)''b $^X $__FILE__\n};
}

$_ = 'ÉÉa';
if ($_ =~ s'(Éa)''ib) {
    if ($1 eq 'Éa') {
        print qq{ok - 18 'ÉÉa' =~ s'(Éa)''ib $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 18 'ÉÉa' =~ s'(Éa)''ib $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 18 'ÉÉa' =~ s'(Éa)''ib $^X $__FILE__\n};
}

__END__

