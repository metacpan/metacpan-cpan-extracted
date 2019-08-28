# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use strict;
use KSC5601;
print "1..8\n";

my $__FILE__ = __FILE__;

if ('p{L}' =~ /(\p{L})/) {
    if ($1 eq 'p{L}') {
        print qq{ok - 1 'p{L}' =~ /(\\p{L})/ ($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 'p{L}' =~ /(\\p{L})/ ($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 'p{L}' =~ /(\\p{L})/ $^X $__FILE__\n};
}

if ('p{^L}' =~ /(\p{^L})/) {
    print qq{not ok - 2 'p{^L}' =~ /(\\p{^L})/ ($1) $^X $__FILE__\n};
}
else {
    print qq{ok - 2 'p{^L}' =~ /(\\p{^L})/ $^X $__FILE__\n};
}

if ('p{^L}' =~ /(\p{\^L})/) {
    print qq{ok - 3 'p{^L}' =~ /(\\p{\\^L})/ ($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 'p{^L}' =~ /(\\p{\\^L})/ $^X $__FILE__\n};
}

if ('pL' =~ /(\pL)/) {
    if ($1 eq 'pL') {
        print qq{ok - 4 'pL' =~ /(\\pL)/ ($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 'pL' =~ /(\\pL)/ ($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 'pL' =~ /(\\pL)/ $^X $__FILE__\n};
}

if ('P{L}' =~ /(\P{L})/) {
    if ($1 eq 'P{L}') {
        print qq{ok - 5 'P{L}' =~ /(\\P{L})/ ($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 'P{L}' =~ /(\\P{L})/ ($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 'P{L}' =~ /(\\P{L})/ $^X $__FILE__\n};
}

if ('P{^L}' =~ /(\P{^L})/) {
    print qq{not ok - 6 'P{^L}' =~ /(\\P{^L})/ ($1) $^X $__FILE__\n};
}
else {
    print qq{ok - 6 'P{^L}' =~ /(\\P{^L})/ $^X $__FILE__\n};
}

if ('P{^L}' =~ /(\P{\^L})/) {
    print qq{ok - 7 'P{^L}' =~ /(\\P{\\^L})/ ($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 'P{^L}' =~ /(\\P{\\^L})/ $^X $__FILE__\n};
}

if ('PL' =~ /(\PL)/) {
    if ($1 eq 'PL') {
        print qq{ok - 8 'PL' =~ /(\\PL)/ ($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 8 'PL' =~ /(\\PL)/ ($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 'PL' =~ /(\\PL)/ $^X $__FILE__\n};
}

__END__
