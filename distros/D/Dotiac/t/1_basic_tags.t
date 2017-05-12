use Test::More tests=>313;
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
require Dtest;

package foo;
sub new {
	bless [],shift;
}
sub text {
	return "XxccxX";
}

package main;


dtest("tag_autoescape.html","A&'\"A&amp;&#39;&quot;A\n",{X=>"&'\""});
dtest("tag_block.html","ABABA\n",{});
dtest("tag_extends.html","ACACA\n",{});
dtest("tag_extends_var.html","ACACA\n",{VAR=>"tag_block.html"});
dtest("tag_extends_var.html","ACACA\n",{VAR=>Dotiac::DTL->new("tag_block.html")});
Dotiac::DTL->newandcompile("tag_block.html");
dtest("tag_extends_var.html","ACACA\n",{VAR=>"tag_block.html"});
dtest("tag_extends_var.html","ACACA\n",{VAR=>Dotiac::DTL->new("tag_block.html")});
unlink "tag_block.html.pm";
dtest("tag_comment.html","AA\n",{});
dtest("tag_cycle.html","ACABACA\n",{qw/C C/});
dtest("tag_cycle_for.html","ACABACA\n",{L=>[qw/A A/,'']});
dtest("tag_cycle_for2.html","A+0A=B-1X=Y+2A=B-3X=YA\n",{L=>[0 .. 3]});
dtest("tag_cycle_for3.html","ABCABCDEFGA\n",{L=>[0 .. 9]});
dtest("tag_cycle_for4.html","ABCABC23451\n",{L=>[2 .. 11]});
#dtest("tag_debug.html","",{L=>[1 .. 5],P=>"FOO"}); #Can't test debug...
dtest("tag_filter.html","Aba_abA\n",{P=>"VV_VVVV"});
dtest("tag_firstof.html","ABACABA\n",{B=>"B",C=>'c'});
dtest("tag_for_array.html","ABACABA\n",{loop=>[qw/B A C A B/]});
dtest("tag_for_array2.html","ABACABA\n",{loop=>[qw/B A C A B/]});
dtest("tag_for_hash.html","AABBACCA\n",{loop=>{qw/B A C C A B/}});
dtest("tag_for_hash2.html","AABBACCA\n",{loop=>{qw/B A C C A B/}});
dtest("tag_for_hash3.html","ACCBAABA\n",{loop=>{qw/B A C C A B/}});
dtest("tag_for_hash4.html","ACCBAABA\n",{loop=>{qw/B A C C A B/}});
dtest("tag_for_array3.html","AABCCBAA\n",{loop=>[[qw/A B C/],[qw/C B A/]]});
dtest("tag_for_array4.html","ACBAABCA\n",{loop=>[[qw/A B C/],[qw/C B A/]]});
dtest("tag_for_vars.html","A110A2321B1232C011A\n",{loop=>[qw/A B C/]});
dtest("tag_for_vars.html","A110AB2321BA1232CC011A\n",{loop=>{qw/B A C C A B/}});
dtest("tag_for_nested.html","A111213212223313233A\n",{loop=>{qw/B A C C A B/}});
dtest("tag_if.html","ABACABA\n",{});
dtest("tag_if2.html","ABACABA\n",{A=>1,B=>0});
my $s="";
my $t=bless({},"FOO");
dtest("tag_if_true.html","ABACABA\n",{A=>1,B=>"a",C=>\$s,D=>[1],E=>{A=>1},F=>$t});
dtest("tag_if_true.html","Abacaba\n",{A=>0,B=>"",C=>undef,D=>[],E=>{},F=>0.0e0});
dtest("tag_if_and.html","ABACABA\n",{A=>1,B=>1,C=>0});
dtest("tag_if_and.html","AbAcAbA\n",{A=>0,B=>0,C=>1});
dtest("tag_if_or.html","ABACABA\n",{A=>0,B=>0,C=>0});
dtest("tag_if_or.html","ABACABA\n",{A=>1,B=>0,C=>1});
dtest("tag_if_or.html","ABACABA\n",{A=>0,B=>1,C=>1});
dtest("tag_if_or.html","AbAcAbA\n",{A=>0,B=>0,C=>1});
dtest("tag_ifchanged.html","ABACABA\n",{loop=>[qw/A A B B B B A C C C A A A B A A/]});
dtest("tag_ifchanged_var.html","ABACABA\n",{loop=>[{value=>"A",changed=>1},{value=>"4",changed=>1},{value=>"B",changed=>2},{value=>"66",changed=>2},{value=>"A",changed=>3},{value=>"A",changed=>3},{value=>"C",changed=>4},{value=>"Ddd",changed=>4},{value=>"foo",changed=>4},{value=>"A",changed=>5},{value=>"B",changed=>6},{value=>"meep!",changed=>6},{value=>"A",changed=>7},{value=>"7756",changed=>7}]});
dtest("tag_ifchanged_else.html","ABACABA\n",{loop=>[qw/B B C C B B/]});
dtest("tag_ifchanged_var_else.html","ABACABA\n",{loop=>[{value=>"A",changed=>1},{value=>"B",changed=>2},{value=>"66",changed=>2},{value=>"C",changed=>3},{value=>"<S-Del>",changed=>3},{value=>"B",changed=>4},{value=>"Ddd",changed=>4}]});
dtest("tag_ifequal.html","ABACACABA\n",{INT1=>1,INT2=>1,INT3=>2,S1=>"Foo",S2=>"Foo",S3=>"Bar",A1=>[1],A2=>[2],A3=>[2,2],H1=>{A=>1},H2=>{V=>3},H3=>{A=>3,B=>4}});
dtest("tag_ifnotequal.html","ABACACABA\n",{INT1=>1,INT2=>1,INT3=>2,S1=>"Foo",S2=>"Foo",S3=>"Bar",A1=>[1],A2=>[2],A3=>[2,2],H1=>{A=>1},H2=>{V=>3},H3=>{A=>3,B=>4}});
my $inc=Dotiac::DTL->new("inc_var.html");
dtest("tag_include.html","AB\nACA\nB\nA\n",{var1=>B=>var2=>C=>inc_name=>"inc_more.html",inc_object=>$inc});
dtest("tag_include.html","AB\nACACA\nB\nA\n",{var1=>B=>var2=>C=>inc_name=>"inc_more2.html",inc_object=>$inc});
dtest("tag_load.html","ABACABA\n",{});
dtest("tag_regroup.html","ABACABA\n",{loop=>[{name=>"A",text=>"B"},{name=>"A",text=>"A"},{name=>"C",text=>"A"},{name=>"B",text=>"A"}]});
dtest("tag_regroup2.html","aBAcAbA\n",{loop=>[{name=>"A",text=>"B"},{name=>"A",text=>"A"},{name=>"C",text=>"A"},{name=>"B",text=>"A"}]});
dtest("tag_spaceless.html","<br> <br>  AB  <p> </p> <b> BA </b> <br>\n",{});
dtest("tag_templatetags.html","{%%}{{}}{}{##}\n",{});
dtest("tag_url.html","A/bee?zee=dii&amp;E=F A/BEE?ZEE=DII&E=F A/bee?zee=dii&E=F A/BEE?ZEE=DII&amp;E=F\n",{B=>"bee",C=>"zee",D=>"dii",E=>"EEH"});
dtest("tag_widthratio.html","A20C17A\n",{A=>14,B=>28});
my $x=new foo;
dtest("tag_with.html","ABaCCaBA\n",{foo=>$x,X=>{X=>"a"}});
__DATA__


