######################################################################
#
# t/5342_utf8_by_euc__9of9.t
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
("\xF4\xA6",'utf8','euc','',"\xE7\x86\x99"),
("\xFD",'utf8','euc','',"\xFD"),
("\xFE",'utf8','euc','',"\xFE"),
("\xFF",'utf8','euc','',"\xFF"),
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
