# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use strict;
use KSC5601;
print "1..2\n";

my $__FILE__ = __FILE__;

$_ = 'ㄲ';
if ($_ =~ s/(.)//b) {
    if (length($1) == 1) {
        print qq{ok - 1 \$_='ㄲ'; \$_=~s/(.)//b; length(\$1)==1 $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$_='ㄲ'; \$_=~s/(.)//b; length(\$1)==1 $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$_='ㄲ'; \$_=~s/(.)//b; length(\$1)==1 $^X $__FILE__\n};
}

$_ = 'ㄲ';
if ($_ =~ s'(.)''b) {
    if (length($1) == 1) {
        print qq{ok - 2 \$_='ㄲ'; \$_=~s'(.)''b; length(\$1)==1 $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 \$_='ㄲ'; \$_=~s'(.)''b; length(\$1)==1 $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 \$_='ㄲ'; \$_=~s'(.)''b; length(\$1)==1 $^X $__FILE__\n};
}

__END__

