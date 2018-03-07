######################################################################
#
# 0122_cp932_vs_jipsj_test.t
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use vars qw(@test);
    @test = (
        ["\x8B\xC4",'jipsj','cp932',{'INPUT_LAYOUT'=>'D'},"\xB6\xDA"], # ‹Ä 8BC4 B6DA
        ["\x96\x8A",'jipsj','cp932',{'INPUT_LAYOUT'=>'D'},"\xBF\xCE"], # –Š 968A BFCE
        ["\x97\x79",'jipsj','cp932',{'INPUT_LAYOUT'=>'D'},"\xD0\xC4"], # —y 9779 D0C4
        ["\xE0\xF4",'jipsj','cp932',{'INPUT_LAYOUT'=>'D'},"\xC4\xE8"], # àô E0F4 C4E8
        ["\xEA\x9F",'jipsj','cp932',{'INPUT_LAYOUT'=>'D'},"\x36\x46"], # êŸ EA9F 3646
        ["\xEA\xA0",'jipsj','cp932',{'INPUT_LAYOUT'=>'D'},"\x4B\x6A"], # ê  EAA0 4B6A
        ["\xEA\xA1",'jipsj','cp932',{'INPUT_LAYOUT'=>'D'},"\x4D\x5A"], # ê¡ EAA1 4D5A
        ["\xEA\xA2",'jipsj','cp932',{'INPUT_LAYOUT'=>'D'},"\x60\x76"], # ê¢ EAA2 6076
        ["\xEA\xA3",'jipsj','cp932',{'INPUT_LAYOUT'=>'D'},"\xB4\xA8"], # ê£ EAA3 B4A8
        ["\xEA\xA4",'jipsj','cp932',{'INPUT_LAYOUT'=>'D'},"\xC3\xBA"], # ê¤ EAA4 C3BA
    );
    $|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }
}

use Jacode4e;

for my $test (@test) {
    my($give,$OUTPUT_encoding,$INPUT_encoding,$option,$want) = @{$test};
    my $got = $give;
    my $return = Jacode4e::convert(\$got,$OUTPUT_encoding,$INPUT_encoding,$option);

    my $option_content = '';
    if (defined $option) {
        $option_content .= qq{INPUT_LAYOUT=>$option->{'INPUT_LAYOUT'}}        if exists $option->{'INPUT_LAYOUT'};
        $option_content .= qq{OUTPUT_SHIFTING=>$option->{'OUTPUT_SHIFTING'}}  if exists $option->{'OUTPUT_SHIFTING'};
        $option_content .= qq{SPACE=>@{[uc unpack('H*',$option->{'SPACE'})]}} if exists $option->{'SPACE'};
        $option_content .= qq{GETA=>@{[uc unpack('H*',$option->{'GETA'})]}}   if exists $option->{'GETA'};
        $option_content = "{$option_content}";
    }

    ok(($return > 0) and ($got eq $want),
        sprintf(qq{$INPUT_encoding(%s) to $OUTPUT_encoding(%s), $option_content => return=$return,got=(%s)},
            uc unpack('H*',$give),
            uc unpack('H*',$want),
            uc unpack('H*',$got),
        )
    );
}

__END__
