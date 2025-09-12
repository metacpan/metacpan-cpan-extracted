# This code is part of Perl distribution Log-Report version 1.41.
# The POD got stripped from this file by OODoc version 3.04.
# For contributors see file ChangeLog.

# This software is copyright (c) 2007-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Log::Report::Dispatcher::Syslog;{
our $VERSION = '1.41';
}

use base 'Log::Report::Dispatcher';

use warnings;
use strict;

use Log::Report 'log-report';

use Sys::Syslog        qw/:standard :extended :macros/;
use Log::Report::Util  qw/@reasons expand_reasons/;
use Encode             qw/encode/;

use File::Basename qw/basename/;

my %default_reasonToPrio = (
	TRACE   => LOG_DEBUG,
	ASSERT  => LOG_DEBUG,
	INFO    => LOG_INFO,
	NOTICE  => LOG_NOTICE,
	WARNING => LOG_WARNING,
	MISTAKE => LOG_WARNING,
	ERROR   => LOG_ERR,
	FAULT   => LOG_ERR,
	ALERT   => LOG_ALERT,
	FAILURE => LOG_EMERG,
	PANIC   => LOG_CRIT,
);

@reasons==keys %default_reasonToPrio
	or panic __"not all reasons have a default translation";

#--------------------

my $active;

sub init($)
{	my ($self, $args) = @_;
	$args->{format_reason} ||= 'IGNORE';

	$self->SUPER::init($args);

	! $active
		or error __x"max one active syslog dispatcher, attempt for {new} have {old}", new => $self->name, old => $active;
	$active   = $self->name;

	setlogsock(delete $args->{logsocket})
		if $args->{logsocket};

	my $ident = delete $args->{identity} || basename $0;
	my $flags = delete $args->{flags}    || 'pid,nowait';
	my $fac   = delete $args->{facility} || 'user';
	openlog $ident, $flags, $fac;   # doesn't produce error.

	$self->{LRDS_incl_dom} = delete $args->{include_domain};
	$self->{LRDS_charset}  = delete $args->{charset} || "utf-8";
	$self->{LRDS_format}   = $args->{format} || sub {$_[0]};

	$self->{prio} = +{ %default_reasonToPrio };
	if(my $to_prio = delete $args->{to_prio})
	{	my @to = @$to_prio;
		while(@to)
		{	my ($reasons, $level) = splice @to, 0, 2;
			my @reasons = expand_reasons $reasons;

			my $prio    = Sys::Syslog::xlate($level);
			$prio != -1
				or error __x"syslog level '{level}' not understood", level => $level;

			$self->{prio}{$_} = $prio for @reasons;
		}
	}

	$self;
}

sub close()
{	my $self = shift;
	undef $active;
	closelog;

	$self->SUPER::close;
}

#--------------------

sub format(;$)
{	my $self = shift;
	@_ ? $self->{LRDS_format} = shift : $self->{LRDS_format};
}

#--------------------

sub log($$$$$)
{	my ($self, $opts, $reason, $msg, $domain) = @_;
	my $text    = $self->translate($opts, $reason, $msg) or return;
	my $format  = $self->format;

	# handle each line in message separately
	$text       =~ s/\s+$//s;
	my @text    = split /\n/, $format->($text, $domain, $msg, %$opts);

	my $prio    = $self->reasonToPrio($reason);
	my $charset = $self->{LRDS_charset};

	if($self->{LRDS_incl_dom} && $domain)
	{	$domain =~ s/\%//g;    # security
		syslog $prio, "$domain %s", encode($charset, shift @text);
	}

	syslog $prio, "%s", encode($charset, $_)
		for @text;
}


sub reasonToPrio($) { $_[0]->{prio}{$_[1]} }

1;
