######################################################################
#
# 0007_cp932x_E9CB.t
#
# Copyright (c) 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use vars qw(@test);
    @test = (
        ["\xE9\xCB",'cp932x',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\xE9\xCB"        ],
        ["\xE9\xCB",'cp932',   'cp932x',{'INPUT_LAYOUT'=>'D'},"\xE9\xCB"        ],
        ["\xE9\xCB",'cp932ibm','cp932x',{'INPUT_LAYOUT'=>'D'},"\xE9\xCB"        ],
        ["\xE9\xCB",'cp932nec','cp932x',{'INPUT_LAYOUT'=>'D'},"\xE9\xCB"        ],
        ["\xE9\xCB",'sjis2004','cp932x',{'INPUT_LAYOUT'=>'D'},"\xE9\xCB"        ],
        ["\xE9\xCB",'cp00930', 'cp932x',{'INPUT_LAYOUT'=>'D'},"\x51\xF0"        ],
        ["\xE9\xCB",'keis78',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\xB0\xB3"        ],
        ["\xE9\xCB",'keis83',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\xF2\xCD"        ],
        ["\xE9\xCB",'keis90',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\xF2\xCD"        ],
        ["\xE9\xCB",'jef',     'cp932x',{'INPUT_LAYOUT'=>'D'},"\xB0\xB3"        ],
        ["\xE9\xCB",'jef9p',   'cp932x',{'INPUT_LAYOUT'=>'D'},"\xB0\xB3"        ],
        ["\xE9\xCB",'jipsj',   'cp932x',{'INPUT_LAYOUT'=>'D'},"\x30\x33"        ],
        ["\xE9\xCB",'jipse',   'cp932x',{'INPUT_LAYOUT'=>'D'},"\xF0\xF3"        ],
        ["\xE9\xCB",'letsj',   'cp932x',{'INPUT_LAYOUT'=>'D'},"\xF2\xCD"        ],
        ["\xE9\xCB",'utf8',    'cp932x',{'INPUT_LAYOUT'=>'D'},"\xE9\xB0\xBA"    ],
        ["\xE9\xCB",'utf8.1',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\xE9\xB0\xBA"    ],
        ["\xE9\xCB",'utf8jp',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\xF3\xB1\xBB\xAA"],
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
