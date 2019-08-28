# encoding: KSC5601
# This file is encoded in KS C 5601.
die "This file is not encoded in KS C 5601.\n" if q{ㄲ} ne "\xa4\xa2";

use strict;
use KSC5601;
print "1..1\n";

my $__FILE__ = __FILE__;

$_ = 'C:/Perl/site/lib';
$_ =~ s#/#\\#g;

if ($_ eq 'C:\\Perl\\site\\lib') {
    print qq{ok - 1 \$_ =~ s#/#\\\\#g; $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \$_ =~ s#/#\\\\#g; $^X $__FILE__\n};
}

__END__
