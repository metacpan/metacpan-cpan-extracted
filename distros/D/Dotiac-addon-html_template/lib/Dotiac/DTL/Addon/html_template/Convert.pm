###############################################################################
#Convert.pm
#Last Change: 2009-01-21
#Copyright (c) 2009 Marc-Seabstian "Maluku" Lucksch
#Version 0.4
####################
#This file is an addon to the Dotiac::DTL project. 
#http://search.cpan.org/perldoc?Dotiac::DTL
#
#Convert.pm is published under the terms of the MIT license, which  
#basically means "Do with it whatever you want". For more information, see the 
#license.txt file that should be enclosed with libsofu distributions. A copy of
#the license is (at the time of writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################

package Dotiac::DTL::Addon::html_template::Convert;
use warnings;
use strict;
require Dotiac::DTL;

use Carp;
use File::Spec;
use Scalar::Util qw/blessed reftype/;
require File::Basename;

our $VERSION = 0.4;

our $COMBINE=0;

sub import {
	my $class=shift;
	if (@_ and (lc($_[0]) eq "combine" or lc($_[0]) eq ":combine")) {
		$COMBINE=1;
	}
	{
		require Dotiac::DTL::Template;
		no warnings qw/redefine/;
		*HTML::Template::new=\&new;
		*HTML::Template::new_file=\&new_file;
		*HTML::Template::new_filehandle=\&new_filehandle;
		*HTML::Template::new_array_ref=\&new_array_ref;
		*HTML::Template::new_scalar_ref=\&new_scalar_ref;
		*Dotiac::DTL::Template::query=\&query;
	}
}

my %cache;


#package HTML::Template;

#our $VERSION=2.9;

sub query {
	my $self=shift;
	my @a=$self->param();
	if (@_ and $_ eq "name") {
		my $l=$_[0];
		$l=$l->[-1] if ref $l;
		$l=lc($l);
		return "VAR" if grep { lc($_) eq $l } @a;
	}
	if (@_ and $_ eq "loop") {
		my $l=$_[0];
		$l=$l->[-1] if ref $l;
		$l=lc($l);
		return () if grep { lc($_) eq $l } @a;
	}
	return $self->param();
}

sub _filter {
	my $data=shift;
	my $filter=shift;
	$filter=[$filter] unless ref $filter eq 'ARRAY';
	foreach my $f (@{$filter}) {
		if (ref ($f) eq "HASH" and $f->{"sub"} and ref $f->{"sub"} eq "CODE") {
			if ($f->{format} and not ref $f->{format} and lc($f->{format}) eq "array") {
				my @data=split /\n/,$data;
				$f->{'sub'}->(\@data);
				$data=join("\n",@data);
			}
			else {
				$f->{'sub'}->(\$data);
			}
		}
		elsif (ref ($f) eq "CODE") {
			$f->(\$data);
		}
	}
	return $data;
}

sub _associate {
	my $template=shift;
	my $a=shift;
	my @a=();
	if (Scalar::Util::blessed($a)) {
		@a=($a)
	}
	else {
		@a=@{$a} if ref $a eq "ARRAY";
	}
	foreach my $obj (@a) {
		next unless Scalar::Util::blessed($obj);
		next unless $obj->can("param");
		my @params=$obj->param();
		foreach my $p (@params) {
			$template->param($p,$obj->param($p));
		}
	}
}

our %include;

my %escapeflags = (
	url=>"u",
	js=>"j"
);

sub new_file {
	my $class = shift;
	return $class->new('filename', @_);
}
sub new_filehandle {
	my $class = shift;
	return $class->new('filehandle', @_);
}
sub new_array_ref {
	my $class = shift;
	return $class->new('arrayref', @_);
}
sub new_scalar_ref {
	my $class = shift;
	return $class->new('scalarref', @_);
}

