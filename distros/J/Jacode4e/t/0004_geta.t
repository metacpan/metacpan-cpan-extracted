######################################################################
#
# 0004_geta_test.t
#
# Copyright (c) 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use vars qw(@test);
    @test = (
        ["\xFC\xFC",'cp932x',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xAC"        ],
        ["\xFC\xFC",'cp932',   'cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xAC"        ],
        ["\xFC\xFC",'cp932ibm','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xAC"        ],
        ["\xFC\xFC",'cp932nec','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xAC"        ],
        ["\xFC\xFC",'sjis2004','cp932x',{'INPUT_LAYOUT'=>'D'},"\x81\xAC"        ],
        ["\xFC\xFC",'cp00930', 'cp932x',{'INPUT_LAYOUT'=>'D'},"\x44\x7D"        ],
        ["\xFC\xFC",'keis78',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\xA2\xAE"        ],
        ["\xFC\xFC",'keis83',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\xA2\xAE"        ],
        ["\xFC\xFC",'keis90',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\xA2\xAE"        ],
        ["\xFC\xFC",'jef',     'cp932x',{'INPUT_LAYOUT'=>'D'},"\xA2\xAE"        ],
        ["\xFC\xFC",'jef9p',   'cp932x',{'INPUT_LAYOUT'=>'D'},"\xA2\xAE"        ],
        ["\xFC\xFC",'jipsj',   'cp932x',{'INPUT_LAYOUT'=>'D'},"\x22\x2E"        ],
        ["\xFC\xFC",'jipse',   'cp932x',{'INPUT_LAYOUT'=>'D'},"\x7F\x4B"        ],
        ["\xFC\xFC",'letsj',   'cp932x',{'INPUT_LAYOUT'=>'D'},"\xA2\xAE"        ],
        ["\xFC\xFC",'utf8',    'cp932x',{'INPUT_LAYOUT'=>'D'},"\xE3\x80\x93"    ],
        ["\xFC\xFC",'utf8.1',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\xE3\x80\x93"    ],
        ["\xFC\xFC",'utf8jp',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\xF3\xB0\x85\xAB"],
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
