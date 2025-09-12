# This code is part of Perl distribution Log-Report-Template version 1.03.
# The POD got stripped from this file by OODoc version 3.04.
# For contributors see file ChangeLog.

# This software is copyright (c) 2017-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Log::Report::Template;{
our $VERSION = '1.03';
}

use base 'Template';

use warnings;
use strict;

use Log::Report 'log-report-template';
use Log::Report::Template::Textdomain ();
# use Log::Report::Template::Extract on demand.

use File::Find        qw/find/;
use Scalar::Util      qw/blessed/;
use Template::Filters ();
use String::Print     ();



sub new
{	my $class = shift;

	# Template::Base gladly also calls _init() !!
	my $self = $class->SUPER::new(@_) or panic $class->error;
	$self;
}

sub _init($)
{	my ($self, $args) = @_;

	if(ref $self eq __PACKAGE__)
	{	# Instantiated directly
		$self->SUPER::_init($args);
	}
	else
	{	# Upgrade from existing Template object
		bless $self, __PACKAGE__;
	}

	my $delim = $self->{LRT_delim} = $args->{DELIMITER} || ':';
	my $incl = $args->{INCLUDE_PATH} || [];
	$self->{LRT_path} = ref $incl eq 'ARRAY' ? $incl : [ split $delim, $incl ];

	my $handle_errors = $args->{processing_errors} || 'NATIVE';
	if($handle_errors eq 'EXCEPTION') { $self->{LRT_exceptions} = 1 }
	elsif($handle_errors ne 'NATIVE')
	{	error __x"illegal value '{value}' for 'processing_errors' option", value => $handle_errors;
	}

	$self->{LRT_formatter} = $self->_createFormatter($args);
	$self->{LRT_trTo} = $args->{translate_to};
	$self->{LRT_tdc}  = $args->{textdomain_class} || 'Log::Report::Template::Textdomain';
	$self->_defaultFilters;
	$self;
}

sub _createFormatter($)
{	my ($self, $args) = @_;
	my $formatter = $args->{formatter};
	return $formatter if ref $formatter eq 'CODE';

	my $syntax = $args->{template_syntax} || 'HTML';
	my $modifiers = $self->_collectModifiers($args);

	my $sp     = String::Print->new(
		encode_for => ($syntax eq 'HTML' ? $syntax : undef),
		modifiers  => $modifiers,
	);

	sub { $sp->sprinti(@_) };
}

#--------------------

sub formatter() { $_[0]->{LRT_formatter} }


sub translateTo(;$)
{	my $self = shift;
	my $old  = $self->{LRT_trTo};
	@_ or return $old;

	my $lang = shift;

	return $lang   # language unchanged?
		if ! defined $lang ? ! defined $old : ! defined $old  ? 0 : $lang eq $old;

	$_->translateTo($lang) for $self->domains;
	$self->{LRT_trTo} = $lang;
}

#--------------------


sub addTextdomain($%) {
	my ($self, %args) = @_;

	if(my $only = $args{only_in_directory})
	{	my $delim = $self->{LRT_delim};
		$only     = $args{only_in_directory} = [ split $delim, $only ]
			if ref $only ne 'ARRAY';

		my @incl  = $self->_incl_path;
		foreach my $dir (@$only)
		{	next if grep $_ eq $dir, @incl;
			error __x"directory {dir} not in INCLUDE_PATH, used by {option}", dir => $dir, option => 'addTextdomain(only_in_directory)';
		}
	}

	$args{templater} ||= $self;
	$args{lang}      ||= $self->translateTo;

	my $name    = $args{name};
	my $td_class= $self->{LRT_tdc};
	my $domain;
	if($domain  = textdomain $name, 'EXISTS')
	{	$td_class->upgrade($domain, %args);
	}
	else
	{	$domain = textdomain($td_class->new(%args));
	}

	my $func    = $domain->function;
	if((my $other) = grep $func eq $_->function, $self->domains)
	{	error __x"translation function '{func}' already in use by textdomain '{name}'", func => $func, name => $other->name;
	}
	$self->{LRT_domains}{$name} = $domain;

	# call as function or as filter
	$self->_stash->{$func}  = $domain->translationFunction($self->service);
	$self->context->define_filter($func => $domain->translationFilter, 1);
	$domain;
}

