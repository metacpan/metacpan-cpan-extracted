use Test::More tests=>6;
chdir "t";
no warnings;

require Dtest;
use warnings;
use strict;

dtest("tag_unparsed.html","A{{ C }}AB{% unparsed %}{{ C }}B{% endunparsed %}A&lt;C&gt;AA&lt;D&gt;A<D>AAx&lt;d&gt;xAx<d>x\n",{});
