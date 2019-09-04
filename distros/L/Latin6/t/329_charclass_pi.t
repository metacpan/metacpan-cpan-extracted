# encoding: Latin6
# This file is encoded in Latin-6.
die "This file is not encoded in Latin-6.\n" if q{‚ } ne "\x82\xa0";

use Latin6;
print "1..25\n";

my $__FILE__ = __FILE__;

if ("A" !~ /[B-D]/i) {
    print qq{ok - 1 "A"!~/[B-D]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "A"!~/[B-D]/i $^X $__FILE__\n};
}

if ("B" =~ /[B-D]/i) {
    print qq{ok - 2 "B"=~/[B-D]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 "B"=~/[B-D]/i $^X $__FILE__\n};
}

if ("C" =~ /[B-D]/i) {
    print qq{ok - 3 "C"=~/[B-D]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 "C"=~/[B-D]/i $^X $__FILE__\n};
}

if ("D" =~ /[B-D]/i) {
    print qq{ok - 4 "D"=~/[B-D]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 "D"=~/[B-D]/i $^X $__FILE__\n};
}

if ("E" !~ /[B-D]/i) {
    print qq{ok - 5 "E"!~/[B-D]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 "E"!~/[B-D]/i $^X $__FILE__\n};
}

if ("A" !~ /[\x42-D]/i) {
    print qq{ok - 6 "A"!~/[\\x42-D]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 "A"!~/[\\x42-D]/i $^X $__FILE__\n};
}

if ("B" =~ /[\x42-D]/i) {
    print qq{ok - 7 "B"=~/[\\x42-D]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 "B"=~/[\\x42-D]/i $^X $__FILE__\n};
}

if ("C" =~ /[\x42-D]/i) {
    print qq{ok - 8 "C"=~/[\\x42-D]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 "C"=~/[\\x42-D]/i $^X $__FILE__\n};
}

if ("D" =~ /[\x42-D]/i) {
    print qq{ok - 9 "D"=~/[\\x42-D]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 "D"=~/[\\x42-D]/i $^X $__FILE__\n};
}

if ("E" !~ /[\x42-D]/i) {
    print qq{ok - 10 "E"!~/[\\x42-D]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 "E"!~/[\\x42-D]/i $^X $__FILE__\n};
}

my $from = 'B';
if ("A" !~ /[$from-D]/i) {
    print qq{ok - 11 "A"!~/[\$from-D]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 "A"!~/[\$from-D]/i $^X $__FILE__\n};
}

if ("B" =~ /[$from-D]/i) {
    print qq{ok - 12 "B"=~/[\$from-D]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 "B"=~/[\$from-D]/i $^X $__FILE__\n};
}

if ("C" =~ /[$from-D]/i) {
    print qq{ok - 13 "C"=~/[\$from-D]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 13 "C"=~/[\$from-D]/i $^X $__FILE__\n};
}

if ("D" =~ /[$from-D]/i) {
    print qq{ok - 14 "D"=~/[\$from-D]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 "D"=~/[\$from-D]/i $^X $__FILE__\n};
}

if ("E" !~ /[$from-D]/i) {
    print qq{ok - 15 "E"!~/[\$from-D]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 "E"!~/[\$from-D]/i $^X $__FILE__\n};
}

my $to = 'D';
if ("A" !~ /[$from-$to]/i) {
    print qq{ok - 16 "A"!~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 16 "A"!~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("B" =~ /[$from-$to]/i) {
    print qq{ok - 17 "B"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 17 "B"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("C" =~ /[$from-$to]/i) {
    print qq{ok - 18 "C"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 18 "C"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("D" =~ /[$from-$to]/i) {
    print qq{ok - 19 "D"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 "D"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("E" !~ /[$from-$to]/i) {
    print qq{ok - 20 "E"!~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 20 "E"!~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("A" !~ /[${from}-${to}]/i) {
    print qq{ok - 21 "A"!~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 21 "A"!~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("B" =~ /[${from}-${to}]/i) {
    print qq{ok - 22 "B"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 22 "B"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("C" =~ /[${from}-${to}]/i) {
    print qq{ok - 23 "C"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 23 "C"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("D" =~ /[${from}-${to}]/i) {
    print qq{ok - 24 "D"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 24 "D"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("E" !~ /[${from}-${to}]/i) {
    print qq{ok - 25 "E"!~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 25 "E"!~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

__END__