sub _incl_path() { @{ $_[0]->{LRT_path}} }
sub _stash()     { $_[0]->service->context->stash }


sub domains()   { values %{$_[0]->{LRT_domains} } }


sub domain($)   { $_[0]->{LRT_domains}{$_[1]} }


sub extract(%)
{	my ($self, %args) = @_;

	eval "require Log::Report::Template::Extract";
	panic $@ if $@;

	my $stats   = $args{show_stats} || 0;
	my $charset = $args{charset}    || 'UTF-8';
	my $write   = exists $args{write_tables} ? $args{write_tables} : 1;

	my @filenames;
	if(my $fns  = $args{filenames} || $args{filename})
	{	push @filenames, ref $fns eq 'ARRAY' ? @$fns : $fns;
	}
	else
	{	my $match = $args{filename_match} || qr/\.tt2?$/;
		my $filter = sub {
			my $name = $File::Find::name;
			push @filenames, $name if -f $name && $name =~ $match;
		};
		foreach my $dir ($self->_incl_path)
		{	trace "scan $dir for template files";
			find { wanted => sub { $filter->($File::Find::name) }, no_chdir => 1}, $dir;
		}
	}

	foreach my $domain ($self->domains)
	{	my $function = $domain->function;
		my $name     = $domain->name;

		trace "extracting msgids for '$function' from domain '$name'";

		my $extr = Log::Report::Template::Extract->new(
			lexicon => $domain->lexicon,
			domain  => $name,
			pattern => "TT2-$function",
			charset => $charset,
		);

		$extr->process($_)
			for @filenames;

		$extr->showStats;
		$extr->write     if $write;
	}
}

#--------------------

sub _cols_factory(@)
{	my $self = shift;
	my $params = ref $_[-1] eq 'HASH' ? pop : undef;
	my @blocks = @_ ? @_ : 'td';
	if(@blocks==1 && $blocks[0] =~ /\$[1-9]/)
	{	my $pattern = shift @blocks;
		return sub {    # second syntax
			my @cols = split /\t/, $_[0];
			$pattern =~ s/\$([0-9]+)/$cols[$1-1] || ''/ge;
			$pattern;
		}
	}

	sub {    # first syntax
		my @cols = split /\t/, $_[0];
		my @wrap = @blocks;
		my @out;
		while(@cols)
		{	push @out, "<$wrap[0]>$cols[0]</$wrap[0]>";
			shift @cols;
			shift @wrap if @wrap > 1;
		}
		join '', @out;
	}
}


sub _br_factory(@)
{	my $self = shift;
	my $params = ref $_[-1] eq 'HASH' ? pop : undef;
	return sub {
		my $templ = shift or return '';
		for($templ)
		{	s/\A[\s\n]*\n//;     # leading blank lines
			s/\n[\s\n]*\n/\n/g;  # double blank links
			s/\n[\s\n]*\z/\n/;   # trailing blank lines
			s/\s*\n/<br>\n/gm;   # trailing blanks per line
		}
		$templ;
	}
}

sub _defaultFilters()
{	my $self    = shift;
	my $context = $self->context;
	$context->define_filter(cols => \&_cols_factory, 1);
	$context->define_filter(br   => \&_br_factory,   1);
	$self;
}


sub _collectModifiers($)
{	my ($self, $args) = @_;

	# First match will be used
	my @modifiers = @{$args->{modifiers} || []};

	# More default extensions expected here.  String::Print already adds a bunch.
	\@modifiers;
}


{	# Log::Report exports 'error', and we use that.  Our base-class
	# 'Template' however, also has a method named error() as well.
	# Gladly, they can easily be separated.

	# no warnings 'redefined' misbehaves, at least for perl 5.16.2
	no warnings;

	sub error()
	{
		blessed $_[0] && $_[0]->isa('Template')
			or return Log::Report::error(@_);

		$_[0]->{LRT_exceptions}
			or return shift->SUPER::error(@_);

		@_ or panic "inexpected call to collect errors()";

		# convert Template errors into Log::Report errors
		Log::Report::error($_[1]);
	}
}


#--------------------

1;
