# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;
print "1..5\n";

my $__FILE__ = __FILE__;

#
# tr
#
$y = "ㄲㄴㄶㄸㄺ";
$y =~ tr/ㄲ-ㄶ//cd;
if ($y ne "ㄲㄴㄶ") {
    print "not ok - 1 $^X $__FILE__\n";
}
else {
    print "ok - 1 $^X $__FILE__\n";
}

$y = "ㄲㄴㄶㄸㄺ";
$y =~ tr/ㄲ-ㄶ/ㄻ-ㄿ/;
if ($y ne "ㄻㄽㄿㄸㄺ") {
    print "not ok - $^X 2 $__FILE__\n";
}
else {
    print "ok - 2 $^X $__FILE__\n";
}

$y = 'abcabcabc';
$y =~ tr/a-c/d-f/;
if ($y ne 'defdefdef') {
    print "not ok - 3 $^X $__FILE__\n";
}
else {
    print "ok - 3 $^X $__FILE__\n";
}

$y = 'abc';
$y =~ tr/abc/def/;
if ($y ne 'def') {
    print "not ok - 4 $^X $__FILE__\n";
}
else {
    print "ok - 4 $^X $__FILE__\n";
}

$y = 'abcabcabc';
$y =~ tr/abc/def/;
if ($y ne 'defdefdef') {
    print "not ok - 5 $^X $__FILE__\n";
}
else {
    print "ok - 5 $^X $__FILE__\n";
}

__END__
