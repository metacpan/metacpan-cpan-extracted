# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;
print "1..20\n";

my $__FILE__ = __FILE__;

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (substr($_,10) eq 'ㄻㄽㄿㅁㅃ') {
    print qq{ok - 1 substr(\$_,10) eq 'ㄻㄽㄿㅁㅃ' $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 substr(\$_,10) eq 'ㄻㄽㄿㅁㅃ' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (substr($_,4,6) eq 'ㄶㄸㄺ') {
    print qq{ok - 2 substr(\$_,4,6) eq 'ㄶㄸㄺ' $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 substr(\$_,4,6) eq 'ㄶㄸㄺ' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (substr($_,4,6,'ㅅㅇㅉㅋㅍ') eq 'ㄶㄸㄺ') {
    if ($_ eq 'ㄲㄴㅅㅇㅉㅋㅍㄻㄽㄿㅁㅃ') {
        print qq{ok - 3 substr(\$_,4,6,'ㅅㅇㅉㅋㅍ') eq 'ㄶㄸㄺ' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 substr(\$_,4,6,'ㅅㅇㅉㅋㅍ') eq 'ㄶㄸㄺ' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 substr(\$_,4,6,'ㅅㅇㅉㅋㅍ') eq 'ㄶㄸㄺ' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (substr($_,-6) eq 'ㄿㅁㅃ') {
    print qq{ok - 4 substr(\$_,-6) eq 'ㄿㅁㅃ' $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 substr(\$_,-6) eq 'ㄿㅁㅃ' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (substr($_,-10,6) eq 'ㄻㄽㄿ') {
    print qq{ok - 5 substr(\$_,-10,6) eq 'ㄻㄽㄿ' $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 substr(\$_,-10,6) eq 'ㄻㄽㄿ' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (substr($_,-10,6,'ㅴㅶㅸ') eq 'ㄻㄽㄿ') {
    if ($_ eq 'ㄲㄴㄶㄸㄺㅴㅶㅸㅁㅃ') {
        print qq{ok - 6 substr(\$_,-10,6,'ㅴㅶㅸ') eq 'ㄻㄽㄿ' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 6 substr(\$_,-10,6,'ㅴㅶㅸ') eq 'ㄻㄽㄿ' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 substr(\$_,-10,6,'ㅴㅶㅸ') eq 'ㄻㄽㄿ' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (substr($_,10,0) eq '') {
    print qq{ok - 7 substr(\$_,10,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 substr(\$_,10,0) eq '' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (substr($_,10,0,'ㅴㅶㅸ') eq '') {
    if ($_ eq 'ㄲㄴㄶㄸㄺㅴㅶㅸㄻㄽㄿㅁㅃ') {
        print qq{ok - 8 substr(\$_,10,0,'ㅴㅶㅸ') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 8 substr(\$_,10,0,'ㅴㅶㅸ') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 substr(\$_,10,0,'ㅴㅶㅸ') eq '' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (substr($_,-10,0) eq '') {
    print qq{ok - 9 substr(\$_,-10,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 substr(\$_,-10,0) eq '' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (substr($_,-10,0,'ㅴㅶㅸ') eq '') {
    if ($_ eq 'ㄲㄴㄶㄸㄺㅴㅶㅸㄻㄽㄿㅁㅃ') {
        print qq{ok - 10 substr(\$_,-10,0,'ㅴㅶㅸ') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 substr(\$_,-10,0,'ㅴㅶㅸ') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 substr(\$_,-10,0,'ㅴㅶㅸ') eq '' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (KSC5601::substr($_,5) eq 'ㄻㄽㄿㅁㅃ') {
    print qq{ok - 11 KSC5601::substr(\$_,5) eq 'ㄻㄽㄿㅁㅃ' $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 KSC5601::substr(\$_,5) eq 'ㄻㄽㄿㅁㅃ' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (KSC5601::substr($_,2,3) eq 'ㄶㄸㄺ') {
    print qq{ok - 12 KSC5601::substr(\$_,2,3) eq 'ㄶㄸㄺ' $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 KSC5601::substr(\$_,2,3) eq 'ㄶㄸㄺ' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (KSC5601::substr($_,2,3,'ㅅㅇㅉㅋㅍ') eq 'ㄶㄸㄺ') {
    if ($_ eq 'ㄲㄴㅅㅇㅉㅋㅍㄻㄽㄿㅁㅃ') {
        print qq{ok - 13 KSC5601::substr(\$_,2,3,'ㅅㅇㅉㅋㅍ') eq 'ㄶㄸㄺ' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 13 KSC5601::substr(\$_,2,3,'ㅅㅇㅉㅋㅍ') eq 'ㄶㄸㄺ' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 13 KSC5601::substr(\$_,2,3,'ㅅㅇㅉㅋㅍ') eq 'ㄶㄸㄺ' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (KSC5601::substr($_,-3) eq 'ㄿㅁㅃ') {
    print qq{ok - 14 KSC5601::substr(\$_,-3) eq 'ㄿㅁㅃ' $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 KSC5601::substr(\$_,-3) eq 'ㄿㅁㅃ' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (KSC5601::substr($_,-5,3) eq 'ㄻㄽㄿ') {
    print qq{ok - 15 KSC5601::substr(\$_,-5,3) eq 'ㄻㄽㄿ' $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 KSC5601::substr(\$_,-5,3) eq 'ㄻㄽㄿ' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (KSC5601::substr($_,-5,3,'ㅴㅶㅸ') eq 'ㄻㄽㄿ') {
    if ($_ eq 'ㄲㄴㄶㄸㄺㅴㅶㅸㅁㅃ') {
        print qq{ok - 16 KSC5601::substr(\$_,-5,3,'ㅴㅶㅸ') eq 'ㄻㄽㄿ' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 16 KSC5601::substr(\$_,-5,3,'ㅴㅶㅸ') eq 'ㄻㄽㄿ' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 16 KSC5601::substr(\$_,-5,3,'ㅴㅶㅸ') eq 'ㄻㄽㄿ' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (KSC5601::substr($_,5,0) eq '') {
    print qq{ok - 17 KSC5601::substr(\$_,5,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 17 KSC5601::substr(\$_,5,0) eq '' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (KSC5601::substr($_,5,0,'ㅴㅶㅸ') eq '') {
    if ($_ eq 'ㄲㄴㄶㄸㄺㅴㅶㅸㄻㄽㄿㅁㅃ') {
        print qq{ok - 18 KSC5601::substr(\$_,5,0,'ㅴㅶㅸ') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 18 KSC5601::substr(\$_,5,0,'ㅴㅶㅸ') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 18 KSC5601::substr(\$_,5,0,'ㅴㅶㅸ') eq '' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (KSC5601::substr($_,-5,0) eq '') {
    print qq{ok - 19 KSC5601::substr(\$_,-5,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 KSC5601::substr(\$_,-5,0) eq '' $^X $__FILE__\n};
}

$_ = 'ㄲㄴㄶㄸㄺㄻㄽㄿㅁㅃ';
if (KSC5601::substr($_,-5,0,'ㅴㅶㅸ') eq '') {
    if ($_ eq 'ㄲㄴㄶㄸㄺㅴㅶㅸㄻㄽㄿㅁㅃ') {
        print qq{ok - 20 KSC5601::substr(\$_,-5,0,'ㅴㅶㅸ') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 20 KSC5601::substr(\$_,-5,0,'ㅴㅶㅸ') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 20 KSC5601::substr(\$_,-5,0,'ㅴㅶㅸ') eq '' $^X $__FILE__\n};
}

__END__
