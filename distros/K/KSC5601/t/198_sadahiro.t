# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;
print "1..1\n";

my $__FILE__ = __FILE__;

# 숴엎뿍 C<i>, C<I> ㄺㅸㅣ C<j> ㅟ、C<\p{}>, C<\P{}>, POSIX C<[: :]>.
# (嬌ㄸㅠ C<\p{IsLower}>, C<[:lower:]> ㅚㅙ) ㅛㅟ븜錮ㅇㅮㅋㆃ。
# ㅍㅞㅏㅱ、C<re('\p{Lower}', 'iI')> ㅞ쭤ㅿㅺㅛ
# C<re('\p{Alpha}')> ㆂ뽁錮ㅇㅖㄿㅐㅅㄴ。

# KSC5601 �쉈樂혼┘㎘∃� C<\p{}>, C<\P{}>, POSIX C<[: :]> ㅞ덧퓰ㄼㅲㅘㅲㅘ쨍뷔ㅇㅚㄴ。

print "ok - 1 $^X $__FILE__ (NULL)\n";

__END__

