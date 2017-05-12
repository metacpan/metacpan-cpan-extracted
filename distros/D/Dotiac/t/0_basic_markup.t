use Test::More tests => 64;
eval {
	require Test::NoWarnings;
	Test::NoWarnings->import();
	1;
} or do {
	SKIP: {
		skip "Test::NoWarnings is not installed", 1;
		fail "This shouldn't really happen at all";
	};
};

chdir "t";

require_ok('Dotiac::DTL');
require Dtest;
use strict;
use warnings;

package foo;
sub new {
	bless {member=>"A"},shift;
}
sub func {
	return "AC";
}

package foo2;
sub new {
	bless ["A"],shift;
}
sub func {
	return "D";
}
package main;

my $foo=new foo;
my $foo2=new foo2;

#From scalar
my $a="A{# b #}A{# C #}A{#
D #}A";
my $t=Dotiac::DTL->new(\$a);
ok($t,"Creating Template from scalar");
is($t->string(),"AAAA","String output from scalar created template");
is($t->string(),"AAAA","String output from scalar created template again");
dtest("justtext.html","AAAA\n",{});
dtest("comments.html","AAAA\n",{});
dtest("variables.html","ABACABA\n",{var=>"B",var2=>"C"});
dtest("variables1.html","AAAA\n",{});
$Dotiac::DTL::AUTOESCAPING=0;
dtest("statics.html","AB{{A'\"'A}}BA\n",{});
dtest("variables2.html","A<&>A'\"'A<&>A\n",{var=>"<&>",var2=>"'\"'"});
$Dotiac::DTL::AUTOESCAPING=1;
dtest("statics.html","AB{{A\'\"\'A}}BA\n",{});
dtest("variables2.html","A&lt;&amp;&gt;A&#39;&quot;&#39;A&lt;&amp;&gt;A\n",{var=>"<&>",var2=>"'\"'"});
#die $foo,$foo2;
dtest("datastructures.html","ABACADABA\n",{array=>["A",[0,"B"]],object=>$foo,aobject=>$foo2,hash=>{value=>"B",subhash=>{value=>"A"}}});
unlink "variables3.html.pm";
$t=Dotiac::DTL->new("variables3.html");
is_deeply([sort $t->param()],['var','var2'],"Saved parameters from normal template");
$t=Dotiac::DTL->new("variables3.html",1);
is_deeply([sort $t->param()],['var','var2'],"Saved parameters from cached template");
$t=Dotiac::DTL->new("variables3.html",1);
ok($t->{first}->isa("Dotiac::DTL::Compiled"),"variables3.html a compiled template");
$t=Dotiac::DTL->new("variables3.html",1);
ok($t->{first}->isa("Dotiac::DTL::Compiled"),"variables3.html a cached compiled template");
is_deeply([sort $t->param()],['var','var2'],"Saved parameters from compiled template");
unlink "variables3.html.pm";
