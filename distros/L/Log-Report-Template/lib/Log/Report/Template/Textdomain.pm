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

package Log::Report::Template::Textdomain;{
our $VERSION = '1.04';
}

use base 'Log::Report::Domain';

use warnings;
use strict;

use Log::Report 'log-report-template';

use Log::Report::Message ();

use Scalar::Util         qw/weaken/;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args)->_initMe($args);
}

sub _initMe($)
{	my ($self, $args) = @_;

	if(my $only =  $args->{only_in_directory})
	{	my @only = ref $only eq 'ARRAY' ? @$only : $only;
		my $dirs = join '|', map "\Q$_\E", @only;
		$self->{LRTT_only_in} = qr!^(?:$dirs)(?:$|/)!;
	}

	$self->{LRTT_function} = $args->{translation_function} || 'loc';
	$self->{LRTT_lexicon}  = $args->{lexicon};
	$self->{LRTT_lang}     = $args->{lang};

	$self->{LRTT_templ}    = $args->{templater} or panic "Requires templater";
	weaken $self->{LRTT_templ};

	$self;
}



sub upgrade($%)
{	my ($class, $domain, %args) = @_;

	ref $domain eq 'Log::Report::Domain'
		or error __x"extension to domain '{name}' already exists", name => $domain->name;

	(bless $domain, $class)->_initMe(\%args);
}

#--------------------

sub templater() { $_[0]->{LRTT_templ} }


sub function() { $_[0]->{LRTT_function} }


sub lexicon() { $_[0]->{LRTT_lexicon} }


sub expectedIn($)
{	my ($self, $fn) = @_;
	my $only = $self->{LRTT_only_in} or return 1;
	$fn =~ $only;
}


sub lang() { $_[0]->{LRTT_lang} }

#--------------------

sub translateTo($)
{	my ($self, $lang) = @_;
	$self->{LRTT_lang} = $lang;
}



sub translationFunction($)
{	my ($self, $service) = @_;
	my $context = $service->context;

	# Prepare as much and fast as possible, because it gets called often!
	sub { # called with ($msgid, @positionals, [\%params])
		my $msgid  = shift;
		my $params = @_ && ref $_[-1] eq 'HASH' ? pop @_ : {};
		my $plural = $msgid =~ s/\|(.*)// ? $1 : undef;
		if(defined $plural && ! defined $params->{_count})
		{	@_ or error __x"no counting positional for '{msgid}'", msgid => $msgid;
			$params->{_count} = shift;
		}
		@_ and error __x"superfluous positional parameters for '{msgid}'", msgid => $msgid;

		Log::Report::Message->new(
			_msgid => $msgid, _plural => $plural, _domain => $self,
			%$params, _stash => $context->{STASH}, _expand => 1,
		)->toString($self->lang);
	};
}

# Larger HTML blocks are fragile in blanks.  We remove all superfluous blanks from the
# msgid, which will break translation of <pre> blocks :-)
sub _normalized_ws($)      # Code shared with ::Extract
{	defined $_[0] or return undef;
	$_[0] =~ s/[ \t]+/ /gr # remove blank repetition
		=~ s/^ //gmr     # no blanks in the beginning of the line
		=~ s/\A\n+//r    # no leading blank lines
		=~ s/\n+\z/\n/r; # no trailing blank lines;
}

sub translationFilter()
{	my $self   = shift;

	# Prepare as much and fast as possible, because it gets called often!
	# A TT filter can be either static or dynamic.  Dynamic filters need to
	# implement a "a factory for static filters": a sub which produces a
	# sub which does the real work.
	sub {
		my $context = shift;
		my $params  = @_ && ref $_[-1] eq 'HASH' ? pop @_ : {};
		$params->{_count} = shift if @_;
		$params->{_error} = 'too many' if @_;   # don't know msgid yet

		sub { # called with $msgid (template container content) only, the
			# parameters are caught when the factory produces this sub.
			my $msgid  = shift;
			my $plural = $msgid =~ s/\|(.*)// ? $1 : undef;
			defined $plural || ! defined $params->{_count}
				or error __x"message does not contain counting alternatives in '{msgid}'", msgid => $msgid;

			! defined $plural || defined $params->{_count}
				or error __x"no counting positional for '{msgid}'", msgid => $msgid;

			! $params->{_error}
				or error __x"superfluous positional parameters for '{msgid}'", msgid => $msgid;

			Log::Report::Message->new(_msgid => _normalized_ws($msgid), _plural => _normalized_ws($plural), _domain => $self,
				%$params, _stash => $context->{STASH}, _expand => 1,
			)->toString($self->lang);
		}
	};
}

sub _reportMissingKey($$)
{	my ($self, $sp, $key, $args) = @_;

	# Try to grab the value from the stash.  That's a major advantange
	# of TT over plain Perl: we have access to the variable namespace.

	my $stash = $args->{_stash};
	if($stash)
	{	my $value = $stash->get($key);
		return $value if defined $value && length $value;
	}

	warning __x"Missing key '{key}' in format '{format}', in {use //template}",
		key => $key, format => $args->{_format}, use => $stash->{template}{name};

	undef;
}

1;
