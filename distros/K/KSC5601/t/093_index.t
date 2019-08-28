# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;
print "1..4\n";

my $__FILE__ = __FILE__;

$_ = 'ㄲㄴㄶㄸㄺㄲㄴㄶㄸㄺ';
if (index($_,'ㄶㄸ') == 4) {
    print qq{ok - 1 index(\$_,'ㄶㄸ') == 4 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 index(\$_,'ㄶㄸ') == 4 $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄲㄴㄶㄸㄺ';
if (index($_,'ㄶㄸ',6) == 14) {
    print qq{ok - 2 index(\$_,'ㄶㄸ',6) == 14 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 index(\$_,'ㄶㄸ',6) == 14 $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄲㄴㄶㄸㄺ';
if (KSC5601::index($_,'ㄶㄸ') == 2) {
    print qq{ok - 3 KSC5601::index(\$_,'ㄶㄸ') == 2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 KSC5601::index(\$_,'ㄶㄸ') == 2 $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄲㄴㄶㄸㄺ';
if (KSC5601::index($_,'ㄶㄸ',3) == 7) {
    print qq{ok - 4 KSC5601::index(\$_,'ㄶㄸ',3) == 7 $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 KSC5601::index(\$_,'ㄶㄸ',3) == 7 $^X $__FILE__\n};
}

__END__
