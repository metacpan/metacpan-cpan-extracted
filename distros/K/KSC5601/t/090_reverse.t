# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;
print "1..2\n";

my $__FILE__ = __FILE__;

@_ = KSC5601::reverse('ㄲㄴㄶㄸㄺ', 'ㄻㄽㄿㅁㅃ', 'ㅅㅇㅉㅋㅍ');
if ("@_" eq "ㅅㅇㅉㅋㅍ ㄻㄽㄿㅁㅃ ㄲㄴㄶㄸㄺ") {
    print qq{ok - 1 \@_ = KSC5601::reverse('ㄲㄴㄶㄸㄺ', 'ㄻㄽㄿㅁㅃ', 'ㅅㅇㅉㅋㅍ') $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \@_ = KSC5601::reverse('ㄲㄴㄶㄸㄺ', 'ㄻㄽㄿㅁㅃ', 'ㅅㅇㅉㅋㅍ') $^X $__FILE__\n};
}

$_ = KSC5601::reverse('ㄲㄴㄶㄸㄺ', 'ㄻㄽㄿㅁㅃ', 'ㅅㅇㅉㅋㅍ');
if ($_ eq "ㅍㅋㅉㅇㅅㅃㅁㄿㄽㄻㄺㄸㄶㄴㄲ") {
    print qq{ok - 2 \$_ = KSC5601::reverse('ㄲㄴㄶㄸㄺ', 'ㄻㄽㄿㅁㅃ', 'ㅅㅇㅉㅋㅍ') $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$_ = KSC5601::reverse('ㄲㄴㄶㄸㄺ', 'ㄻㄽㄿㅁㅃ', 'ㅅㅇㅉㅋㅍ') $^X $__FILE__\n};
}

__END__
