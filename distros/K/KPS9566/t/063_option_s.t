# encoding: KPS9566
# This file is encoded in KPS9566.
die "This file is not encoded in KPS9566.\n" if q{‚ } ne "\x82\xa0";

use KPS9566;
print "1..1\n";

my $__FILE__ = __FILE__;

# s///g
$a = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

if ($a =~ s/[CK]/‚ ‚¢‚¤/g) {
    if ($a eq "AB‚ ‚¢‚¤DEFGHIJ‚ ‚¢‚¤LMNOPQRSTUVWXYZ") {
        print qq{ok - 1 \$a =~ s/[CK]/‚ ‚¢‚¤/g ($a) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$a =~ s/[CK]/‚ ‚¢‚¤/g ($a) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$a =~ s/[CK]/‚ ‚¢‚¤/g ($a) $^X $__FILE__\n};
}

__END__
