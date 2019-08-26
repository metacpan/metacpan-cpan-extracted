######################################################################
#
# t/5270_jis_by_euc_h_9of9.t
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
("\xF4\xA6",'jis','euc','h',"\x1B\x24\x42\x74\x26\x1B\x28\x42"),
("\xFD",'jis','euc','h',"\xFD\x1B\x28\x42"),
("\xFE",'jis','euc','h',"\xFE\x1B\x28\x42"),
("\xFF",'jis','euc','h',"\xFF\x1B\x28\x42"),
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
