######################################################################
#
# 0015_option_override_mapping.t
#
# Copyright (c) 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use vars qw(@test);
    @test = (
        ["\x81\x5D",'cp932x',  'cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\x81\x7C"        }},"\x81\x7C"        ],
        ["\x81\x5D",'cp932',   'cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\x81\x7C"        }},"\x81\x7C"        ],
        ["\x81\x5D",'cp932ibm','cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\x81\x7C"        }},"\x81\x7C"        ],
        ["\x81\x5D",'cp932nec','cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\x81\x7C"        }},"\x81\x7C"        ],
        ["\x81\x5D",'sjis2004','cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\x81\xAF"        }},"\x81\xAF"        ],
        ["\x81\x5D",'cp00930', 'cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\xE9\xF3"        }},"\xE9\xF3"        ],
        ["\x81\x5D",'keis78',  'cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\xA1\xDD"        }},"\xA1\xDD"        ],
        ["\x81\x5D",'keis83',  'cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\xA1\xDD"        }},"\xA1\xDD"        ],
        ["\x81\x5D",'keis90',  'cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\xA1\xDD"        }},"\xA1\xDD"        ],
        ["\x81\x5D",'jef',     'cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\xA1\xDD"        }},"\xA1\xDD"        ],
        ["\x81\x5D",'jef9p',   'cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\xA1\xDD"        }},"\xA1\xDD"        ],
        ["\x81\x5D",'jipsj',   'cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\x21\x5D"        }},"\x21\x5D"        ],
        ["\x81\x5D",'jipse',   'cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\x4F\x5A"        }},"\x4F\x5A"        ],
        ["\x81\x5D",'letsj',   'cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\xA1\xDD"        }},"\xA1\xDD"        ],
        ["\x81\x5D",'utf8',    'cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\xEF\xBC\x8D"    }},"\xEF\xBC\x8D"    ],
        ["\x81\x5D",'utf8.1',  'cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\xEF\xBC\x8D"    }},"\xEF\xBC\x8D"    ],
        ["\x81\x5D",'utf8jp',  'cp932x',{'INPUT_LAYOUT'=>'D',                    'OVERRIDE_MAPPING'=>{"\x81\x5D"=>"\xF3\xB0\x84\xBC"}},"\xF3\xB0\x84\xBC"],

        ["\x81\x40",'cp932x',  'cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\x20\x20",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\x81\x7C"        }},"\x81\x7C"        ],
        ["\x81\x40",'cp932',   'cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\x20\x20",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\x81\x7C"        }},"\x81\x7C"        ],
        ["\x81\x40",'cp932ibm','cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\x20\x20",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\x81\x7C"        }},"\x81\x7C"        ],
        ["\x81\x40",'cp932nec','cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\x20\x20",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\x81\x7C"        }},"\x81\x7C"        ],
        ["\x81\x40",'sjis2004','cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\x20\x20",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\x81\xAF"        }},"\x81\xAF"        ],
        ["\x81\x40",'cp00930', 'cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\x44\xE2",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\xE9\xF3"        }},"\xE9\xF3"        ],
        ["\x81\x40",'keis78',  'cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\x40\x40",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\xA1\xDD"        }},"\xA1\xDD"        ],
        ["\x81\x40",'keis83',  'cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\x40\x40",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\xA1\xDD"        }},"\xA1\xDD"        ],
        ["\x81\x40",'keis90',  'cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\x40\x40",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\xA1\xDD"        }},"\xA1\xDD"        ],
        ["\x81\x40",'jef',     'cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\x40\x40",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\xA1\xDD"        }},"\xA1\xDD"        ],
        ["\x81\x40",'jef9p',   'cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\x40\x40",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\xA1\xDD"        }},"\xA1\xDD"        ],
        ["\x81\x40",'jipsj',   'cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\x20\x20",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\x21\x5D"        }},"\x21\x5D"        ],
        ["\x81\x40",'jipse',   'cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\x40\x40",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\x4F\x5A"        }},"\x4F\x5A"        ],
        ["\x81\x40",'letsj',   'cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\xA1\xA1",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\xA1\xDD"        }},"\xA1\xDD"        ],
        ["\x81\x40",'utf8',    'cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\x20\x20",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\xEF\xBC\x8D"    }},"\xEF\xBC\x8D"    ],
        ["\x81\x40",'utf8.1',  'cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\x20\x20",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\xEF\xBC\x8D"    }},"\xEF\xBC\x8D"    ],
        ["\x81\x40",'utf8jp',  'cp932x',{'INPUT_LAYOUT'=>'D','SPACE'=>"\x20\x20",'OVERRIDE_MAPPING'=>{"\x81\x40"=>"\xF3\xB0\x84\xBC"}},"\xF3\xB0\x84\xBC"],

# U+32FF SQUARE ERA NAME REIWA
# https://unicode.org/versions/Unicode12.1.0/
# http://en.glyphwiki.org/wiki/u32ff
# https://www.ibm.com/support/pages/zos%E3%81%AB%E3%81%8A%E3%81%91%E3%82%8B%E6%96%B0%E5%85%83%E5%8F%B7%E5%AF%BE%E5%BF%9C%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6
# http://www.hitachi-support.com/alert/ss/HWS17-007/list.pdf#page=29

        ["\xE8\x60",    'cp00930','cp00930',{'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE8\x60"=>"\xE8\x60"        }},"\xE8\x60"        ],
        ["\xE8\x60",    'keis78', 'cp00930',{'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE8\x60"=>"\x73\xFA"        }},"\x73\xFA"        ],
        ["\xE8\x60",    'keis83', 'cp00930',{'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE8\x60"=>"\x73\xFA"        }},"\x73\xFA"        ],
        ["\xE8\x60",    'keis90', 'cp00930',{'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE8\x60"=>"\x73\xFA"        }},"\x73\xFA"        ],
        ["\xE8\x60",    'utf8',   'cp00930',{'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE8\x60"=>"\xE3\x8B\xBF"    }},"\xE3\x8B\xBF"    ],
        ["\xE8\x60",    'utf8.1', 'cp00930',{'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE8\x60"=>"\xE3\x8B\xBF"    }},"\xE3\x8B\xBF"    ],

        ["\x73\xFA",    'cp00930','keis78', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\xE8\x60"        }},"\xE8\x60"        ],
        ["\x73\xFA",    'keis78', 'keis78', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\x73\xFA"        }},"\x73\xFA"        ],
        ["\x73\xFA",    'keis83', 'keis78', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\x73\xFA"        }},"\x73\xFA"        ],
        ["\x73\xFA",    'keis90', 'keis78', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\x73\xFA"        }},"\x73\xFA"        ],
        ["\x73\xFA",    'utf8',   'keis78', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\xE3\x8B\xBF"    }},"\xE3\x8B\xBF"    ],
        ["\x73\xFA",    'utf8.1', 'keis78', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\xE3\x8B\xBF"    }},"\xE3\x8B\xBF"    ],

        ["\x73\xFA",    'cp00930','keis83', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\xE8\x60"        }},"\xE8\x60"        ],
        ["\x73\xFA",    'keis78', 'keis83', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\x73\xFA"        }},"\x73\xFA"        ],
        ["\x73\xFA",    'keis83', 'keis83', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\x73\xFA"        }},"\x73\xFA"        ],
        ["\x73\xFA",    'keis90', 'keis83', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\x73\xFA"        }},"\x73\xFA"        ],
        ["\x73\xFA",    'utf8',   'keis83', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\xE3\x8B\xBF"    }},"\xE3\x8B\xBF"    ],
        ["\x73\xFA",    'utf8.1', 'keis83', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\xE3\x8B\xBF"    }},"\xE3\x8B\xBF"    ],

        ["\x73\xFA",    'cp00930','keis90', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\xE8\x60"        }},"\xE8\x60"        ],
        ["\x73\xFA",    'keis78', 'keis90', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\x73\xFA"        }},"\x73\xFA"        ],
        ["\x73\xFA",    'keis83', 'keis90', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\x73\xFA"        }},"\x73\xFA"        ],
        ["\x73\xFA",    'keis90', 'keis90', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\x73\xFA"        }},"\x73\xFA"        ],
        ["\x73\xFA",    'utf8',   'keis90', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\xE3\x8B\xBF"    }},"\xE3\x8B\xBF"    ],
        ["\x73\xFA",    'utf8.1', 'keis90', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\x73\xFA"=>"\xE3\x8B\xBF"    }},"\xE3\x8B\xBF"    ],

        ["\xE3\x8B\xBF",'cp00930','utf8',   {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE3\x8B\xBF"=>"\xE8\x60"    }},"\xE8\x60"        ],
        ["\xE3\x8B\xBF",'keis78', 'utf8',   {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE3\x8B\xBF"=>"\x73\xFA"    }},"\x73\xFA"        ],
        ["\xE3\x8B\xBF",'keis83', 'utf8',   {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE3\x8B\xBF"=>"\x73\xFA"    }},"\x73\xFA"        ],
        ["\xE3\x8B\xBF",'keis90', 'utf8',   {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE3\x8B\xBF"=>"\x73\xFA"    }},"\x73\xFA"        ],
        ["\xE3\x8B\xBF",'utf8',   'utf8',   {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE3\x8B\xBF"=>"\xE3\x8B\xBF"}},"\xE3\x8B\xBF"    ],
        ["\xE3\x8B\xBF",'utf8.1', 'utf8',   {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE3\x8B\xBF"=>"\xE3\x8B\xBF"}},"\xE3\x8B\xBF"    ],

        ["\xE3\x8B\xBF",'cp00930','utf8.1', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE3\x8B\xBF"=>"\xE8\x60"    }},"\xE8\x60"        ],
        ["\xE3\x8B\xBF",'keis78', 'utf8.1', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE3\x8B\xBF"=>"\x73\xFA"    }},"\x73\xFA"        ],
        ["\xE3\x8B\xBF",'keis83', 'utf8.1', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE3\x8B\xBF"=>"\x73\xFA"    }},"\x73\xFA"        ],
        ["\xE3\x8B\xBF",'keis90', 'utf8.1', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE3\x8B\xBF"=>"\x73\xFA"    }},"\x73\xFA"        ],
        ["\xE3\x8B\xBF",'utf8',   'utf8.1', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE3\x8B\xBF"=>"\xE3\x8B\xBF"}},"\xE3\x8B\xBF"    ],
        ["\xE3\x8B\xBF",'utf8.1', 'utf8.1', {'INPUT_LAYOUT'=>'D',                'OVERRIDE_MAPPING'=>{"\xE3\x8B\xBF"=>"\xE3\x8B\xBF"}},"\xE3\x8B\xBF"    ],
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
        $option_content .= qq{INPUT_LAYOUT=>$option->{'INPUT_LAYOUT'},}        if exists $option->{'INPUT_LAYOUT'};
        $option_content .= qq{OUTPUT_SHIFTING=>$option->{'OUTPUT_SHIFTING'},}  if exists $option->{'OUTPUT_SHIFTING'};
        $option_content .= qq{SPACE=>@{[uc unpack('H*',$option->{'SPACE'})]},} if exists $option->{'SPACE'};
        $option_content .= qq{GETA=>@{[uc unpack('H*',$option->{'GETA'})]},}   if exists $option->{'GETA'};
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
