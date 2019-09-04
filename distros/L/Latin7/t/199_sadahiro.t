# encoding: Latin7
# This file is encoded in Latin-7.
die "This file is not encoded in Latin-7.\n" if q{ } ne "\x82\xa0";

use Latin7;
print "1..1\n";

my $__FILE__ = __FILE__;

# ćĒŻ¾¾ (į¦Ī C<(?<=[A-Z])>) Ŗ¼OĢńoCg¶ĢęńoCgÉ
# ėĮÄ}b`·é±ĘÉĶĪ³źÄ¢Ü¹ńB
# į¦ĪA C<match("ACE", '(?<=[A-Z])(\p{Kana})')> Ķ C<('C')>
# šŌµÜ·ŖAąæėńėčÅ·B

if ('ACE' =~ /(?<=[A-Z])([ACE])/) {
    print "ok - 1 $^X $__FILE__ ('ACE' =~ /(?<=[A-Z])([ACE])/)($1)\n";
}
else {
    print "not ok - 1 $^X $__FILE__ ('ACE' =~ /(?<=[A-Z])([ACE])/)()\n";
}

__END__

