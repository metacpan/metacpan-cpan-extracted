use Test::More tests=>3;
chdir "t";
no warnings;

#require Dtest;
use warnings;
use strict;

use Dotiac::DTL::Addon::html_template::Replace qw/combine/;

#Combine
{
	my $tx="<TMPL_IF NAME=test>{{ test }}</TMPL_IF>";
	my $template=HTML::Template->new("scalarref",\$tx,case_sensitive=>1);
	$template->param("test","Hello World");
	is($template->output(),"Hello World","Html::Template + Django combine");
}
{
	my $tx="<TMPL_IF NAME=test>{{ test }}</TMPL_IF>";
	my $template=HTML::Template->new("scalarref",\$tx,case_sensitive=>1,default_escape=>"html");
	$template->param("test","<>");
	is($template->output(),"&lt;&gt;","Html::Template + Django combine");
}
{
	my $tx="<TMPL_IF NAME=test>{{ test }}</TMPL_IF>";
	my $template=HTML::Template->new("scalarref",\$tx,case_sensitive=>1,default_escape=>"url");
	$template->param("test","<>");
	is($template->output(),"<>","Html::Template + Django combine");
}
