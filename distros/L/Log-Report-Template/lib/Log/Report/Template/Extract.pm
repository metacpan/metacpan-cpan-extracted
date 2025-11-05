# This code is part of Perl distribution Log-Report-Template version 1.04.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2017-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Log::Report::Template::Extract;{
our $VERSION = '1.04';
}

use base 'Log::Report::Extract';

use warnings;
use strict;

use Log::Report 'log-report-template';

use Log::Report::Template::Textdomain  ();
sub _normalized_ws($) { Log::Report::Template::Textdomain::_normalized_ws($_[0]) }

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);
	$self->{LRTE_domain}  = $args->{domain}
		or error __"template extract requires explicit domain";

	$self->{LRTE_pattern} = $args->{pattern};
	$self;
}

#--------------------

sub domain()  { $_[0]->{LRTE_domain} }
sub pattern() { $_[0]->{LRTE_pattern} }

#--------------------

sub process($@)
{	my ($self, $fn, %opts) = @_;

	my $charset = $opts{charset} || 'utf-8';
	info __x"processing file {file} in {charset}", file => $fn, charset => $charset;

	my $pattern = $opts{pattern} || $self->pattern
		or error __"need pattern to scan for, either via new() or process()";

	# Slurp the whole file
	open my $in, "<:encoding($charset)", $fn
		or fault __x"cannot read template from {file}", file => $fn;

	undef $/;
	my $text = $in->getline;
	$in->close;

	my $domain  = $self->domain;
	$self->_reset($domain, $fn);

	if(ref $pattern eq 'CODE')
	{	return $pattern->($fn, \$text);
	}
	elsif($pattern =~ m/^TT([12])-(\w+)$/)
	{	return $self->scanTemplateToolkit($1, $2, $fn, \$text);
	}
	else
	{	error __x"unknown pattern {pattern}", pattern => $pattern;
	}

	();
}

sub _no_escapes_in($$$$)
{	my ($msgid, $plural, $fn, $linenr) = @_;
	return if $msgid !~ /\&\w+\;/ && (defined $plural ? $plural !~ /\&\w+\;/ : 1);
	$msgid .= "|$plural" if defined $plural;

	warning __x"msgid '{msgid}' contains html escapes, don't do that.  File {file} line {linenr}", msgid => $msgid, file => $fn, linenr => $linenr;
}


sub scanTemplateToolkit($$$$)
{	my ($self, $version, $function, $fn, $textref) = @_;

	# Split the whole file on the pattern in four fragments per match:
	#       (text, leading, needed trailing, text, leading, ...)
	# f.i.  ('', '[% loc("', 'some-msgid', '", params) %]', ' more text')
	my @frags = $version==1
	  ? split(/[\[%]%(.*?)%[%\]]/s, $$textref)
	  : split(/\[%(.*?)%\]/s, $$textref);

	my $domain     = $self->domain;
	my $linenr     = 1;
	my $msgs_found = 0;

	# pre-compile the regexes, for performance
	my $pipe_func_block  = qr/^\s*(?:\|\s*|FILTER\s+)$function\b/;
	my $msgid_pipe_func  = qr/^\s*(["'])([^\r\n]+?)\1\s*\|\s*$function\b/;
	my $func_msgid_multi = qr/(\b$function\s*\(\s*)(["'])([^\r\n]+?)\2/s;

	while(@frags > 2)
	{	my ($skip_text, $take) = (shift @frags, shift @frags);
		$linenr += $skip_text =~ tr/\n//;
		if($take =~ $pipe_func_block)
		{	# [% | loc(...) %] $msgid [%END%]  or [% FILTER ... %]...[% END %]
			if(@frags < 2 || $frags[1] !~ /^\s*END\s*$/)
			{	error __x"template syntax error, no END in {fn} line {line}", fn => $fn, line => $linenr;
			}
			my $msgid  = $frags[0];  # next content
			my $plural = $msgid =~ s/\|(.*)// ? $1 : undef;
			_no_escapes_in $msgid, $plural, $fn, $linenr;

			$self->store($domain, $fn, $linenr, _normalized_ws($msgid), _normalized_ws($plural));
			$msgs_found++;

			$linenr   += $take =~ tr/\n//;
			next;
		}

		if($take =~ $msgid_pipe_func)
		{	# [% $msgid | loc(...) %]
			my $msgid  = $2;
			my $plural = $msgid =~ s/\|(.*)// ? $1 : undef;
			_no_escapes_in $msgid, $plural, $fn, $linenr;

			$self->store($domain, $fn, $linenr, $msgid, $plural);
			$msgs_found++;

			$linenr   += $take =~ tr/\n//;
			next;
		}

		# loc($msgid, ...) form, can appear more than once
		my @markup = split $func_msgid_multi, $take;
		while(@markup > 4)
		{	# quads with text, call, quote, msgid
			$linenr   += ($markup[0] =~ tr/\n//) + ($markup[1] =~ tr/\n//);
			my $msgid  = $markup[3];
			my $plural = $msgid =~ s/\|(.*)// ? $1 : undef;
			_no_escapes_in $msgid, $plural, $fn, $linenr;

			$self->store($domain, $fn, $linenr, $msgid, $plural);
			$msgs_found++;
			splice @markup, 0, 4;
		}
		$linenr += $markup[-1] =~ tr/\n//; # rest of container
	}
#   $linenr += $frags[-1] =~ tr/\n//; # final page fragment not needed

	$msgs_found;
}

#--------------------

1;
