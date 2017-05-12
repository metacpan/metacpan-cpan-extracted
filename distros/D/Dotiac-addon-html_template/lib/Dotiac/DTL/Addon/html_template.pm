###############################################################################
#html_template.pm
#Last Change: 2009-01-21
#Copyright (c) 2009 Marc-Seabstian "Maluku" Lucksch
#Version 0.4
####################
#This file is an addon to the Dotiac::DTL project. 
#http://search.cpan.org/perldoc?Dotiac::DTL
#
#html_template.pm is published under the terms of the MIT license, which  
#basically means "Do with it whatever you want". For more information, see the 
#license.txt file that should be enclosed with the distributions. A copy of
#the license is (at the time of writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################


package Dotiac::DTL::Addon::html_template;
use strict;
use warnings;
use base qw/Dotiac::DTL::Parser Dotiac::DTL::Addon::html_template_pure/;
use Dotiac::DTL::Core;
require Dotiac::DTL::Tag;
require Dotiac::DTL::Addon;
require Dotiac::DTL::Addon::html_template::Variable;
require Dotiac::DTL::Tag::importloop;

our $VERSION = 0.4;

my @oldparser;
my $first;


sub import {
	push @oldparser,$Dotiac::DTL::PARSER;
	$Dotiac::DTL::PARSER="Dotiac::DTL::Addon::html_template";
	$Dotiac::DTL::Addon::NOCOMPILE{'Dotiac::DTL::Addon::html_template'}=1;
	my $class=shift;
	while (my $a=shift @_) {
		my $o=shift @_;
		if (defined $o and exists $Dotiac::DTL::Addon::html_template_pure::OPTIONS{$a}) {
			$Dotiac::DTL::Addon::html_template_pure::OPTIONS{$a}=$o;
		}
	}
	$first=1;
}

sub unimport {
	$Dotiac::DTL::PARSER=pop @oldparser;
	$first=0;
}


sub new {
	my $class=shift;
	my $self={};
	bless $self,$class;
	return $self;
}


