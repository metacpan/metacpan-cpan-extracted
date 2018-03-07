######################################################################
#
# 0002_basic_test.t
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use vars qw(@test);
    @test = (
        ["\x81\x40",            'jef',  'cp932',undef,                    "\xA1\xA1"],
        [("\x81\x40",           'jef',  'cp932',undef)                 => "\xA1\xA1"], # sometimes I trap ((you)).
        ["\x81\x40",            'jef',  'cp932',{}                     => "\xA1\xA1"],
        ["\x81\x40",            'jef',  'cp932',{'SPACE'=>"\x40\x40"}  => "\x40\x40"],
        ["\xFC\xFC",            'jef',  'cp932',{}                     => "\xA2\xAE"],
        ["\xFC\xFC",            'jef',  'cp932',{'GETA'=>"\xFE\xFE"}   => "\xFE\xFE"],
        ["\x28\xA1\xA1",        'cp932','jef',  {}                     => "\x81\x40"],
        ["\x28\xA1\xA1\x29\xF1",'cp932','jef',  {}                     => "\x81\x40\x31"],
        ["\xA1\xA1\xF1",        'cp932','jef',  {'INPUT_LAYOUT'=>'DS'} => "\x81\x40\x31"],
        ["\x81\x40\x31",        'jef',  'cp932',{}                     => "\xA1\xA1\xF1"],
        ["\x81\x40\x31",        'jef',  'cp932',{'OUTPUT_SHIFTING'=>1} => "\x28\xA1\xA1\x29\xF1"],
        ["\xA1\xA1\xFE\xFE\xF1",'jipsj','jef',  {'INPUT_LAYOUT'=>'DDS','OUTPUT_SHIFTING'=>1,'SPACE'=>"\x20\x20",'GETA'=>"\x7E\x7E"} => "\x1A\x70\x20\x20\x7E\x7E\x1A\x71\x31"],
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
