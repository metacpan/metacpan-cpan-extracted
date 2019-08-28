# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{あ} ne "\xa4\xa2";

use KSC5601;
print "1..1\n";

my $__FILE__ = __FILE__;

$a = "アソア";
if ($a !~ s/(アイ|イウ)//) {
    print qq{ok - 1 "アソア" !~ s/(アイ|イウ)// \$1=() $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "アソア" !~ s/(アイ|イウ)// \$1=($1) $^X $__FILE__\n};
}

__END__
