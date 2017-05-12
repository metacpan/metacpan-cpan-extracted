#!/usr/bin/perl -w
use strict;
use Test::Simple tests => 6;
use Metai::Kalendorius;

ok(Metai::Kalendorius->vardai('2006.03.12','www') eq 'Teofanas,Galvirdas,Darmant&#0279;');
ok(Metai::Kalendorius->zodiakas('2006.7.6','www') eq 'V&#0279;&#0380;ys');
ok(Metai::Kalendorius->metu_laikas('2006.12.12','www') eq '&#0381;iema');
ok(Metai::Kalendorius->menuo('2006.04.23','www') eq 'Balandis');
ok(Metai::Kalendorius->diena('2008.12.16','utf-8') eq 'Antradienis');
ok(Metai::Kalendorius->metu_laikas('2008.2.29','www') eq '&#0381;iema');

