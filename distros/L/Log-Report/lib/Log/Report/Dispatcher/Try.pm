# This code is part of Perl distribution Log-Report version 1.42.
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

package Log::Report::Dispatcher::Try;{
our $VERSION = '1.42';
}

use base 'Log::Report::Dispatcher';

use warnings;
use strict;

use Log::Report 'log-report', syntax => 'SHORT';
use Log::Report::Exception ();
use Log::Report::Util      qw/%reason_code expand_reasons/;
use List::Util             qw/first/;

#--------------------

use overload
	bool     => 'failed',
	'""'     => 'showStatus',
	fallback => 1;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	defined $self->SUPER::init($args) or return;

	$self->{exceptions} = delete $args->{exceptions} || [];
	$self->{died}       = delete $args->{died};
	$self->hide($args->{hide} // 'NONE');
	$self->{on_die}     = $args->{on_die} // 'ERROR';
	$self;
}

#--------------------

sub died(;$)
{	my $self = shift;
	@_ ? ($self->{died} = shift) : $self->{died};
}


sub exceptions() { @{ $_[0]->{exceptions}} }


sub hides($) { $_[0]->{LRDT_hides}{$_[1]} }


sub hide(@)
{	my $self = shift;
	my @reasons = expand_reasons(@_ > 1 ? \@_ : shift);
	$self->{LRDT_hides} = +{ map +($_ => 1), @reasons };
}


sub die2reason() { $_[0]->{on_die} }

#--------------------

sub log($$$$)
{	my ($self, $opts, $reason, $message, $domain) = @_;

	unless($opts->{stack})
	{	my $mode = $self->mode;
		$opts->{stack} = $self->collectStack
			if $reason eq 'PANIC'
			|| ($mode==2 && $reason_code{$reason} >= $reason_code{ALERT})
			|| ($mode==3 && $reason_code{$reason} >= $reason_code{ERROR});
	}

	$opts->{location} ||= '';

	push @{$self->{exceptions}},
		Log::Report::Exception->new(reason => $reason, report_opts => $opts, message => $message);

	$self;
}


sub reportFatal(@) { my $s = shift; $_->throw(@_) for $s->wasFatal   }
sub reportAll(@)   { my $s = shift; $_->throw(@_) for $s->exceptions }

#--------------------

sub failed()  {   defined shift->{died} }
sub success() { ! defined shift->{died} }


sub wasFatal(@)
{	my ($self, %args) = @_;
	defined $self->{died} or return ();

	my $ex = first { $_->isFatal } @{$self->{exceptions}}
		or return ();

	# There can only be one fatal exception.  Is it in the class?
	(!$args{class} || $ex->inClass($args{class})) ? $ex : ();
}


sub showStatus()
{	my $self  = shift;
	my $fatal = $self->wasFatal or return '';
	__x"try-block stopped with {reason}: {text}", reason => $fatal->reason, text => $self->died;
}

1;
