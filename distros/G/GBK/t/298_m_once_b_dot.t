# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use strict;
use GBK;
print "1..4\n";

my $__FILE__ = __FILE__;

if ('偁' =~ ?(.)?b) {
    if (length($1) == 1) {
        print qq{ok - 1 '偁'=~?(.)?b; length(\$1)==1 $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 '偁'=~?(.)?b; length(\$1)==1 $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 '偁'=~?(.)?b; length(\$1)==1 $^X $__FILE__\n};
}

if (@_ = '偁' =~ ?(.)?bg) {
    if (scalar(@_) == length('偁')) {
        if (grep( ! /^1$/, map { length($_) } @_)) {
            print qq{not ok - 2 \@_='偁'=~?(.)?bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
        }
        else {
            print qq{ok - 2 \@_='偁'=~?(.)?bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 2 \@_='偁'=~?(.)?bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 \@_='偁'=~?(.)?bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
}

if ('偁' =~ m?(.)?b) {
    if (length($1) == 1) {
        print qq{ok - 3 '偁'=~m?(.)?b; length(\$1)==1 $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 '偁'=~m?(.)?b; length(\$1)==1 $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 '偁'=~m?(.)?b; length(\$1)==1 $^X $__FILE__\n};
}

if (@_ = '偁' =~ m?(.)?bg) {
    if (scalar(@_) == length('偁')) {
        if (grep( ! /^1$/, map { length($_) } @_)) {
            print qq{not ok - 4 \@_='偁'=~m?(.)?bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
        }
        else {
            print qq{ok - 4 \@_='偁'=~m?(.)?bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 4 \@_='偁'=~m?(.)?bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 \@_='偁'=~m?(.)?bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
}

__END__

