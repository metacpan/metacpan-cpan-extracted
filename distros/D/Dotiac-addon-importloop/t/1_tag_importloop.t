use Test::More tests=>18;
chdir "t";
no warnings;

require Dtest;
use warnings;
use strict;

my @loop=(
	{Title=>"BBB",Text=>"CCC"},
	{Title=>"ddd",Text=>"eee"},
	{Title=>"GGG",Text=>"HHH"},
);

dtest("tag_importloop.html","AaBBBaCCCaadddaeeeaaGGGaHHHaAaGGGaHHHaadddaeeeaaBBBaCCCaAYYY\n",{loop=>\@loop,Text=>"XXX",Foo=>"Z"});
dtest("tag_importloop_merge.html","AaBBBaCCCaZaadddaeeeaZaaGGGaHHHaZaAaGGGaHHHaZaadddaeeeaZaaBBBaCCCaZaAZaYYY\n",{loop=>\@loop,Text=>"XXX",Foo=>"Z"});
dtest("tag_importloop_contextvars.html","\n1<>=1:1aBBBaCCCa\n<1>=2:adddaeeea\n<>1=3:1aGGGaHHHa\n1<>=1:1aGGGaHHHa\n<1>=2:adddaeeea\n<>1=3:1aBBBaCCCa\n\n",{loop=>\@loop,Text=>"XXX",Foo=>"Z"});