sub new {
	%Dotiac::DTL::Addon::html_template::Convert::include=();
	my $class=shift;
	my %opts=@_;
	my $flags="";
	$flags.=($Dotiac::DTL::Addon::html_template::Convert::COMBINE?"+":"-");
	$flags.=($opts{global_vars}?"g":"n");
	$flags.=($opts{case_sensitive}?"s":"i");
	$flags.=($opts{loop_context_vars}?"l":"c");
	$flags.=($opts{default_escape}?($escapeflags{lc($opts{default_escape})}||"h"):"o");
	my $r = eval {
		if ($opts{filename}) {
			my @compile=();
			push @compile,$opts{compile} if exists ($opts{compile});
			my $file=_find_file(\%opts);
			croak "Can't find file: $opts{filename}" unless $file;
			$Dotiac::DTL::Addon::html_template::Convert::include{$file}++;
			#die $flags;
			if (-e "$file$flags.html") {
				if ((stat("$file$flags.html"))[9] >= (stat("$file"))[9]) {
					#if (-M "$file$flags.html" < -M $file) {
					my $template=Dotiac::DTL->new("$file$flags.html",@compile);
					Dotiac::DTL::Addon::html_template::Convert::_associate($template,$opts{associate}) if $opts{associate};
					return $template;
				}
			}
			open my $fh, "<",$file or croak "Can't open $file: $!";
			my $data=do {local $/;<$fh>};
			close $fh;
			$data=Dotiac::DTL::Addon::html_template::Convert::_filter($data,$opts{filter}) if $opts{filter};
			my @f = File::Basename::fileparse($file);
			$data=Dotiac::DTL::Addon::html_template::Convert::_convert($data,\%opts,$f[1]);
			my $template;
			if (open my $fh,">","$file$flags.html") {
				print $fh $data;
				close $fh;
				$template=Dotiac::DTL->new("$file$flags.html")
			}
			else {
				if (@compile) {
					carp "Can't compile template $file, even though it was requested. Can't create \"$file$flags.html\": $!";
					delete $opts{compile};
					@compile=();
				}
				$Dotiac::DTL::CURRENTDIR=$f[1]; # Works only with Dotiac::DTL >= 0.8
				$template=Dotiac::DTL->new(\$data);
			}
			Dotiac::DTL::Addon::html_template::Convert::_associate($template,$opts{associate}) if $opts{associate};
			return $template;
		}
		my $data;
		if ($opts{filehandle}) {
			my $fh=$opts{filehandle};
			$data=do {local $/;<$fh>};
		}
		elsif ($opts{scalarref}) {
			$data=${$opts{scalarref}}; #Have to deref here for conversion
		}
		elsif ($opts{arrayref}) {
			$data=join("",@{$opts{arrayref}});
		}
		$data=Dotiac::DTL::Addon::html_template::Convert::_filter($data,$opts{filter}) if $opts{filter};
		if ($cache{$data.$flags}) {
			$data=$cache{$data.$flags};
		}
		else {
			my $odata=$data;
			$data=Dotiac::DTL::Addon::html_template::Convert::_convert($data,\%opts);
			$cache{$odata.$flags}=$data;
		}
		my $template=Dotiac::DTL->new(\$data);
		Dotiac::DTL::Addon::html_template::Convert::_associate($template,$opts{associate}) if $opts{associate};
		return $template;
	};
	return $r if $r;
	croak "Something went wrong while generating the template: $@";
}


my %filter=(
	url=>"urlencode",
	js=>"escapejs",
	html=>"escape"
);

