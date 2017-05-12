#!/usr/local/bin/perl
#
# $Id: 05-KANJI.t,v 1.1 2015/03/10 11:04:45 dankogai Exp dankogai $
#
use strict;
use warnings;
use Lingua::JA::Numbers;
use Test::More;
use utf8;
is ja2num("10億") => 1e9;
is ja2num("一二三四五六七八九〇") => 1234567890;
is ja2num("一二三四五六七八九零") => 1234567890;
is ja2num("12億3456万7890")       => 1234567890;
is ja2num("十二億三千四百五十六万七千八百九十") => 1234567890;
done_testing();
__END__
