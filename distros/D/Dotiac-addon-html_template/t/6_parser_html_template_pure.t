use Test::More tests => 104;
eval {
	require Test::NoWarnings;
	Test::NoWarnings->import();
	#pass "Yo";
	1;
} or do {
	SKIP: {
		skip "Test::NoWarnings is not installed", 1;
		fail "This shouldn't really happen at all";
	};
};

chdir "t";
require Dtest;
use strict;
use warnings;


use_ok('Dotiac::DTL::Addon::html_template_pure');
use Dotiac::DTL::Addon::html_template_pure;

dtest("parser_pure_var1.html","ABABABABABABA\n",{test=>"B"},"TMPL_VAR");
dtest("parser_pure_var2.html","A<>A<>A<>A<>A<>A<>A\n",{test=>"<>"},"Autoescape off?");
$Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}="html";
dtest("parser_pure_var_html.html","A&lt;&#39;&gt;A<'>A<'>A&lt;&#39;&gt;A%3C%27%3EA<\\'>A\n",{test=>"<'>"},"Autoescape html?");
$Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}="js";
dtest("parser_pure_var_js.html","A<\\'>A<'>A<'>A&lt;&#39;&gt;A%3C%27%3EA<\\'>A\n",{test=>"<'>"},"Autoescape JS?");
$Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}="url";
dtest("parser_pure_var_url.html","A%3C%27%3EA<'>A<'>A&lt;&#39;&gt;A%3C%27%3EA<\\'>A\n",{test=>"<'>"},"Autoescape URL?");
$Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}="";
dtest("parser_pure_doublevar_no.html","A&lt;\\&#39;&gt;A\n",{test=>"<'>"},"doubleescape normal");
$Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}="html";
dtest("parser_pure_doublevar_html.html","A&lt;\\&#39;&gt;A\n",{test=>"<'>"},"doubleescape html");
$Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}="";
dtest("parser_pure_if.html","ABABABA\n",{test=>"B"},"TMPL_IF");
dtest("parser_pure_unless.html","ABABABA\n",{test=>"B"},"TMPL_IF");
dtest("parser_pure_loop.html","ABACDAEA\n",{text=>"X",title=>"X",loop=>[{title=>"B",text=>"C"},{title=>"D",text=>"E"}]},"TMPL_LOOP");
dtest("parser_pure_loop.html","AXACDAXA\n",{text=>"X",title=>"X",loop=>[{text=>"C"},{title=>"D"}]},"TMPL_LOOP merged");
$Dotiac::DTL::Addon::html_template_pure::OPTIONS{global_vars}=0;
dtest("parser_pure_loop2.html","AACDAA\n",{text=>"X",title=>"X",loop=>[{text=>"C"},{title=>"D"}]},"TMPL_LOOP unmerged");
$Dotiac::DTL::Addon::html_template_pure::OPTIONS{global_vars}=1;
dtest("parser_pure_loop_vars.html","A1<>:1!\n<1>:2\n<1>:3!\n<>1:4\nA\n",{loop=>[{},{},{},{}]},"TMPL_LOOP context vars");
$Dotiac::DTL::Addon::html_template_pure::OPTIONS{loop_context_vars}=0;
dtest("parser_pure_loop_vars2.html","A<>:\n<>:\n<>:\n<>:\nA\n",{loop=>[{},{},{},{}]},"TMPL_LOOP no context vars");
$Dotiac::DTL::Addon::html_template_pure::OPTIONS{loop_context_vars}=1;
dtest("parser_pure_include.html","AB\nA\n",{test=>"B"},"TMPL_INCLUDE");
dtest("test.tmpl"," <html>\n  <head><title>Test Template</title>\n  <body>\n  My Home Directory is /bin\n  <p>\n  My Path is set to /FOO;/BAR\n  </body>\n  </html>\n",{PATH => "/FOO;/BAR",HOME=>"/bin"},"H::T Example");
dtest("tag_autoescape.html","A{% autoescape off %}{{ X }}A{% autoescape on %}{{ X }}{% endautoescape %}A{% endautoescape %}\n",{},"Pure test");
