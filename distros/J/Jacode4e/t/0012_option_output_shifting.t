######################################################################
#
# 0012_option_output_shifting_test.t
#
# Copyright (c) 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use vars qw(@test);
    @test = (
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'cp932x',  'cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\x81\x40\x31\x81\x40\x81\x40\x32\x33"                                ],
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'cp932',   'cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\x81\x40\x31\x81\x40\x81\x40\x32\x33"                                ],
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'cp932ibm','cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\x81\x40\x31\x81\x40\x81\x40\x32\x33"                                ],
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'cp932nec','cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\x81\x40\x31\x81\x40\x81\x40\x32\x33"                                ],
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'sjis2004','cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\x81\x40\x31\x81\x40\x81\x40\x32\x33"                                ],
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'cp00930', 'cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\x0E\x40\x40\x0F\xF1\x0E\x40\x40\x40\x40\x0F\xF2\xF3"                ],
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'keis78',  'cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\x0A\x42\xA1\xA1\x0A\x41\xF1\x0A\x42\xA1\xA1\xA1\xA1\x0A\x41\xF2\xF3"],
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'keis83',  'cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\x0A\x42\xA1\xA1\x0A\x41\xF1\x0A\x42\xA1\xA1\xA1\xA1\x0A\x41\xF2\xF3"],
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'keis90',  'cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\x0A\x42\xA1\xA1\x0A\x41\xF1\x0A\x42\xA1\xA1\xA1\xA1\x0A\x41\xF2\xF3"],
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'jef',     'cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\x28\xA1\xA1\x29\xF1\x28\xA1\xA1\xA1\xA1\x29\xF2\xF3"                ],
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'jef9p',   'cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\x38\xA1\xA1\x29\xF1\x38\xA1\xA1\xA1\xA1\x29\xF2\xF3"                ],
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'jipsj',   'cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\x1A\x70\x21\x21\x1A\x71\x31\x1A\x70\x21\x21\x21\x21\x1A\x71\x32\x33"],
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'jipse',   'cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\x3F\x75\x4F\x4F\x3F\x76\xF1\x3F\x75\x4F\x4F\x4F\x4F\x3F\x76\xF2\xF3"],
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'letsj',   'cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\x93\x70\x20\x20\x93\xF1\x31\x93\x70\x20\x20\x20\x20\x93\xF1\x32\x33"],
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'utf8',    'cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\xE3\x80\x80\x31\xE3\x80\x80\xE3\x80\x80\x32\x33"                    ],
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'utf8.1',  'cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\xE3\x80\x80\x31\xE3\x80\x80\xE3\x80\x80\x32\x33"                    ],
        ["\x81\x40\x31\x81\x40\x81\x40\x32\x33",'utf8jp',  'cp932x',{'INPUT_LAYOUT'=>'DSDDSS','OUTPUT_SHIFTING'=>1},"\xF3\xB0\x84\x80\xF3\xB0\x80\xB1\xF3\xB0\x84\x80\xF3\xB0\x84\x80\xF3\xB0\x80\xB2\xF3\xB0\x80\xB3"],
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