sub _convert_tag {
	my $start=shift;
	$start="{% templatetag openbrace %}"x length($start);
	my $end=shift;
	my $tag=lc(shift(@_));
	my $options=shift; 
	my @opts=();
	@opts=split /\s*((?:(?:[Dd][Ee][Ff][Aa][Uu][Ll][Tt])|(?:[Ee][Ss][Cc][Aa][Pp][Ee])|(?:[Nn][Aa][Mm][Ee]))\s*=)\s*/,$options if $options;
	my %opts=();
	#die shift(@opts);
	#Convert options, quick and dirty
	while (defined(my $o=shift(@opts))) {
	#if (my $o=0) {
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
				$value=~s/\\/\\\\/g;
			}
			else {
				$value=~s/\s*$//g;
				$value=~s/\\/\\\\/g;
				$value=~s/\"/\\\"/g;
				$value='"'.$value.'"';
			}
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
	#use Data::Dumper;
	#warn Data::Dumper->Dump([$tag,\%opts]);
	my $cv=shift;
	my $global=shift;
	my $default=shift;
	my $opts=shift;
	if ($tag eq "var") {
		my @filter;
		my $d=$default;
		if ($opts{escape}) {
			foreach my $f (@{$opts{escape}}) {
				next if $f eq "";
				$d="";
				next unless $f;
				next if $f eq "off";
				next if $f eq "none";
				if ($f eq "js" or $f eq "url") {
					push @filter,$filter{$f}
				}
				else {
					push @filter,"escape" unless $default eq "html";
					$d=$default if $default eq "html";
				}
			}
		}
		if ($d) {
			push @filter,$filter{$d} if $filter{$d};
			#push @filter,"safe" if $default eq "html";
		}
		elsif ($default eq "html") {
			push @filter,"safe";
		}
		if ($opts{default}) {
			my $def=shift @{$opts{default}};
			push @filter,"default:$def" if $def;
		}
		my $name;
		if ($opts{name}) {
			$name=shift @{$opts{name}} while not $name and @{$opts{name}};
		}
		$name='""' unless $name;
		#warn "{{ ".join("|",$name,@filter)." }}";
		return "$start\{\{ ".join("|",$name,@filter)." }}";
	}
	elsif ($tag eq "else") {
		return "$start\{\% else \%}";
	}
	elsif ($tag eq "if") {
		return "$start\{\% endif \%}" if ($end);
		my $name;
		if ($opts{name}) {
			$name=shift @{$opts{name}} while not $name and @{$opts{name}};
		}
		$name='""' unless $name;
		return "$start\{\% if $name \%}";
	}
	elsif ($tag eq "unless") {
		return "$start\{\% endif \%}" if ($end);
		my $name;
		if ($opts{name}) {
			$name=shift @{$opts{name}} while not $name and @{$opts{name}};
		}
		$name='""' unless $name;
		return "$start\{\% if not $name \%}";
	}
	elsif ($tag eq "loop") {
		return "$start\{\% endimportloop \%}" if ($end);
		my $name;
		if ($opts{name}) {
			$name=shift @{$opts{name}} while not $name and @{$opts{name}};
		}
		$name='""' unless $name;
		return "$start\{\% importloop ${name}${cv}$global \%}";
	}
	elsif ($tag eq "include") {
		my $name;
		if ($opts{name}) {
			$name=shift @{$opts{name}} while not $name and @{$opts{name}};
		}
		return "$start" unless $name;
		my $me="";
		$me = $opts->{filename} if $opts->{filename};
		$opts->{filename}=$name;
		my $file=_find_file($opts,@_);
		unless ($file) {
			carp "Can't find included file: $opts->{filename}";
			return "$start";
		}
		if ($include{$file}) {
			carp "Can't cyclic include $file, Include skipped";
			return "$start";
		}
		$include{$file}++;
		my $flags="";
		$flags.=($COMBINE?"+":"-");
		$flags.=($opts{global_vars}?"g":"n");
		$flags.=($opts{case_sensitive}?"s":"i");
		$flags.=($opts{loop_context_vars}?"l":"c");
		$flags.=($opts{default_escape}?($escapeflags{lc($opts{default_escape})}||"h"):"o");
		my $relfile=$file;
		if ($me) {
			my @mypath=File::Basename::fileparse(File::Spec->rel2abs($me));
			$relfile=File::Spec->abs2rel(File::Spec->rel2abs($file),$mypath[1]);
		}
		if (-e "$file$flags.html") {
			if ((stat("$file$flags.html"))[9] >= (stat("$file"))[9]) {
				$include{$file}--;
				return die "$start\{\% include \"$relfile$flags.html\" \%}";
			}
		}
		my $pathsep=quotemeta(File::Spec->catdir('',''));
		$relfile=~s/$pathsep/\//g; #Works almost everywhere, Dotiac takes care of that
		$relfile=~s/\\/\\\\/g;
		open my $fh, "<",$file or croak "Can't open $file: $!";
		my $data=do {local $/;<$fh>};
		close $fh;
		$data=Dotiac::DTL::Addon::html_template::Replace::_filter($data,$opts{filter}) if $opts{filter};
		my @f = File::Basename::fileparse($file);
		$data=_convert($data,\%opts,$f[1],@_);
		if (open my $fh,">","$file$flags.html") {
			print $fh $data;
			close $fh;
			$include{$file}--;
			return "$start\{\% include \"$relfile$flags.html\" \%}";
		}
		else {
			carp "Can't write into $file$flags.html: $!, Include of $file skipped";
			return "$start"
		}

	}
	return "$start";
}

my %tag=reverse (
	openblock=>"{%",
	closeblock=>"%}",
	openvariable=>"{{",
	closevariable=>"}}",
	openbrace=>"{",
	closebrace=>"}",
	opencomment=>"{#",
	closecomment=>"#}"
);

