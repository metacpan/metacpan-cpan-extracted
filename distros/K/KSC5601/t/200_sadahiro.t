# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{あ} ne "\xa4\xa2";

use KSC5601;
print "1..2\n";

my $__FILE__ = __FILE__;

# 控えめな量指定子を含むパターン (例えば C<.??>やC<\d*?>) は、
# 空文字列とマッチすることができますが、C<jsplit()> のパターンとして用いた場合、
# 組み込みの C<split()> から予想される動作と異なることがあります。

if (join('', map {"($_)"} split(/.??/, 'アイウ')) eq '(ア)(イ)(ウ)') {
    print "ok - 1 $^X $__FILE__ (join('', map {qq{(\$_)}} split(/.??/, 'アイウ')) eq '(ア)(イ)(ウ)')\n";
}
else {
    print "not ok - 1 $^X $__FILE__ (join('', map {qq{(\$_)}} split(/.??/, 'アイウ')) eq '(ア)(イ)(ウ)')\n";
}

if (join('', map {"($_)"} split(/\d*?/, 'アイウ')) eq '(ア)(イ)(ウ)') {
    print "ok - 2 $^X $__FILE__ (join('', map {qq{(\$_)}} split(/\\d*?/, 'アイウ')) eq '(ア)(イ)(ウ)')\n";
}
else {
    print "not ok - 2 $^X $__FILE__ (join('', map {qq{(\$_)}} split(/\\d*?/, 'アイウ')) eq '(ア)(イ)(ウ)')\n";
}

__END__

