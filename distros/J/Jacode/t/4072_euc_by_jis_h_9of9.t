######################################################################
#
# t/4072_euc_by_jis_h_9of9.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

sub BEGIN {
    eval q<
        use FindBin;
        use lib "$FindBin::Bin/..";
    >;
}
require 'lib/jacode.pl';

# avoid "Allocation too large"
@todo = (
("\xA0\x1B\x28\x42",'euc','jis','h',"\xA0"),
("\xFD\x1B\x28\x42",'euc','jis','h',"\xFD"),
("\xFE\x1B\x28\x42",'euc','jis','h',"\xFE"),
("\xFF\x1B\x28\x42",'euc','jis','h',"\xFF"),
);

print "1..", scalar(@todo)/5, "\n";
$tno = 1;

while (($give,$OUTPUT_encoding,$INPUT_encoding,$option,$want) = splice(@todo,0,5)) {
    $got = $give;
    &jacode'convert(*got,$OUTPUT_encoding,$INPUT_encoding,$option);
    if ($got eq $want) {
        printf(    "ok $tno - give=(%s) want=(%s) got=(%s)\n", unpack('H*',$give), unpack('H*',$want), unpack('H*',$got));
    }
    else {
        printf("not ok $tno - give=(%s) want=(%s) got=(%s)\n", unpack('H*',$give), unpack('H*',$want), unpack('H*',$got));
    }
    $tno++;
}

__END__
