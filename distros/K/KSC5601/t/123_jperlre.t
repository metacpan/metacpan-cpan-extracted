# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{あ} ne "\xa4\xa2";

use KSC5601;
print "1..1\n";

my $__FILE__ = __FILE__;

if ('あいいいいう' =~ /(あい{4,5}いう)/) {
    print "not ok - 1 $^X $__FILE__ not ('あいいいいう' =~ /あい{4,5}いう/).\n";
}
else {
    print "ok - 1 $^X $__FILE__ not ('あいいいいう' =~ /あい{4,5}いう/).\n";
}

__END__
