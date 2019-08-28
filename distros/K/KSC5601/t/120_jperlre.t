# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('ㄲㄴㄴㄴㄴㄶ' =~ /(ㄲㄴ{1,}ㄴㄶ)/) {
    if ("$1" eq "ㄲㄴㄴㄴㄴㄶ") {
        print "ok - 1 $^X $__FILE__ ('ㄲㄴㄴㄴㄴㄶ' =~ /ㄲㄴ{1,}ㄴㄶ/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('ㄲㄴㄴㄴㄴㄶ' =~ /ㄲㄴ{1,}ㄴㄶ/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('ㄲㄴㄴㄴㄴㄶ' =~ /ㄲㄴ{1,}ㄴㄶ/).\n";
}

__END__
