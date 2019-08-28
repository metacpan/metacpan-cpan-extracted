# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('ㄲㄴㄶㄶ' =~ /^(ㄲㄴㄶ)$/) {
    print "not ok - 1 $^X $__FILE__ not ('ㄲㄴㄶㄶ' =~ /^ㄲㄴㄶ\$/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('ㄲㄴㄶㄶ' =~ /^ㄲㄴㄶ\$/).\n";
}

__END__
