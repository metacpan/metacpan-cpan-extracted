# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{‚ } ne "\x82\xa0";

use KPS9566;
print "1..15\n";

my $__FILE__ = __FILE__;

if ("ABCDEF" =~ /DEF$/) {
    print qq{ok - 1 "ABCDEF" =~ /DEF\$/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "ABCDEF" =~ /DEF\$/ $^X $__FILE__\n};
}

if ("ABCDEF\n" =~ /DEF$/) {
    print qq{ok - 2 "ABCDEF\\n" =~ /DEF\$/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 "ABCDEF\\n" =~ /DEF\$/ $^X $__FILE__\n};
}

if ("ABCDEF\n" =~ /DEF\n$/) {
    print qq{ok - 3 "ABCDEF\\n" =~ /DEF\\n\$/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 "ABCDEF\\n" =~ /DEF\\n\$/ $^X $__FILE__\n};
}

if ("ABCDEF" =~ /DEF\Z/) {
    print qq{ok - 4 "ABCDEF" =~ /DEF\\Z/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 "ABCDEF" =~ /DEF\\Z/ $^X $__FILE__\n};
}

if ("ABCDEF\n" =~ /DEF\Z/) {
    print qq{ok - 5 "ABCDEF\\n" =~ /DEF\\Z/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 "ABCDEF\\n" =~ /DEF\\Z/ $^X $__FILE__\n};
}

if ("ABCDEF\n" =~ /DEF\n\Z/) {
    print qq{ok - 6 "ABCDEF\\n" =~ /DEF\\n\\Z/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 "ABCDEF\\n" =~ /DEF\\n\\Z/ $^X $__FILE__\n};
}

if ("ABCDEF" =~ /DEF\z/) {
    print qq{ok - 7 "ABCDEF" =~ /DEF\\z/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 "ABCDEF" =~ /DEF\\z/ $^X $__FILE__\n};
}

if ("ABCDEF\n" !~ /DEF\z/) {
    print qq{ok - 8 "ABCDEF\\n" !~ /DEF\\z/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 "ABCDEF\\n" !~ /DEF\\z/ $^X $__FILE__\n};
}

if ("ABCDEF\n" =~ /DEF\n\z/) {
    print qq{ok - 9 "ABCDEF\\n" =~ /DEF\\n\\z/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 "ABCDEF\\n" =~ /DEF\\n\\z/ $^X $__FILE__\n};
}

if ("ABCDEF\nGHI" =~ /DEF$/m) {
    print qq{ok - 10 "ABCDEF\\nGHI" =~ /DEF\$/m $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 "ABCDEF\\nGHI" =~ /DEF\$/m $^X $__FILE__\n};
}

if ("ABCDEF\nGHI" !~ /DEF\n$/m) {
    print qq{ok - 11 "ABCDEF\\nGHI" !~ /DEF\\n\$/m $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 "ABCDEF\\nGHI" !~ /DEF\\n\$/m $^X $__FILE__\n};
}

if ("ABCDEF\nGHI" !~ /DEF\Z/m) {
    print qq{ok - 12 "ABCDEF\\nGHI" !~ /DEF\\Z/m $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 "ABCDEF\\nGHI" !~ /DEF\\Z/m $^X $__FILE__\n};
}

if ("ABCDEF\nGHI" !~ /DEF\n\Z/m) {
    print qq{ok - 13 "ABCDEF\\nGHI" !~ /DEF\\n\\Z/m $^X $__FILE__\n};
}
else {
    print qq{not ok - 13 "ABCDEF\\nGHI" !~ /DEF\\n\\Z/m $^X $__FILE__\n};
}

if ("ABCDEF\nGHI" !~ /DEF\z/m) {
    print qq{ok - 14 "ABCDEF\\nGHI" !~ /DEF\\z/m $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 "ABCDEF\\nGHI" !~ /DEF\\z/m $^X $__FILE__\n};
}

if ("ABCDEF\nGHI" !~ /DEF\n\z/m) {
    print qq{ok - 15 "ABCDEF\\nGHI" !~ /DEF\\n\\z/m $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 "ABCDEF\\nGHI" !~ /DEF\\n\\z/m $^X $__FILE__\n};
}

__END__
