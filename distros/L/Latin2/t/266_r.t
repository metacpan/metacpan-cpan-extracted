# encoding: Latin2
# This file is encoded in Latin-2.
die "This file is not encoded in Latin-2.\n" if q{ } ne "\x82\xa0";

use strict;
use Latin2;
print "1..3\n";

my $__FILE__ = __FILE__;

if("\x0A" =~ /\R/){
    print qq{ok - 1 "\\x0A" =~ /\\R/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 1 "\\x0A" =~ /\\R/ $^X $__FILE__\n};
}

if("\x0D" =~ /\R/){
    print qq{ok - 2 "\\x0D" =~ /\\R/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 2 "\\x0D" =~ /\\R/ $^X $__FILE__\n};
}

if("\x0D\x0A" =~ /\R/){
    print qq{ok - 3 "\\x0D\\x0A" =~ /\\R/ $^X $__FILE__\n};
}
else{
    print qq{not ok - 3 "\\x0D\\x0A" =~ /\\R/ $^X $__FILE__\n};
}

__END__
