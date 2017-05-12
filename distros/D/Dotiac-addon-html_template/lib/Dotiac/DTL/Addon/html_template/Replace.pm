###############################################################################
#Replace.pm
#Last Change: 2009-01-21
#Copyright (c) 2009 Marc-Seabstian "Maluku" Lucksch
#Version 0.4
####################
#This file is an addon to the Dotiac::DTL project. 
#http://search.cpan.org/perldoc?Dotiac::DTL
#
#Replace.pm is published under the terms of the MIT license, which  
#basically means "Do with it whatever you want". For more information, see the 
#license.txt file that should be enclosed with this distribution. A copy of
#the license is (at the time of writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################

package Dotiac::DTL::Addon::html_template::Replace;
use warnings;
use strict;
use Dotiac::DTL;
require Dotiac::DTL::Addon::case_insensitive;
#use base qw/Dotiac::DTL::Template/;
use Carp;
use File::Spec;
use Scalar::Util qw/blessed reftype/;
use Carp qw/croak/;
require File::Basename;

our $VERSION = 0.4;

our $COMBINE=0;

sub import {
	my $class=shift;
	if (@_ and (lc($_[0]) eq "combine" or lc($_[0]) eq ":combine")) {
		$COMBINE=1;
	}
}

sub _new {
	my $class=shift;
	my $parser=shift;
	my $template=shift;
	my $cs=shift;
	my $ci=!$cs;
	my $global=shift;
	my $context=shift;
	my $default=shift;
	return bless [$template,$parser,$ci,$global,$context,$default],$class;

}

sub param {
	my $self=shift;
	return $self->[0]->param(@_);
}
sub output {
	my $self=shift;
	my $p=$Dotiac::DTL::PARSER;
	$Dotiac::DTL::PARSER=$self->[1];
	my @save=($Dotiac::DTL::Addon::html_template_pure::OPTIONS{global_vars},$Dotiac::DTL::Addon::html_template_pure::OPTIONS{loop_context_vars},$Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape});
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{global_vars}=$self->[3];
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{loop_context_vars}=$self->[4];
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}=$self->[5];
	Dotiac::DTL::Addon::case_insensitive->import() if $self->[2];
	my $r;
	$r="";
	eval {
		if (@_ and $_[0] eq "print_to") {
			my $fh=select $_[1];
			$self->[0]->print();
			select $fh;
		}
		else {
			$r=$self->[0]->string();
		}
		1;
	} or croak "Something went wrong in the output: $@";
	$Dotiac::DTL::PARSER=$p;
	Dotiac::DTL::Addon::case_insensitive->unimport() if $self->[2];
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{global_vars}=$save[0];
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{loop_context_vars}=$save[1];
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}=$save[2];
	return $r;
}

sub isa {
	my $class=shift;
	my $name=shift;
	return 1 if $name eq "Dotiac::DTL::Template"; #Just lie about it.
	return 1 if $name eq "HTML::Template";  #Just lie about it.
	return $class->isa($name);
}

