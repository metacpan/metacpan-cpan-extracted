######################################################################
#
# 0301_fix_erratas-2.13.6.18.t
#
# Copyright (c) 2021 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use vars qw(@test);
    @test = (
        ['芺', 'keis78', 'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['覀', 'keis78', 'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['麽', 'keis78', 'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x6D\xFB"],
        ['芺', 'keis83', 'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['覀', 'keis83', 'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['麽', 'keis83', 'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x6D\xFB"],
        ['芺', 'keis90', 'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['覀', 'keis90', 'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['麽', 'keis90', 'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x6D\xFB"],
        ['漼', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['臽', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['海', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x55\xFB"],
        ['渚', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\xBD\xED"],
        ['漢', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x56\xE6"],
        ['煮', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x58\xA7"],
        ['爫', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['社', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xD3"],
        ['祉', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xD5"],
        ['祈', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xD4"],
        ['祐', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xD6"],
        ['祖', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xD7"],
        ['祝', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xD9"],
        ['禍', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xE2"],
        ['禎', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xE3"],
        ['穀', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xF4"],
        ['突', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5D\xCD"],
        ['縉', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['署', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5F\xF0"],
        ['者', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x60\xB5"],
        ['臭', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x60\xE3"],
        ['艹', 'jef',    'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['漼', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['臽', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['海', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x55\xFB"],
        ['渚', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\xBD\xED"],
        ['漢', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x56\xE6"],
        ['煮', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x58\xA7"],
        ['爫', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['社', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xD3"],
        ['祉', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xD5"],
        ['祈', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xD4"],
        ['祐', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xD6"],
        ['祖', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xD7"],
        ['祝', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xD9"],
        ['禍', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xE2"],
        ['禎', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xE3"],
        ['穀', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5C\xF4"],
        ['突', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5D\xCD"],
        ['縉', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['署', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x5F\xF0"],
        ['者', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x60\xB5"],
        ['臭', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x60\xE3"],
        ['艹', 'jef9p',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['Ý',  'jipsj',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['耰', 'jipsj',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['Ý',  'jipse',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
        ['耰', 'jipse',  'utf8.1', {'INPUT_LAYOUT'=>'D'}, "\x00\x00"],
    );
    $|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }
}

use Jacode4e;

for my $test (@test) {
    my($give,$OUTPUT_encoding,$INPUT_encoding,$option,$want) = @{$test};
    my $got = $give;
    $option->{'GETA'} = "\x00\x00";
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

__DATA__