sub _convert {
	my $data=shift;
	my $ret="";
	my %opts=%{shift(@_)};
	my $global="";
	$global=" merge" if $opts{global_vars};
	my $cv="";
	$cv=" contextvars" if $opts{loop_context_vars};
	my $default="";
	if ($opts{default_escape}) {
		$default=lc($opts{default_escape});
	}
	if ($opts{case_sensitive}) {
		$ret="{% load importloop %}";
	}
	else {
		$ret="{% load case-insensitive importloop %}";
	}
	$ret.="{% autoescape off %}" unless $default eq "html";
	$data=~s/((?:\{\{)|(?:\}\})|(?:\%\})|(?:\{\%)|(?:\{#)|(?:#\})|(?:\{)|(?:\}))/{% templatetag $tag{$1} %}/g unless $Dotiac::DTL::Addon::html_template::Convert::COMBINE;
	$data=~s/(\{*)
		<(?:!--\s*)?
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
		(?:--)?>
	/_convert_tag($1,$2,$3,$4,$cv,$global,$default,{%opts},@_)/xeg;
	#carp $ret.$data." ";
	return $ret.$data."{% endautoescape %}" unless $default eq "html";
	return $ret.$data;
}

sub _find_file { #like HTML::Template
	my $o=shift;
	my $file=$o->{filename};
	return File::Spec->canonpath($file) if (File::Spec->file_name_is_absolute($file) and (-e $file));
	foreach my $p (@_) {
		my $path =  File::Spec->catfile($p, $file);
		return File::Spec->canonpath($path) if -e $path;
	}
	if (defined($ENV{HTML_TEMPLATE_ROOT})) {
		my $path =  File::Spec->catfile($ENV{HTML_TEMPLATE_ROOT}, $file);
		return File::Spec->canonpath($path) if -e $path;
	}
	if ($o->{path}) {
		foreach my $path (@{$o->{path}}) {
			$path =  File::Spec->catfile($path, $file);
			return File::Spec->canonpath($path) if -e $path;
		}
	}
	return File::Spec->canonpath($file) if -e $file;
	if ($o->{path}) {
		if (defined($ENV{HTML_TEMPLATE_ROOT})) {
			foreach my $path (@{$o->{path}}) {
				$path =  File::Spec->catfile($ENV{HTML_TEMPLATE_ROOT},$path, $file);
				return File::Spec->canonpath($path) if -e $path;
			}
		}
	}
	return undef;
}
1;

__END__

=head1 NAME

Dotiac::DTL::Addon::html_template::Convert - Convert HTML::Template to Dotiac::DTL

=head1 SYNOPSIS

	#!/usr/bin/perl -w
	use Dotiac::DTL::Addon::html_template::Convert;

	# open the html template
	my $template = HTML::Template->new(filename => 'test.tmpl');

	# fill in some parameters
	$template->param(HOME => $ENV{HOME});
	$template->param(PATH => $ENV{PATH});

	# send the obligatory Content-Type and print the template output
	print "Content-Type: text/html\n\n", $template->output;

=head1 DESCRIPTION

Converts HTML::Template templates to Dotiac::DTL templates.

Just replace

	use HTML::Template;

with 
	use Dotiac::DTL::Addon::html_template::Convert;

or 

	use Dotiac::DTL::Addon::html_template::Convert qw/combine/;	

in the script that calls that template.

Dotiac::DTL::Addon::html_template::Convert will then convert the template into L<Dotiac::DTL>/Django template code and render it.

If the input is a filename, it will also save the converted versions under "FILENAME"+[+/-]+4 chars+".html" and won't reconvert as long as that file is there and not outdated.

When using mostly scalarrefs as data, L<use Dotiac::DTL::Addon::html_template::Replace> is a better choice and faster.

The 4 chars save the options of the HTML::Template, cause different options of HTML::Template result in different compiled template.

=head2 The 4 Bytes in the new name:

=over

=item First: g or n

"g" stands for global_vars on, "n" for off.

=item Second: i or s

"i" stands for case_insensitive, "c" for case_sensitive

=item Third: l or c

"l" stands for "loop_context_var" on, "c" for clear loop ("loop_context_var" off)

=item Last: j, h, u, o

Save the default escape status:

"j" for "JS", "h" for "HTML", "u" for "URL", o for "off"

=back

For example: On all options to default, the flag will be "nico", all options on it will be "gslh"

=head2 combine

When set "combine" in the use statement, this module will allow combined Django and HTML::Template code:

Valid template:

	{% if test or failed %}<TMPL_VAR test>{% endif %}

This is done by first converting HTML::Template code into Django template code and then parsing the whole thing again.

	{% if test or failed %}{{ test }}{% endif %}

The flags will be added with a leading "+" instead of a "-".

=head2 What won't work

Some options are accepted (global_vars,filter,loop_context_vars,associate,case_sensitive) the others are ignored (caching).

Sadly, the params() call without arguments and query() won't work at all prior to Dotiac::DTL 0.8, since Dotiac::DTL doesn't really care for variables until it renders.

=head2 Compiling

There is one additional option to new():

=head3 compile

Instructs Dotiac::DTL to compile the template, only works with filenames

	my $t=HTML::Template->new(filename=>"foo.html",compile=>1);

This will first translate to "foo.html[FLAGS].html" and then B<on the next run> compile to "foo.html[FLAGS]..html.pm"

=head1 BUGS

Please report any bugs or feature requests to L<https://sourceforge.net/tracker2/?group_id=249411&atid=1126445>

=head1 SEE ALSO

L<Dotiac::DTL>, L<Dotiac::DTL::Addon>, L<http://www.dotiac.com>, L<http://www.djangoproject.com>

=head1 AUTHOR

Marc-Sebastian Lucksch

perl@marc-s.de

=cut
