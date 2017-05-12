use Test::More tests=>1;
chdir "t";
no warnings;

#require Dtest;
use warnings;
use strict;

use Dotiac::DTL::Addon::html_template::Convert qw/combine/;

#Combine
{
	my $tx="<TMPL_IF NAME=test>{{ test }}</TMPL_IF>";
	my $template=HTML::Template->new("scalarref",\$tx,case_sensitive=>1);
	$template->param("test","Hello World");
	is($template->output(),"Hello World","Html::Template + Django combine");
}