sub parse {
	my $self=shift;
	my $template=shift;
	my $pos=shift;
	my $start=$$pos;
	my @end = @_;
	my $found;
	$found=shift @end if @end;
	local $_;
	while ($Dotiac::DTL::PARSER eq __PACKAGE__) {
		pos($$template) = $$pos;
		if ($$template=~m/[^<\{]*([<\{])/g) {
			my $dtag=$1; #Decisive tag :)
			my $pre = substr $$template,$start,pos($$template)-$start-1;
			if ($dtag eq "{") {
				my $n = substr $$template,pos($$template),1;
				$$pos=pos($$template)+1;
				if ($n eq "%") {
					my $npos = index($$template,"%}",$$pos);
					die "Missing closing %} at char $$pos" if $npos < 0;
					my $cont=substr $$template,$$pos,$npos-$$pos;
					$$pos=$npos+2;
					$cont=~s/^\s+//;
					$cont=~s/\s+$//;
					my ($tagname,$param) = split /\s+/,$cont,2;
					$tagname=lc $tagname;
					$$found = $tagname and return Dotiac::DTL::Tag->new($pre) if $found and grep {$_ eq $tagname} @end;
					my $r;
					eval {$r="Dotiac::DTL::Tag::$tagname"->new($pre,$param,$self,$template,$pos);};
					if ($@) {
						die "Error while loading Tag '$tagname' from Dotiac::DTL::Tag::$tagname. If this is an endtag (like endif) then your template is unbalanced\n$@";
					}
					if ($$pos >= length $$template) {
						$r->next(Dotiac::DTL::Tag->new(""));
					}
					else {
						$r->next($self->parse($template,$pos,@_));
					}
					if (not $start or $first) {
							$first=0;
							return $r if lc($Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}) eq "html";
							return bless {p=>"",n=>Dotiac::DTL::Tag->new(""),escape=>0,content=>$r},"Dotiac::DTL::Tag::autoescape"; #Autoescape off unless default_escape == html
					}
					return $r;
					
				}
				elsif ($n eq "{") {
					my $npos = index($$template,"}}",$$pos);
					die "Missing closing }} at char $$pos" if $npos < 0;
					my $cont=substr $$template,$$pos,$npos-$$pos;
					$$pos=$npos+2;
					return Dotiac::DTL::Variable->new($pre,$cont,$self->parse($template,$pos,@_));
				}
				elsif ($n eq "#") {
					my $npos = index($$template,"#}",$$pos);
					die "Missing closing #} at char $$pos" if $npos < 0;
					my $cont=substr $$template,$$pos,$npos-$$pos;
					$$pos=$npos+2;
					return Dotiac::DTL::Comment->new($pre,$cont,$self->parse($template,$pos,@_));
				}
			}
			else {
				#my $p=
				if($$template=~m/\G(?:!--\s*)?
				([\/]?)\s*
				[Tt][Mm][Pp][Ll]_((?:[Vv][Aa][Rr])|(?:[Ii][Ff])|(?:[Ee][Ll][Ss][Ee])|(?:[Uu][Nn][Ll][Ee][Ss][Ss])|(?:[Ll][Oo][Oo][Pp])|(?:[Ii][Nn][Cc][Ll][Uu][Dd][Ee]))
				\s*(
				    (?:
					(?:
					    (?:(?:[Dd][Ee][Ff][Aa][Uu][Ll][Tt])|(?:[Ee][Ss][Cc][Aa][Pp][Ee])|(?:[Nn][Aa][Mm][Ee]))
					    \s*=\s*
					)?
					(?!-->)(?:(?:"[^">]*")|(?:'[^'>]*')|(?:[^\s=>]*))\s*
				    )*
				)
				(?:--)?>/sgx) {
					my $end=$1;
					my $tag=lc($2);
					my $content=$3;
					$$pos=pos($$template);
					my $tagname=$tag;
					$tagname="end$tag" if $end;
					$tagname="endimportloop" if $end and $tag eq "loop";
					$tagname="endif" if $end and $tag eq "unless";	
					$$found = $tagname and return Dotiac::DTL::Tag->new($pre) if $found and grep {$_ eq $tagname} @end;
					my $t=$self->maketag($tag,$content,$pre,$template,$pos);
					if ($t) {
						if ($$pos >= length $$template) {
							$t->next(Dotiac::DTL::Tag->new(""));
						}
						else {
							$t->next($self->parse($template,$pos,@_));
						}
						if (not $start or $first) {
							$first=0;
							return $t if lc($Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}) eq "html";
							return bless {p=>"",n=>Dotiac::DTL::Tag->new(""),escape=>0,content=>$t},"Dotiac::DTL::Tag::autoescape"; #Autoescape off unless default_escape == html
						}
						return $t;
					}
					else {
						warn "Couldn't make anything with $tag,$tagname, maybe your template is unbalanced";
					}
				}
				else {
					#die;# $p;
					$$pos++;
				}
			}
		}
		else {
			$$pos=length $$template;
			return Dotiac::DTL::Tag->new(substr $$template,$start);
		}

	}
	my $parser=$Dotiac::DTL::PARSER->new();
	my @args=($template,$pos);
	push @args,$found if $found;
	push @args,@end if @end;
	return $parser->parse(@args);
}


1;
__END__

=head1 NAME

Dotiac::DTL::Addon::html_template - Render combined Django and HTML::Template templates in Dotiac::DTL 

=head1 SYNOPSIS

Load in Perl file for all templates:

	use Dotiac::DTL::Addon::html_template;

Unload again:

	no Dotiac::DTL::Addon::html_template;	


Load from a Dotiac::DTL-template (only Dotiac::DTL 0.8 and up)

	{% load html_template %}<TMPL_VAR NaME=Foo>....

You also might want make the whole thing case insensitive if the L<HTML::Template> template's need it.

	use Dotiac::DTL::Addon::html_template;
	use Dotiac::DTL::Addon::case_insensitive;

or in the template ( > Dotiac::DTL 0.8 ):

	{% load html_template case_insensitive %}<TMPL_VAR NaME=Foo>....

=head1 INSTALLATION

via CPAN:

	perl -MCPAN -e "install Dotiac::DTL::Addon::html_template"

or get it from L<https://sourceforge.net/project/showfiles.php?group_id=249411&package_id=306751>, extract it and then run in the extracted folder:

	perl Makefile.PL
	make test
	make install

=head1 DESCRIPTION

This makes L<Dotiac::DTL> render templates written for L<HTML::Template>. There are four ways to do this:

=head2 Dotiac::DTL::Addon::html_template_pure

This exchanges the parser of Dotiac::DTL with one that can read HTML::Template templates.

It can't render Django Templates anymore, so those will not work.

=head2 Dotiac::DTL::Addon::html_template

This also exchanges the parser, but with one that can read both Django and HTML::Template templates.

This way HTML::Template templates can import/extend Django templates and be imported/extended from them.

B<This means currently working HTML::Template templates can be extended with some Django/Dotiac tags and it will still work like expected>

	<!-- Large web project -->
	....
	<TMPL_IF time><div id="time">{# <TMPL_VAR time> Now Django #}{{ time|date:"Y-m-d H:M" }}</TMPL_IF>
	....

But there will be a problem if the HTML::Template template contains not Django {{, {% or {# tags, but this is rarely the case.

=head2 Dotiac::DTL::Addon::html_template::Convert

This replaces HTML::Template and converts the templates before giving them to Dotiac::DTL. It can work with both pure and combined Django/HTML::Template templates.

B<So even here Django and HTML::Template tags can be mixed, and there is just one different line in the script>

	# use HTML::Template # Not anymore
	use Dotiac::DTL::Addon::html_template::Convert qw/combine/ #Now using Dotiac

See L<Dotiac::DTL::Addon::html_template::Convert>

=head2 Dotiac::DTL::Addon::html_template::Replace

Same as Convert, behaves like HTML::Template to the script, but uses Dotiac::DTL internally. Also supports mixed templates.

This is faster than C<Convert> when using scalarrefs and such as template data.

C<Convert> on the other hand is more stable with filenames, C<Replace> might get confused when using different options on the same template.

See L<Dotiac::DTL::Addon::html_template::Replace>

=head1 OPTIONS

Since Django has no concept of options to a template, there are a few L<HTML::Template> options that can't be ignored:

=head2 filter

This won't work at all, the templates will need to have the filter applied beforehand. There are a lot of things that HTML::Template requires a filter for, but Django supports in a different way, for example: Includes from variables, n-sstage templating (L<Dotiac::DTL::Addon::unparsed>).

=head2 associate

There is also no corresponding thing in Dotiac, but there is an easy solution that almost does the same thing (at least for CGI):

	#Perl
	my $template=Dotiac::DTL->new(...);
	$cgi=new CGI;
	$template->param(cgi=>$cgi->Vars);
	#And then in the template:
	Hello, <TMPL_VAR cgi.name>

It this won't work you need (because of existsing templates), do this:

	#Perl
	# $obj is the associate object.
	foreach my $p ($obj->param()) {
		$template->param($p,$obj->param($p));
	}
	# In the template:
	Hello, <TMPL_VAR name>

=head2 case_sensitive

This option defaults to off in HTML::Template, but in Django it defaults to on.

This is quite bad for most templates, so you can use the case_insensitive addon from CPAN for this. (It should already be installed when this module is installed):

In the perl script that calls it:

	use Dotiac::DTL::Addon::case_insensitive;

In the template (before any {% load html_template_pure %}) with Dotiac::DTL 0.8 and up:

	{% load case_insensitive %}

But remember, this makes Dotiac::DTL slower, so this should be avoided and all variables should be in the right case.

=head2 loop_context_vars

This one defaults to off in HTML::Template, but is set to on here, because it probably won't disrupt any templates.

It can be set to off if there are some problems:

	use Dotiac::DTL::Addon::html_template loop_context_vars=>0;

=head2 global_vars

This one defaults to off in HTML::Template, but it is also set to on here, because it probably won't disrupt any templates.

It can be set to off if there are some problems:

	use Dotiac::DTL::Addon::html_template global_vars=>0;

=head2 default_escape

This is set to off in HTML::Template (which is not that good), but set to HTML in Django. Therefore this parser has to fiddle about with it a lot.

	use Dotiac::DTL::Addon::html_template default_escape=>"HTML";
	use Dotiac::DTL::Addon::html_template default_escape=>"JS";
	use Dotiac::DTL::Addon::html_template default_escape=>"URL";

=head2 Combine options

	use Dotiac::DTL::Addon::html_template global_vars=>0, loop_context_vars=>0, default_escape=>"HTML";

=head2 Setting options during runtime:

Options are save in %Dotiac::DTL::Addon::html_template_pure::OPTIONS (no matter if you use Dotiac::DTL::Addon::html_template_pure or Dotiac::DTL::Addon::html_template).

Changes are only applied to the following new() calls or included templates during print().

	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}="html"
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}="js"
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}="url"
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}="" #off
	
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{global_var}=0
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{global_var}=1

	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{loop_context_vars}=1
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{loop_context_vars}=0

B<Note:> Changing options for the same template might not work because of the caching routines.
It works fine for different templates.

B<Also note:> Once a template is compiled, these options are ignored. In fact the whole module wouldn't be needed anymore. (Unless there is a {% load html_template(_pure) %} in there)

=head1 A NOTE ON COMBINED TEMPLATES

It is possible for Django tags close Html::Template tags and reverse, but it is not very pretty:

	<h1>My posts</h1>
	<TMPL_LOOP posts>
		<h2>
		{% if title %}
			{{ title }}
		<!-- TMPL_ELSE -->
			A post
		</TMPL_IF>
		</h2>
		{{ text|linebreaksbr}}
	{% endimportloop %}


But sometimes it might be useful to add an {% empty %} tag to an existing template:

	Updated on :
	<TMPL_LOOP updated>
		{{ time|date }}
	{% empty %}
		<b>Never</b>
	</TMPL_LOOP>

=head1 BUGS

Please report any bugs or feature requests to L<https://sourceforge.net/tracker2/?group_id=249411&atid=1126445>

=head1 SEE ALSO

L<Dotiac::DTL>, L<Dotiac::DTL::Addon>, L<http://www.dotiac.com>, L<http://www.djangoproject.com>

=head1 AUTHOR

Marc-Sebastian Lucksch

perl@marc-s.de

=cut
