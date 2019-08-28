# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use KSC5601;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('ㄸef' =~ /(()ef)/) {
    if ("$1-$2" eq "ef-") {
        print "ok - 1 $^X $__FILE__ ('ㄸef' =~ /()ef/).\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__ ('ㄸef' =~ /()ef/).\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__ ('ㄸef' =~ /()ef/).\n";
}

__END__