sub query {
	my $self=shift;
	my @a=$self->[0]->param();
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
	return $self->[0]->param();
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

#package HTML::Template;

#our 
$HTML::Template::VERSION=2.9;

no warnings qw/redefine/;

sub HTML::Template::_find_file { #like HTML::Template
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



my %escapeflags = (
	url=>"u",
	js=>"j"
);

sub HTML::Template::new_file {
	my $class = shift;
	return $class->HTML::Template::new('filename', @_);
}
sub HTML::Template::new_filehandle {
	my $class = shift;
	return $class->HTML::Template::new('filehandle', @_);
}
sub HTML::Template::new_array_ref {
	my $class = shift;
	return $class->HTML::Template::new('arrayref', @_);
}
sub HTML::Template::new_scalar_ref {
	my $class = shift;
	return $class->HTML::Template::new('scalarref', @_);
}

use Carp qw/croak/;

sub HTML::Template::new {
	%Dotiac::DTL::Addon::html_template::Replace::include=();
	my $class=shift;
	my %opts=@_;
	my @save=($Dotiac::DTL::Addon::html_template_pure::OPTIONS{global_vars},$Dotiac::DTL::Addon::html_template_pure::OPTIONS{loop_context_vars},$Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape});
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{global_vars}=$opts{global_vars};
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{loop_context_vars}=$opts{loop_context_vars};
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}=$opts{default_escape};
	Dotiac::DTL::Addon::case_insensitive->import() unless $opts{case_sensitive};
	my $flags=""; 
	$flags.=($opts{global_vars}?"g":"n");
	$flags.=($opts{case_sensitive}?"s":"i");
	$flags.=($opts{loop_context_vars}?"l":"c");
	$flags.=($opts{default_escape}?($escapeflags{lc($opts{default_escape})}||"h"):"o");
	my $parser="Dotiac::DTL::Addon::html_template";
	$parser="Dotiac::DTL::Addon::html_template_pure" unless $Dotiac::DTL::Addon::html_template::Replace::COMBINE;
	my $r = eval {
		if ($opts{filename}) {
			$flags=($Dotiac::DTL::Addon::html_template::Replace::COMBINE?"+":"-").$flags;
			my @compile=();
			push @compile,$opts{compile} if exists ($opts{compile});
			my $file=HTML::Template::_find_file(\%opts);
			croak "Can't find file: $opts{filename}" unless $file;
			if (-e "$file$flags.html") { #If there is already a converted version, use it.
				if ((stat("$file$flags.html"))[9] >= (stat("$file"))[9]) {
					#if (-M "$file$flags.html" < -M $file) {
					my $template=Dotiac::DTL->new("$file$flags.html",@compile);
					Dotiac::DTL::Addon::html_template::Replace::_associate($template,$opts{associate}) if $opts{associate};
					return $template;
				}
			}
			if (-e "$file$flags.htm") { #If there is already a filtered version, use it.
				if ((stat("$file$flags.htm"))[9] >= (stat("$file"))[9]) {
					my $p=$Dotiac::DTL::PARSER;
					$Dotiac::DTL::PARSER=$parser;
					my $template=Dotiac::DTL->new("$file$flags.htm",@compile);
					Dotiac::DTL::Addon::html_template::Replace::_associate($template,$opts{associate}) if $opts{associate};
					$Dotiac::DTL::PARSER=$p;
					return Dotiac::DTL::Addon::html_template::Replace->_new($parser,$template,$opts{case_sensitive},$opts{global_vars},$opts{loop_context_vars},$opts{default_escape});

				}
			}
			if ($opts{filter}) {
				#Not good!
				open my $fh, "<",$file or croak "Can't open $file: $!";
				my $data=do {local $/;<$fh>};
				close $fh;
				$data=Dotiac::DTL::Addon::html_template::Replace::_filter($data,$opts{filter});
				my @f = File::Basename::fileparse($file);
				if (open my $fh,">","$file$flags.htm") {
					print $fh $data;
					close $fh;
					my $p=$Dotiac::DTL::PARSER;
					$Dotiac::DTL::PARSER=$parser;
					my $template=Dotiac::DTL->new("$file$flags.htm",@compile);
					Dotiac::DTL::Addon::html_template::Replace::_associate($template,$opts{associate}) if $opts{associate};
					$Dotiac::DTL::PARSER=$p;
					return Dotiac::DTL::Addon::html_template::Replace->_new($parser,$template,$opts{case_sensitive},$opts{global_vars},$opts{loop_context_vars},$opts{default_escape});
				}
				else {
					my $p=$Dotiac::DTL::PARSER;
					$Dotiac::DTL::PARSER=$parser;
					$Dotiac::DTL::CURRENTDIR=$f[1];
					my $template=Dotiac::DTL->new(\$data);
					Dotiac::DTL::Addon::html_template::Replace::_associate($template,$opts{associate}) if $opts{associate};
					$Dotiac::DTL::PARSER=$p;
					return Dotiac::DTL::Addon::html_template::Replace->_new($parser,$template,$opts{case_sensitive},$opts{global_vars},$opts{loop_context_vars},$opts{default_escape});
				}
			}
			my $p=$Dotiac::DTL::PARSER;
			$Dotiac::DTL::PARSER=$parser;
			my $template=Dotiac::DTL->new($file,@compile); #Flags are ignored, unstable, but fast.
			Dotiac::DTL::Addon::html_template::Replace::_associate($template,$opts{associate}) if $opts{associate};
			$Dotiac::DTL::PARSER=$p;
			return Dotiac::DTL::Addon::html_template::Replace->_new($parser,$template,$opts{case_sensitive},$opts{global_vars},$opts{loop_context_vars},$opts{default_escape});
		}
		if ($Dotiac::DTL::Addon::html_template::Replace::COMBINE) { #We have to put the flags in here to confuse the Dotiac::DTL::Caching stuff if they change.
			$flags="{# $flags #}";
		}
		else {
			$flags="<TMPL_VAR $flags>";
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
		$data=Dotiac::DTL::Addon::html_template::Replace::_filter($data,$opts{filter}) if $opts{filter};
		$data=$data.$flags;
		my $p=$Dotiac::DTL::PARSER;
		$Dotiac::DTL::PARSER=$parser;
		my $template=Dotiac::DTL->new(\$data);
		$Dotiac::DTL::PARSER=$p;
		Dotiac::DTL::Addon::html_template::Replace::_associate($template,$opts{associate}) if $opts{associate};
		return Dotiac::DTL::Addon::html_template::Replace->_new($parser,$template,$opts{case_sensitive},$opts{global_vars},$opts{loop_context_vars},$opts{default_escape});
	};
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{global_vars}=$save[0];
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{loop_context_vars}=$save[1];
	$Dotiac::DTL::Addon::html_template_pure::OPTIONS{default_escape}=$save[2];
	Dotiac::DTL::Addon::case_insensitive->unimport() unless $opts{case_sensitive};
	return $r if $r;
	croak "Something went wrong while generating the template: $@";
}



1;

__END__

=head1 NAME

Dotiac::DTL::Addon::html_template::Replace - Use Dotiac::DTL as HTML::Template

=head1 SYNOPSIS

	#!/usr/bin/perl -w
	use Dotiac::DTL::Addon::html_template::Replace;

	# open the html template
	my $template = HTML::Template->new(scalarref => \$templatedata);

	# fill in some parameters
	$template->param(HOME => $ENV{HOME});
	$template->param(PATH => $ENV{PATH});

	# send the obligatory Content-Type and print the template output
	print "Content-Type: text/html\n\n", $template->output;

=head1 DESCRIPTION

Makes 

Just replace

	use HTML::Template;

with 
	use Dotiac::DTL::Addon::html_template::Replace;

or 

	use Dotiac::DTL::Addon::html_template::Replace qw/combine/;	

in the script that calls that template.

When using file names and a lot of different options to C<new()>, L<Dotiac::DTL::Addon::html_template::Convert> is a better choice.

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

=head1 BUGS

Please report any bugs or feature requests to L<https://sourceforge.net/tracker2/?group_id=249411&atid=1126445>

=head1 SEE ALSO

L<Dotiac::DTL>, L<Dotiac::DTL::Addon>, L<http://www.dotiac.com>, L<http://www.djangoproject.com>

=head1 AUTHOR

Marc-Sebastian Lucksch

perl@marc-s.de

=cut
