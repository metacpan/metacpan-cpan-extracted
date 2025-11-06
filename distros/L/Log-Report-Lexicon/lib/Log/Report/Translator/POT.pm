# This code is part of Perl distribution Log-Report-Lexicon version 1.15.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2007-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!
#oorestyle: old style disclaimer to be removed.

# This code is part of distribution Log-Report-Lexicon. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Log::Report::Translator::POT;{
our $VERSION = '1.15';
}

use base 'Log::Report::Translator';

use warnings;
use strict;

use Log::Report 'log-report-lexicon';

use Log::Report::Lexicon::Index;
use Log::Report::Lexicon::POTcompact;

use POSIX        qw/:locale_h/;
use Scalar::Util qw/blessed/;
use File::Spec   ();

my %lexicons;
sub _fn_to_lexdir($);

# Work-around for missing LC_MESSAGES on old Perls and Windows
{	no warnings;
	eval "&LC_MESSAGES";
	*LC_MESSAGES = sub(){5} if $@;
}

#--------------------


sub new(@)
{	my $class = shift;
	# Caller cannot wait until init()
	$class->SUPER::new(callerfn => (caller)[1], @_);
}

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	my $lex = delete $args->{lexicons} || delete $args->{lexicon} ||
		(ref $self eq __PACKAGE__ ? [] : _fn_to_lexdir $args->{callerfn});

	+($Log::Report::Lexicon::Index::VERSION || 999) >= 1.00
		or error __x"You have to upgrade Log::Report::Lexicon to at least 1.00";

	my @lex;
	foreach my $dir (ref $lex eq 'ARRAY' ? @$lex : $lex)
	{	# lexicon indexes are shared
		my $l = $lexicons{$dir} ||= Log::Report::Lexicon::Index->new($dir);
		$l->index;   # index the files now
		push @lex, $l;
	}
	$self->{LRTP_lexicons} = \@lex;
	$self->{LRTP_charset}  = $args->{charset};
	$self;
}

sub _fn_to_lexdir($)
{	my $fn = shift;
	$fn =~ s/\.pm$//;
	File::Spec->catdir($fn, 'messages');
}

#--------------------

sub lexicons() { @{ $_[0]->{LRTP_lexicons}} }


sub charset() { $_[0]->{LRTP_charset} }

#--------------------

sub translate($;$$)
{	my ($self, $msg, $lang, $ctxt) = @_;
	#!!! do not debug with $msg in a print: recursion

	my $domain = $msg->{_domain};
	my $dname  = blessed $domain ? $domain->name : $domain;

	my $locale = $lang || setlocale(LC_MESSAGES)
		or return $self->SUPER::translate($msg, $lang, $ctxt);

	my $pot
	  = exists $self->{LRTP_pots}{$dname}{$locale}
	  ? $self->{LRTP_pots}{$dname}{$locale}
	  : $self->load($dname, $locale);

	   ($pot ? $pot->msgstr($msg->{_msgid}, $msg->{_count}, $ctxt) : undef)
	|| $self->SUPER::translate($msg, $lang, $ctxt);
}

sub load($$)
{	my ($self, $dname, $locale) = @_;

	foreach my $lex ($self->lexicons)
	{	my $fn = $lex->find($dname, $locale);

		!$fn && $lex->list($dname)
			and last; # there are tables for dname, but not our lang

		$fn or next;

		my ($ext) = lc($fn) =~ m/\.(\w+)$/;
		my $class
		  = $ext eq 'mo' ? 'Log::Report::Lexicon::MOTcompact'
		  : $ext eq 'po' ? 'Log::Report::Lexicon::POTcompact'
		  :     error __x"unknown translation table extension '{ext}' in {filename}", ext => $ext, filename => $fn;

		info __x"read table {filename} as {class} for {dname} in {locale}", filename => $fn, class => $class, dname => $dname, locale => $locale
			if $dname ne 'log-report';  # avoid recursion

		eval "require $class" or panic $@;

		return $self->{LRTP_pots}{$dname}{$locale} = $class->read($fn, charset => $self->charset);
	}

	$self->{LRTP_pots}{$dname}{$locale} = undef;
}

1;
