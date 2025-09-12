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

package Log::Report::Dispatcher::File;{
our $VERSION = '1.41';
}

use base 'Log::Report::Dispatcher';

use warnings;
use strict;

use Log::Report  'log-report';
use POSIX        qw/strftime/;

use Encode       qw/find_encoding/;
use Fcntl        qw/:flock/;

#--------------------

sub init($)
{	my ($self, $args) = @_;

	if(!$args->{charset})
	{	my $lc = $ENV{LC_CTYPE} || $ENV{LC_ALL} || $ENV{LANG} || '';
		my $cs = $lc =~ m/\.([\w-]+)/ ? $1 : '';
		$args->{charset} = length $cs && find_encoding $cs ? $cs : undef;
	}

	$self->SUPER::init($args);

	my $name = $self->name;
	$self->{to}      = $args->{to}
		or error __x"dispatcher {name} needs parameter 'to'", name => $name;
	$self->{replace} = $args->{replace} || 0;

	my $format = $args->{format} || sub { '['.localtime()."] $_[0]" };
	$self->{LRDF_format}
	= ref $format eq 'CODE' ? $format
	: $format eq 'LONG'
	? sub {	my $msg    = shift;
			my $domain = shift || '-';
			my $stamp  = strftime "%Y-%m-%dT%H:%M:%S", gmtime;
			"[$stamp $$] $domain $msg";
	  }
	: error __x"unknown format parameter `{what}'", what => ref $format || $format;

	$self;
}



sub close()
{	my $self = shift;
	$self->SUPER::close
		or return;

	my $to = $self->{to};
	my @fh_to_close
	  = ref $to eq 'CODE'      ? values %{$self->{LRDF_out}}
	  : $self->{LRDF_filename} ? $self->{LRDF_output}
	  : ();

	$_ && $_->close for @fh_to_close;
	$self;
}

#--------------------

sub filename() { $_[0]->{LRDF_filename} }
sub format()   { $_[0]->{LRDF_format} }


sub output($)
{	# fast simple case
	return $_[0]->{LRDF_output} if $_[0]->{LRDF_output};

	my ($self, $msg) = @_;
	my $name = $self->name;

	my $to   = $self->{to};
	if(!ref $to)
	{	# constant file name
		$self->{LRDF_filename} = $to;
		my $binmode = $self->{replace} ? '>' : '>>';

		open my $f, "$binmode:raw", $to;
		unless($f)
		{	# avoid logging error to myself (issue #4)
			my $msg = __x"cannot write log into {file} with mode '{binmode}'", binmode => $binmode, file => $to;
			if(my @disp = grep $_->name ne $name, Log::Report::dispatcher('list'))
			{	$msg->to($disp[0]->name);
				error $msg;
			}
			else
			{	die $msg;
			}
		}

		$f->autoflush;
		return $self->{LRDF_output} = $f;
	}

	if(ref $to eq 'CODE')
	{	# variable filename
		my $fn = $self->{LRDF_filename} = $to->($self, $msg);
		return $self->{LRDF_output} = $self->{LRDF_out}{$fn};
	}

	# probably file-handle
	$self->{LRDF_output} = $to;
}


#--------------------

sub rotate($)
{	my ($self, $old) = @_;

	my $to   = $self->{to};
	my $logs = ref $to eq 'CODE' ? $self->{LRDF_out} : +{ $self->{to} => $self->{LRDF_output} };

	while(my ($log, $fh) = each %$logs)
	{	!ref $log
			or error __x"cannot rotate log file which was opened as file-handle";

		my $oldfn = ref $old eq 'CODE' ? $old->($log) : $old;
		trace "rotating $log to $oldfn";

		rename $log, $oldfn
			or fault __x"unable to rotate logfile {fn} to {oldfn}", fn => $log, oldfn => $oldfn;

		$fh->close;   # close after move not possible on Windows?

		open my $f, '>>:raw', $log
			or fault __x"cannot write log into {file}", file => $log;

		$self->{LRDF_output} = $logs->{$log} = $f;
		$f->autoflush;
	}

	$self;
}

#--------------------

sub log($$$$)
{	my ($self, $opts, $reason, $msg, $domain) = @_;
	my $trans = $self->translate($opts, $reason, $msg);
	my $text  = $self->format->($trans, $domain, $msg, %$opts);

	my $out   = $self->output($msg);
	flock $out, LOCK_EX;
	$out->print($text);
	flock $out, LOCK_UN;
}

1;
