#!/usr/bin/perl -w
use Lingua::StarDict::Gen;

my $dic=Lingua::StarDict::Gen::carregaDic("microEN-PT.dic");
Lingua::StarDict::Gen::escreveDic($dic,"microEN-PT");
