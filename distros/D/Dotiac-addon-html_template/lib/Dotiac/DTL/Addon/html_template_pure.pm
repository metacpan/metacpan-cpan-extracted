###############################################################################
#html_template_pure.pm
#Last Change: 2009-01-21
#Copyright (c) 2009 Marc-Seabstian "Maluku" Lucksch
#Version 0.4
####################
#This file is an addon to the Dotiac::DTL project. 
#http://search.cpan.org/perldoc?Dotiac::DTL
#
#html_template_pure.pm is published under the terms of the MIT license, which  
#basically means "Do with it whatever you want". For more information, see the 
#license.txt file that should be enclosed with the distributions. A copy of
#the license is (at the time of writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################


package Dotiac::DTL::Addon::html_template_pure;
use strict;
use warnings;
use Dotiac::DTL::Core;
use base qw/Dotiac::DTL::Parser/;
require Dotiac::DTL::Tag;
require Dotiac::DTL::Addon::html_template::Variable;
require Dotiac::DTL::Tag::autoescape;
require Dotiac::DTL::Tag::if;
require Dotiac::DTL::Tag::importloop;
require Dotiac::DTL::Tag::include;

our $VERSION = 0.4;
our %OPTIONS=(
	loop_context_vars=>1,
	global_vars=>1,
	default_escape=>""
);

my @oldparser;



sub import {
	push @oldparser,$Dotiac::DTL::PARSER;
	$Dotiac::DTL::PARSER="Dotiac::DTL::Addon::html_template_pure";
	$Dotiac::DTL::Addon::NOCOMPILE{'Dotiac::DTL::Addon::html_template_pure'}=1;
	my $class=shift;
	while (my $a=shift @_) {
		my $o=shift @_;
		if (defined $o and exists $OPTIONS{$a}) {
			$OPTIONS{$a}=$o;
		}
	}
}

sub unimport {
	$Dotiac::DTL::PARSER=pop @oldparser;
}

