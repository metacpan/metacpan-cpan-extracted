use Test::More tests=>30;
chdir "t";
no warnings;

require Dtest;
use warnings;
use strict;

dtest("special_ci.html","ABABABABA\n",{data=>"B"});
dtest("special_ci2.html","ACACACACA\n",{data=>{foo=>"C"}});
dtest("special_ci2.html","ADADADADA\n",{data=>FOO->new()});
dtest("special_ci_off.html","AABAAA\n",{data=>"B"});
dtest("special_ci_static.html","ABABABABA\n",{});

package FOO;

sub new {
	bless {},shift;
}

sub foo {
	return "D";
}
