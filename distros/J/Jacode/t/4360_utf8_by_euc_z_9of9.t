######################################################################
#
# t/4360_utf8_by_euc_z_9of9.t
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
("\xF4\xA6",'utf8','euc','z',"\xE7\x86\x99"),
("\xFD",'utf8','euc','z',"\xFD"),
("\xFE",'utf8','euc','z',"\xFE"),
("\xFF",'utf8','euc','z',"\xFF"),
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
