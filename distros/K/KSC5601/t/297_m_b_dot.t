# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use strict;
use KSC5601;
print "1..6\n";

my $__FILE__ = __FILE__;

if ('ㄲ' =~ /(.)/b) {
    if (length($1) == 1) {
        print qq{ok - 1 'ㄲ'=~/(.)/b; length(\$1)==1 $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 'ㄲ'=~/(.)/b; length(\$1)==1 $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 'ㄲ'=~/(.)/b; length(\$1)==1 $^X $__FILE__\n};
}

if (@_ = 'ㄲ' =~ /(.)/bg) {
    if (scalar(@_) == length('ㄲ')) {
        if (grep( ! /^1$/, map { length($_) } @_)) {
            print qq{not ok - 2 \@_='ㄲ'=~/(.)/bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
        }
        else {
            print qq{ok - 2 \@_='ㄲ'=~/(.)/bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 2 \@_='ㄲ'=~/(.)/bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 \@_='ㄲ'=~/(.)/bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
}

if ('ㄲ' =~ m/(.)/b) {
    if (length($1) == 1) {
        print qq{ok - 3 'ㄲ'=~m/(.)/b; length(\$1)==1 $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 'ㄲ'=~m/(.)/b; length(\$1)==1 $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 'ㄲ'=~m/(.)/b; length(\$1)==1 $^X $__FILE__\n};
}

if (@_ = 'ㄲ' =~ m/(.)/bg) {
    if (scalar(@_) == length('ㄲ')) {
        if (grep( ! /^1$/, map { length($_) } @_)) {
            print qq{not ok - 4 \@_='ㄲ'=~m/(.)/bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
        }
        else {
            print qq{ok - 4 \@_='ㄲ'=~m/(.)/bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 4 \@_='ㄲ'=~m/(.)/bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 \@_='ㄲ'=~m/(.)/bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
}

if ('ㄲ' =~ m'(.)'b) {
    if (length($1) == 1) {
        print qq{ok - 5 'ㄲ'=~m'(.)'b; length(\$1)==1 $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 'ㄲ'=~m'(.)'b; length(\$1)==1 $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 'ㄲ'=~m'(.)'b; length(\$1)==1 $^X $__FILE__\n};
}

if (@_ = 'ㄲ' =~ m'(.)'bg) {
    if (scalar(@_) == length('ㄲ')) {
        if (grep( ! /^1$/, map { length($_) } @_)) {
            print qq{not ok - 6 \@_='ㄲ'=~m'(.)'bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
        }
        else {
            print qq{ok - 6 \@_='ㄲ'=~m'(.)'bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 6 \@_='ㄲ'=~m'(.)'bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 \@_='ㄲ'=~m'(.)'bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
}

__END__

