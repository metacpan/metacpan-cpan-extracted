######################################################################
#
# t/5099_utf8_by_jis_h_9of9.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
sub BEGIN {
    eval q<
        use FindBin;
        use lib "$FindBin::Bin/../lib";
    >;
}
use Jacode;

# avoid "Allocation too large"
my @todo = (
("\xA0\x1B\x28\x42",'utf8','jis','h',"\xA0"),
("\xFD\x1B\x28\x42",'utf8','jis','h',"\xFD"),
("\xFE\x1B\x28\x42",'utf8','jis','h',"\xFE"),
("\xFF\x1B\x28\x42",'utf8','jis','h',"\xFF"),
);

print "1..", scalar(@todo)/5, "\n";
my $tno = 1;

while (my($give,$OUTPUT_encoding,$INPUT_encoding,$option,$want) = splice(@todo,0,5)) {
    my $got = $give;
    Jacode::convert(\$got,$OUTPUT_encoding,$INPUT_encoding,$option);
    if ($got eq $want) {
        printf(    "ok $tno - give=(%s) want=(%s) got=(%s)\n", unpack('H*',$give), unpack('H*',$want), unpack('H*',$got));
    }
    else {
        printf("not ok $tno - give=(%s) want=(%s) got=(%s)\n", unpack('H*',$give), unpack('H*',$want), unpack('H*',$got));
    }
    $tno++;
}

__END__