sub maketag {
	my $self=shift;
	my $tag=shift;
	my $opts=shift;
	my $pre=shift;
	my @opts=();
	@opts=split /\s*((?:(?:[Dd][Ee][Ff][Aa][Uu][Ll][Tt])|(?:[Ee][Ss][Cc][Aa][Pp][Ee])|(?:[Nn][Aa][Mm][Ee]))\s*=)\s*/,$opts if $opts;
	my %opts=();
	#Convert options, quick and dirty
	while (defined(my $o=shift(@opts))) {
		next unless $o;
		if (substr($o,-1,1) ne "=") {
			push @{$opts{"name"}},$o;
		}
		else {
			$o=~s/\s*=$//;
			$o=lc $o;
			push @{$opts{$o}},shift(@opts);
		}

	}
	if ($opts{default}) {
		foreach my $value (@{$opts{default}}) {
			my $f=substr $value,0,1;
			my $e=substr $value,-1,1;
			if ($f eq $e and $f eq '"' or $f eq "'") {
				$value=substr $value,1,-1;
			}
			$value=Dotiac::DTL::escap($value);
		}
	}
	if ($opts{name}) {
		foreach my $value (@{$opts{name}}) {
			$value=~s/["'\\\s}{]//g;
		}
	}
	if ($opts{escape}) {
		foreach my $value (@{$opts{escape}}) {
			$value=~s/\W//g;
			$value=~tr/A-Z/a-z/;
		}
	}
	my $template=shift;
	my $pos=shift;
	if ($tag eq "var") {
		my @filter;
		push @{$opts{escape}},lc($Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}) if not ($opts{escape}) and $Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape} and lc($Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}) ne "html";
		if ($opts{escape}) {
			foreach my $v (@{$opts{escape}}) {
				if ($v eq "js") {
					push @filter,"escapejs";
					push @filter,"safe" if lc($Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}) eq "html";
				}
				if ($v eq "html") {
					push @filter,"escape";
				}
				if ($v eq "url") {
					push @filter,"urlencode";
					push @filter,"safe" if lc($Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}) eq "html";
				}
				if ($v eq "0" or $v eq "" or $v eq "off" or $v eq "none") {
					push @filter,"safe" if lc($Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}) eq "html";
				}
			}
		}
		if ($opts{default}) {
			push @filter,"default:".shift(@{$opts{default}});
		}
		my $name="``";
		if ($opts{name}) {
			$name=shift @{$opts{name}};
		}
		return Dotiac::DTL::Addon::html_template::Variable->new($pre,$name,\@filter);
	}
	elsif ($tag eq "if") {
		my $found="";
		my $name="``";
		if ($opts{name}) {
			$name=shift @{$opts{name}};
		}
		my $true=$self->parse($template,$pos,\$found,"else","endif");
		if ($found eq "else") {
			return bless {'cond'=>[$name],true=>$true,false=>$self->parse($template,$pos,\$found,"endif"),p=>$pre},"Dotiac::DTL::Tag::if";
		}
		return bless {'cond'=>[$name],true=>$true,p=>$pre},"Dotiac::DTL::Tag::if";
	}
	elsif ($tag eq "unless") {
		my $found="";
		my $name="``";
		if ($opts{name}) {
			$name=shift @{$opts{name}};
		}
		my $true=$self->parse($template,$pos,\$found,"else","endif");
		if ($found eq "else") {
			return bless {'not'=>[$name],true=>$true,false=>$self->parse($template,$pos,\$found,"endif"),p=>$pre},"Dotiac::DTL::Tag::if";
		}
		return bless {'not'=>[$name],true=>$true,p=>$pre},"Dotiac::DTL::Tag::if";
	}
	elsif ($tag eq "loop") {
		my $found="";
		my $name="``";
		if ($opts{name}) {
			$name=shift @{$opts{name}};
		}
		my $content=$self->parse($template,$pos,\$found,"endimportloop","empty");
		if ($found eq "empty") {
			return bless {source=>$name,content=>$content,p=>$pre,empty=>$self->parse($template,$pos,\$found,"endimportloop"),merge=>$Dotiac::DTL::Addon::html_template_pure::OPTIONS{global_vars},contextvars=>$Dotiac::DTL::Addon::html_template_pure::OPTIONS{loop_context_vars}},"Dotiac::DTL::Tag::importloop";
		}
		return bless {source=>$name,content=>$content,p=>$pre,merge=>$Dotiac::DTL::Addon::html_template_pure::OPTIONS{global_vars},contextvars=>$Dotiac::DTL::Addon::html_template_pure::OPTIONS{loop_context_vars}},"Dotiac::DTL::Tag::importloop";
	}
	elsif ($tag eq "include") {
		my $name;
		if ($opts{name}) {
			$name=shift @{$opts{name}};
		}
		return Dotiac::DTL::Addon::html_template::Variable->new($pre,"``",[]) unless $name;
		return eval {
			my $tem = Dotiac::DTL->safenew($name);
			return bless {content=>$tem->{first},load=>$name,p=>$pre},"Dotiac::DTL::Tag::include";
		} || Dotiac::DTL::Addon::html_template::Variable->new($pre,"``",[]);
	}
	return undef;
	
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
		if($$template=~m/\G(.*?)<(?:!--\s*)?
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
			my $pre=$1;
			my $end=$2;
			my $tag=lc($3);
			my $content=$4;
			$$pos=pos($$template);
			#warn "Pre:$pre\nTag:$tag,End:$end\nContent=$content\nStart=$start, end=$$pos" if $tag eq "if";
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
				unless ($start) {
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

sub unparsed { #This isn't needed here.
	return "";
}

1;
__END__

=head1 NAME

Dotiac::DTL::Addon::html_template_pure - Render pure HTML::Template in Dotiac::DTL 

=head1 SYNOPSIS

Load in Perl file for all templates:

	use Dotiac::DTL::Addon::html_template_pure;

Unload again:

	no Dotiac::DTL::Addon::html_template_pure;	


Load from a Dotiac::DTL-template (only Dotiac::DTL 0.8 and up)

	{% load html_template_pure %}<TMPL_VAR NaME=Foo>....

You also might want make the whole thing case insensitive if the L<HTML::Template> template's need it.

	use Dotiac::DTL::Addon::html_template_pure;
	use Dotiac::DTL::Addon::case_insensitive;

or in the template ( > Dotiac::DTL 0.8 ):

	{% load html_template_pure case_insensitive %}<TMPL_VAR NaME=Foo>....

=head1 INSTALLATION

via CPAN:

	perl -MCPAN -e "install Dotiac::DTL::Addon::html_template"

or get it from L<https://sourceforge.net/project/showfiles.php?group_id=249411&package_id=306751>, extract it and then run in the extracted folder:

	perl Makefile.PL
	make test
	make install

=head1 DESCRIPTION

This makes L<Dotiac::DTL> render templates written for L<HTML::Template>. There are three ways to do this:

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

	use Dotiac::DTL::Addon::html_template_pure loop_context_vars=>0;

=head2 global_vars

This one defaults to off in HTML::Template, but it is also set to on here, because it probably won't disrupt any templates.

It can be set to off if there are some problems:

	use Dotiac::DTL::Addon::html_template_pure global_vars=>0;

=head2 default_escape

This is set to off in HTML::Template (which is not that good), but set to HTML in Django. Therefore this parser has to fiddle about with it a lot.

	use Dotiac::DTL::Addon::html_template_pure default_escape=>"HTML";
	use Dotiac::DTL::Addon::html_template_pure default_escape=>"JS";
	use Dotiac::DTL::Addon::html_template_pure default_escape=>"URL";

=head2 Combine options

	use Dotiac::DTL::Addon::html_template_pure global_vars=>0, loop_context_vars=>0, default_escape=>"HTML";

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
