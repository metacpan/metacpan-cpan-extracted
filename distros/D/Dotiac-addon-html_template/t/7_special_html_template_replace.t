use Test::More tests=>40;
no warnings;

sub nor {
	my $value=shift;
	return $value unless $value;
	$value=~s/\r//g;
	return $value;
}

use warnings;
use strict;

use Dotiac::DTL::Addon::html_template::Replace;

#Var tests.
{
	my $tx="Hello <TMPL_VAR test>";
	my $template=HTML::Template->new("scalarref",\$tx);
	ok($template->isa("Dotiac::DTL::Template"),"Generated template is a Dotiac Template");
	$template->param("test","<'>");
	is($template->output(),"Hello <'>","Html::Template Converter short");
}
{
	my $tx="Hello <TMPL_VAR NAME=test>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("test","<'>");
	is($template->output(),"Hello <'>","Html::Template Converter normal");
}
{
	my $tx="Hello <TMPL_VAR TeST>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("test","<'>");
	is($template->output(),"Hello <'>","Html::Template Converter short");
}
#Escaping tests:
{
	my $tx="Hello <TMPL_VAR NAME='test' ESCAPE=HTML>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("test","<'>");
	is($template->output(),"Hello &lt;&#39;&gt;","Html::Template Converter html");
}
{
	my $tx="Hello <TMPL_VAR 'test' ESCAPE=HTML>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("test","<'>");
	is($template->output(),"Hello &lt;&#39;&gt;","Html::Template Converter short html");
}
{
	my $tx="Hello <TMPL_VAR NAME='test' ESCAPE=\"JS\">";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("test","<'>");
	is($template->output(),"Hello <\\'>","Html::Template Converter js");
}
{
	my $tx="Hello <!-- TMPL_VAR 'test' ESCAPE='JS' -->";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("test","<'>");
	is($template->output(),"Hello <\\'>","Html::Template Converter short js");
}
{
	my $tx="Hello <TMPL_VAR NAME='test' ESCAPE=URL>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("test","<'>");
	is($template->output(),"Hello %3C%27%3E","Html::Template Converter url");
}
{
	my $tx="Hello <!-- TMPL_VAR 'test' ESCAPE='URL' -->";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("test","<'>");
	is($template->output(),"Hello %3C%27%3E","Html::Template Converter short url");
}
#Stacking
{
	my $tx="Hello <TMPL_VAR NAME='test' ESCAPE=\"JS\" ESCAPE='HTML'>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("test","<\">");
	is($template->output(),"Hello &lt;\\&quot;&gt;","Html::Template Converter stacking");
}
#Defaultescape:
{
	my $tx="<TMPL_VAR test>,<TMPL_VAR NAME='test' ESCAPE='JS'>,<TMPL_VAR NAME='test' ESCAPE='URL'>,<TMPL_VAR NAME='test' ESCAPE='HTML'>, <TMPL_VAR 'test' ESCAPE=0>";
	my $template=HTML::Template->new("scalarref",\$tx,default_escape=>"HTML");
	$template->param("test","<'>");
	is($template->output(),"&lt;&#39;&gt;,<\\'>,%3C%27%3E,&lt;&#39;&gt;, <'>","Html::Template Converter default=html");
}
{
	my $tx="<TMPL_VAR test>,<TMPL_VAR NAME='test' ESCAPE='JS'>,<TMPL_VAR NAME='test' ESCAPE='URL'>,<TMPL_VAR NAME='test' ESCAPE='HTML'>, <TMPL_VAR 'test' ESCAPE=0>";
	my $template=HTML::Template->new("scalarref",\$tx,default_escape=>"JS");
	$template->param("test","<'>");
	is($template->output(),"<\\'>,<\\'>,%3C%27%3E,&lt;&#39;&gt;, <'>","Html::Template Converter default=js");
}
{
	my $tx="<TMPL_VAR test>,<TMPL_VAR NAME='test' ESCAPE='JS'>,<TMPL_VAR NAME='test' ESCAPE='URL'>,<TMPL_VAR NAME='test' ESCAPE='HTML'>, <TMPL_VAR 'test' ESCAPE=0>";
	my $template=HTML::Template->new("scalarref",\$tx,default_escape=>"URL");
	$template->param("test","<'>");
	is($template->output(),"%3C%27%3E,<\\'>,%3C%27%3E,&lt;&#39;&gt;, <'>","Html::Template Converter default=url");
}
#Default:
{
	my $tx="<TMPL_VAR test DEFAULT='\"'>,<TMPL_VAR NAME='test' ESCAPE='JS' DEFAULT=\"Foo\">,<TMPL_VAR NAME='test' ESCAPE='URL' DEFAULT='Foo'>,<TMPL_VAR NAME='test' ESCAPE='HTML' DEFAULT=Foo >, <TMPL_VAR 'test' ESCAPE=0 DEFAULT='Foo'>";
	my $template=HTML::Template->new("scalarref",\$tx,default_escape=>"HTML");
	$template->param("test","<'>");
	is($template->output(),"&lt;&#39;&gt;,<\\'>,%3C%27%3E,&lt;&#39;&gt;, <'>","Html::Template Converter default known, escape=html");
}
{
	my $tx="<TMPL_VAR test DEFAULT='\"'>,<TMPL_VAR NAME='test' ESCAPE='JS' DEFAULT=\"'\">,<TMPL_VAR NAME='test' ESCAPE='URL' DEFAULT='Foo'>,<TMPL_VAR NAME='test' ESCAPE='HTML' DEFAULT=Foo>, <TMPL_VAR 'test' ESCAPE=0 DEFAULT=\"Foo\">";
	my $template=HTML::Template->new("scalarref",\$tx,default_escape=>"HTML");
	$template->param("x","<'>");
	is($template->output(),"\",\',Foo,Foo, Foo","Html::Template Converter default known, escape=html");
}
{
	my $tx="Hello <TMPL_VAR ESCAPE='HTML'>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("test","<'>");
	is($template->output(),"Hello ","Html::Template Converter no var");
}
{
	my $tx="Hello <TMPL_VAR DEFAULT='FOO'>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("test","<'>");
	is($template->output(),"Hello FOO","Html::Template Converter no var default");
}
#IF:
{
	my $tx="Hello <TMPL_IF test>World</TMPL_IF>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("test","<'>");
	is($template->output(),"Hello World","Html::Template Converter if no else true");
}
{
	my $tx="Hello <TMPL_IF Name=\"test\">World</TMPL_IF>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("x","<'>");
	is($template->output(),"Hello ","Html::Template Converter if no else false");
}
{
	my $tx="Hello <TMPL_IF name=test>World<TMPL_ELSE>Nothing</TMPL_IF>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("test","<'>");
	is($template->output(),"Hello World","Html::Template Converter if else true");
}
{
	my $tx="Hello <TMPL_IF Name='test'>World<TMPL_ELSE>Nothing</TMPL_IF>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("x","<'>");
	is($template->output(),"Hello Nothing","Html::Template Converter if else false");
}
#UNLESS:
{
	my $tx="Hello <TMPL_UNLESS test>World</TMPL_UNLESS>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("x","<'>");
	is($template->output(),"Hello World","Html::Template Converter unless no else true");
}
{
	my $tx="Hello <TMPL_UNLESS Name=\"test\">World</TMPL_UNLESS>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("test","<'>");
	is($template->output(),"Hello ","Html::Template Converter unless no else false");
}
{
	my $tx="Hello <TMPL_UNLESS name=test>World<TMPL_ELSE>Nothing</TMPL_UNLESS>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("x","<'>");
	is($template->output(),"Hello World","Html::Template Converter unless else true");
}
{
	my $tx="Hello <TMPL_UNLESS Name='test'>World<TMPL_ELSE>Nothing</TMPL_UNLESS>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("test","<'>");
	is($template->output(),"Hello Nothing","Html::Template Converter unless else false");
}
#LOOP normal
{
	my $tx="<TMPL_loop loop><TMPL_VAR 'T'>_<TMPL_VAR Name='S'>,</TMPL_LOOP>";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("loop",[{T=>"A",S=>"a"},{T=>"B",S=>"b"},{T=>"C",S=>"c"}]);
	is($template->output(),"A_a,B_b,C_c,","Html::Template Converter loop");
}
#Global_vars
{
	my $tx="<TMPL_loop name=loop><TMPL_VAR T>_<TMPL_VAR S><TMPL_VAR TT>,</TMPL_LOOP>";
	my $template=HTML::Template->new("scalarref",\$tx,global_vars=>0);
	$template->param("loop",[{T=>"A",S=>"a"},{T=>"B",S=>"b"},{T=>"C",S=>"c"}]);
	$template->param("T","X");
	$template->param("TT","X");
	is($template->output(),"A_a,B_b,C_c,","Html::Template Converter loop");
}
{
	my $tx="<TMPL_loop name=loop><TMPL_VAR T>_<TMPL_VAR S><TMPL_VAR TT>,</TMPL_LOOP>";
	my $template=HTML::Template->new("scalarref",\$tx,global_vars=>1);
	$template->param("loop",[{T=>"A",S=>"a"},{T=>"B",S=>"b"},{T=>"C",S=>"c"}]);
	$template->param("T","X");
	$template->param("TT","x");
	is($template->output(),"A_ax,B_bx,C_cx,","Html::Template Converter loop");
}
#Contextvars
{
	my $tx="<TMPL_loop loop><TMPL_IF Name='__first__'>></TMPL_IF><TMPL_VAR __counter__><TMPL_IF NAme=\"__odd__\">0:</TMPL_IF><TMPL_VAR 'T'><TMPL_IF NAME='__inner__'>_</TMPL_IF><TMPL_VAR Name='S'><TMPL_UNLESS Name='__last__'>,</TMPL_IF></TMPL_LOOP>";
	my $template=HTML::Template->new("scalarref",\$tx,loop_context_vars=>1,case_sensitive=>1);
	$template->param("loop",[{T=>"A",S=>"a"},{T=>"B",S=>"b"},{T=>"C",S=>"c"}]);
	is($template->output(),">10:Aa,2B_b,30:Cc","Html::Template Converter loop");
}
{
	my $tx="<TMPL_loop loop><TMPL_IF Name='__first__'>></TMPL_IF><TMPL_VAR __counter__><TMPL_IF NAme=\"__odd__\">0:</TMPL_IF><TMPL_VAR 'T'><TMPL_IF NAME='__inner__'>_</TMPL_IF><TMPL_VAR Name='S'><TMPL_UNLESS Name='__last__'>,</TMPL_IF></TMPL_LOOP>";
	my $template=HTML::Template->new("scalarref",\$tx,loop_context_vars=>1,case_sensitive=>1);
	$template->param("loop",[{T=>"A",S=>"a"},{T=>"B",S=>"b"},{T=>"C",S=>"c"},{T=>"D",S=>"d"}]);
	is($template->output(),">10:Aa,2B_b,30:C_c,4Dd","Html::Template Converter loop");
}
#Combine
{
	my $tx="<TMPL_IF NAME=test>{{ test }}</TMPL_IF>";
	my $template=HTML::Template->new("scalarref",\$tx,case_sensitive=>1);
	$template->param("test","Hello World");
	is($template->output(),"{{ test }}","Html::Template Converter no combine");
}
#Filter
{
	my $tx="<!TMPL_IF NAME=test><!TMPL_VAR NAME=test Escape=HTML><!/TMPL_IF>";
	my $template=HTML::Template->new("scalarref",\$tx,case_sensitive=>1,filter=>sub {${$_[0]}=~s/<!(\/?)TMPL/<$1TMPL/g});
	$template->param("test","Hello World");
	is($template->output(),"Hello World","Html::Template Converter filter");
}
#Bug:
{
	my $tx="Hello {<TMPL_VAR test>}";
	my $template=HTML::Template->new("scalarref",\$tx);
	$template->param("test","<'>");
	is($template->output(),"Hello {<'>}","Html::Template Converter short");
}
#FILE-Filter:
unlink("t/test2.html-nsco.htm");
unlink("t/test2.html-nsco.html");
{
	my $template=HTML::Template->new("filename","t/test2.html",case_sensitive=>1,filter=>[ 
		{'sub'=>sub {${$_[0]}=~s/<!(\/?)TMPL/<$1TMPL/g },
		format=>'scalar' } 
	]);
	$template->param("test","Hello World");
	is(nor($template->output()),"Hello World\n");
}
ok(!-e "t/test2.html-nsco.html","Did not convert, replaced");
ok(-e "t/test2.html-nsco.htm","Did filter and replace");
unlink("t/test2.html-nsco.htm");
#File converter
unlink("t/test1.html-nico.html");
unlink("t/test1.html-nico.htm");
{
	my $template=HTML::Template->new("filename","t/test1.html");
	$template->param("test","World");
	is(nor($template->output()),"Hello, World\n","Html::Template Converter file init");
}
ok(!-e "t/test2.html-nsco.html","Did not convert, replaced");
ok(!-e "t/test2.html-nsco.htm","Didn't filter and replace");
unlink("t/test1.html-nico.html");
unlink("t/test1.html-nico.htm");
