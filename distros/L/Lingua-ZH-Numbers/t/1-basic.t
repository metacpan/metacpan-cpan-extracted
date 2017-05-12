#!/usr/bin/perl
# $File: //member/autrijus/Lingua-ZH-Numbers/t/1-basic.t $ $Author: autrijus $
# $Revision: #2 $ $Change: 2319 $ $DateTime: 2002/11/23 15:00:30 $

use strict;
print "1..6\n";

print "not " unless eval { require Lingua::ZH::Numbers };
print "ok 1 # require Lingua::ZH::Numbers\n";

print "not " unless Lingua::ZH::Numbers::number_to_zh(12345) eq 'YiWan ErQian SanBai SiShi Wu';
print "ok 2 # simple conversion\n";

print "not " unless Lingua::ZH::Numbers::number_to_zh(0) eq 'Ling';
print "ok 3 # simple conversion\n";

Lingua::ZH::Numbers->charset('big5');
print "not " unless Lingua::ZH::Numbers::number_to_zh(12345) eq '一萬二千三百四十五';
print "ok 4 # big5 conversion\n";

print "not " unless eval { require Lingua::ZH::Numbers::Currency };
print "ok 5 # require Lingua::ZH::Numbers::Currency\n";

Lingua::ZH::Numbers::Currency->charset('big5');
print "not " unless Lingua::ZH::Numbers::Currency::currency_to_zh(12345) eq '壹萬貳仟參佰肆拾伍圓整';
print "ok 6 # big5 conversion\n";

exit;
