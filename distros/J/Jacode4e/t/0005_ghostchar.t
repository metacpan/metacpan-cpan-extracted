######################################################################
#
# 0005_ghost_test.t
#
# Copyright (c) 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use vars qw(@test);
    @test = (
        ["\x9C\x5A\x9C\x5A",'cp932x',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\x9C\x5A\x9C\x5A"],
        ["\x9C\x5A\x9C\x5A",'cp932',   'cp932x',{'INPUT_LAYOUT'=>'D'},"\x9C\x5A"        ],
        ["\x9C\x5A\x9C\x5A",'cp932ibm','cp932x',{'INPUT_LAYOUT'=>'D'},"\x9C\x5A"        ],
        ["\x9C\x5A\x9C\x5A",'cp932nec','cp932x',{'INPUT_LAYOUT'=>'D'},"\x9C\x5A"        ],
        ["\x9C\x5A\x9C\x5A",'sjis2004','cp932x',{'INPUT_LAYOUT'=>'D'},"\x9C\x5A"        ],
        ["\x9C\x5A\x9C\x5A",'cp00930', 'cp932x',{'INPUT_LAYOUT'=>'D'},"\x59\xCD"        ],
        ["\x9C\x5A\x9C\x5A",'keis78',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\xD7\xBB"        ],
        ["\x9C\x5A\x9C\x5A",'keis83',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\xD7\xBB"        ],
        ["\x9C\x5A\x9C\x5A",'keis90',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\xD7\xBB"        ],
        ["\x9C\x5A\x9C\x5A",'jef',     'cp932x',{'INPUT_LAYOUT'=>'D'},"\xD7\xBB"        ],
        ["\x9C\x5A\x9C\x5A",'jef9p',   'cp932x',{'INPUT_LAYOUT'=>'D'},"\xD7\xBB"        ],
        ["\x9C\x5A\x9C\x5A",'jipsj',   'cp932x',{'INPUT_LAYOUT'=>'D'},"\x57\x3B"        ],
        ["\x9C\x5A\x9C\x5A",'jipse',   'cp932x',{'INPUT_LAYOUT'=>'D'},"\xE6\x5E"        ],
        ["\x9C\x5A\x9C\x5A",'letsj',   'cp932x',{'INPUT_LAYOUT'=>'D'},"\xD7\xBB"        ],
        ["\x9C\x5A\x9C\x5A",'utf8',    'cp932x',{'INPUT_LAYOUT'=>'D'},"\xE5\xBD\x81"    ],
        ["\x9C\x5A\x9C\x5A",'utf8.1',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\xE5\xBD\x81"    ],
        ["\x9C\x5A\x9C\x5A",'utf8jp',  'cp932x',{'INPUT_LAYOUT'=>'D'},"\xF3\xB4\x83\xBE"],
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
