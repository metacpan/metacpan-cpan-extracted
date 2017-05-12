#!/usr/bin/perl
# $File: //member/autrijus/Encode-HanDetect/t/1-basic.t $ $Author: autrijus $
# $Revision: #1 $ $Change: 4051 $ $DateTime: 2003/01/30 22:34:14 $

use strict;
use Test::More tests => 4;

use_ok('Encode');
use_ok('Encode::HanDetect');
Encode::HanDetect->import('trad');

is(
    encode(big5 => decode('HanDetect', '硂琌程矮刮挡癬ㄓぱ')),
    '硂琌程矮刮挡癬ㄓぱ',
    'big5 detection',
);

is(
    encode(big5 => decode('HanDetect', '这是最后的斗争，团结起来到明天')),
    '硂琌程ゆ刮挡癬ㄓぱ',
    'gbk detection',
);

1;
