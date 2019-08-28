# encoding: GBK
# This file is encoded in GBK.
die "This file is not encoded in GBK.\n" if q{偁} ne "\x82\xa0";

use GBK;
print "1..25\n";

my $__FILE__ = __FILE__;

if ("A" !~ /[B-D]/) {
    print qq{ok - 1 "A"!~/[B-D]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "A"!~/[B-D]/ $^X $__FILE__\n};
}

if ("B" =~ /[B-D]/) {
    print qq{ok - 2 "B"=~/[B-D]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 "B"=~/[B-D]/ $^X $__FILE__\n};
}

if ("C" =~ /[B-D]/) {
    print qq{ok - 3 "C"=~/[B-D]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 "C"=~/[B-D]/ $^X $__FILE__\n};
}

if ("D" =~ /[B-D]/) {
    print qq{ok - 4 "D"=~/[B-D]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 "D"=~/[B-D]/ $^X $__FILE__\n};
}

if ("E" !~ /[B-D]/) {
    print qq{ok - 5 "E"!~/[B-D]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 "E"!~/[B-D]/ $^X $__FILE__\n};
}

if ("A" !~ /[\x42-D]/) {
    print qq{ok - 6 "A"!~/[\\x42-D]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 "A"!~/[\\x42-D]/ $^X $__FILE__\n};
}

if ("B" =~ /[\x42-D]/) {
    print qq{ok - 7 "B"=~/[\\x42-D]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 "B"=~/[\\x42-D]/ $^X $__FILE__\n};
}

if ("C" =~ /[\x42-D]/) {
    print qq{ok - 8 "C"=~/[\\x42-D]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 "C"=~/[\\x42-D]/ $^X $__FILE__\n};
}

if ("D" =~ /[\x42-D]/) {
    print qq{ok - 9 "D"=~/[\\x42-D]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 "D"=~/[\\x42-D]/ $^X $__FILE__\n};
}

if ("E" !~ /[\x42-D]/) {
    print qq{ok - 10 "E"!~/[\\x42-D]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 "E"!~/[\\x42-D]/ $^X $__FILE__\n};
}

my $from = 'B';
if ("A" !~ /[$from-D]/) {
    print qq{ok - 11 "A"!~/[\$from-D]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 "A"!~/[\$from-D]/ $^X $__FILE__\n};
}

if ("B" =~ /[$from-D]/) {
    print qq{ok - 12 "B"=~/[\$from-D]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 "B"=~/[\$from-D]/ $^X $__FILE__\n};
}

if ("C" =~ /[$from-D]/) {
    print qq{ok - 13 "C"=~/[\$from-D]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 13 "C"=~/[\$from-D]/ $^X $__FILE__\n};
}

if ("D" =~ /[$from-D]/) {
    print qq{ok - 14 "D"=~/[\$from-D]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 "D"=~/[\$from-D]/ $^X $__FILE__\n};
}

if ("E" !~ /[$from-D]/) {
    print qq{ok - 15 "E"!~/[\$from-D]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 "E"!~/[\$from-D]/ $^X $__FILE__\n};
}

my $to = 'D';
if ("A" !~ /[$from-$to]/) {
    print qq{ok - 16 "A"!~/[\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 16 "A"!~/[\$from-\$to]/ $^X $__FILE__\n};
}

if ("B" =~ /[$from-$to]/) {
    print qq{ok - 17 "B"=~/[\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 17 "B"=~/[\$from-\$to]/ $^X $__FILE__\n};
}

if ("C" =~ /[$from-$to]/) {
    print qq{ok - 18 "C"=~/[\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 18 "C"=~/[\$from-\$to]/ $^X $__FILE__\n};
}

if ("D" =~ /[$from-$to]/) {
    print qq{ok - 19 "D"=~/[\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 "D"=~/[\$from-\$to]/ $^X $__FILE__\n};
}

if ("E" !~ /[$from-$to]/) {
    print qq{ok - 20 "E"!~/[\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 20 "E"!~/[\$from-\$to]/ $^X $__FILE__\n};
}

if ("A" !~ /[${from}-${to}]/) {
    print qq{ok - 21 "A"!~/[\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 21 "A"!~/[\${from}-\${to}]/ $^X $__FILE__\n};
}

if ("B" =~ /[${from}-${to}]/) {
    print qq{ok - 22 "B"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 22 "B"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}

if ("C" =~ /[${from}-${to}]/) {
    print qq{ok - 23 "C"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 23 "C"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}

if ("D" =~ /[${from}-${to}]/) {
    print qq{ok - 24 "D"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 24 "D"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}

if ("E" !~ /[${from}-${to}]/) {
    print qq{ok - 25 "E"!~/[\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 25 "E"!~/[\${from}-\${to}]/ $^X $__FILE__\n};
}

__END__
