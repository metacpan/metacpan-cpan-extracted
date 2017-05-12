use strict;
use warnings;
use utf8;
use Test::More tests => 7;

use Lingua::ZH::MMSEG;

$_ = '整理完房間就會想在房間念書';
my @arr = fmm;
is $arr[0], '整理', '整理';
is $arr[1], '完', '完';
is $arr[2], '房間','房間';
is $arr[3], '就會','就會';
is $arr[4], '想在','想在';
is $arr[5], '房間','房間';
is $arr[6], '念書','念書';

