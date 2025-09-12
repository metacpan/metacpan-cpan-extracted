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

package Log::Report::Exception;{
our $VERSION = '1.41';
}


use warnings;
use strict;

use Log::Report      'log-report';
use Log::Report::Util qw/is_fatal to_html/;
use POSIX             qw/locale_h/;
use Scalar::Util      qw/blessed/;

#--------------------

use overload
	'""'     => 'toString',
	bool     => sub {1},    # avoid accidental serialization of message
	fallback => 1;

#--------------------

sub new($@)
{	my ($class, %args) = @_;
	$args{report_opts} ||= {};
	bless \%args, $class;
}

#--------------------

sub report_opts() { $_[0]->{report_opts} }


sub reason(;$)
{	my $self = shift;
	@_ ? $self->{reason} = uc(shift) : $self->{reason};
}


sub isFatal()
{	my $self = shift;
	my $opts = $self->report_opts;
	exists $opts->{is_fatal} ? $opts->{is_fatal} : is_fatal $self->{reason};
}


sub message(;$)
{	my $self = shift;
	@_ or return $self->{message};

	my $msg  = shift;
	blessed $msg && $msg->isa('Log::Report::Message')
		or panic "message() of exception expects Log::Report::Message";
	$self->{message} = $msg;
}

#--------------------

sub inClass($) { $_[0]->message->inClass($_[1]) }


sub throw(@)
{	my $self    = shift;
	my %opts    = ( %{$self->{report_opts}}, @_ );

	my $reason;
	if($reason = delete $opts{reason})
	{	exists $opts{is_fatal} or $opts{is_fatal} = is_fatal $reason;
	}
	else
	{	$reason = $self->{reason};
	}

	$opts{stack} ||= Log::Report::Dispatcher->collectStack;
	report \%opts, $reason, $self;
}

# where the throw is handled is not interesting
sub PROPAGATE($$) { $_[0] }


sub toString(;$)
{	my ($self, $locale) = @_;
	my $msg  = $self->message;
	lc($self->{reason}).': '.(ref $msg ? $msg->toString($locale) : $msg)."\n";
}


sub toHTML(;$) { to_html($_[0]->toString($_[1])) }


sub print(;$)
{	my $self = shift;
	(shift || *STDERR)->print($self->toString);
}

1;
