# This code is part of Perl distribution Mail-Message version 3.019.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Reporter;{
our $VERSION = '3.019';
}


use strict;
use warnings;

use Carp;
use Scalar::Util qw/dualvar blessed/;

#--------------------

my @levelname = (undef, qw(DEBUG NOTICE PROGRESS WARNING ERROR NONE INTERNAL));

my %levelprio = (ERRORS => 5, WARNINGS => 4, NOTICES => 2);
for(my $l = 1; $l < @levelname; $l++)
{	$levelprio{$levelname[$l]} = $l;
	$levelprio{$l} = $l;
}

sub new(@)
{	my $class = shift;
#confess "Parameter list has odd length: @_" if @_ % 2;
	(bless +{MR_log => 1, MR_trace => 1}, $class)->init({@_});
}

my ($default_log, $default_trace, $trace_callback);
sub init($)
{	my ($self, $args) = @_;
	$self->{MR_log}   = $levelprio{$args->{log}   || $default_log};
	$self->{MR_trace} = $levelprio{$args->{trace} || $default_trace};
	$self;
}

#--------------------

sub logSettings()
{	my $self = shift;
	(log => $self->{MR_log}, trace => $self->{MR_trace});
}

#--------------------

sub _trace_warn($$$)
{	my ($who, $level, $text) = @_;
	warn "$level: $text\n";
}

sub defaultTrace(;$$)
{	my $thing = shift;

	return ($default_log, $default_trace)
		unless @_;

	my $level = shift;
	my $prio  = $thing->logPriority($level)
		or croak "Unknown trace-level $level.";

	if( ! @_)
	{	$default_log    = $default_trace = $prio;
		$trace_callback = \&_trace_warn;
	}
	elsif(ref $_[0])
	{	$default_log    = $thing->logPriority('NONE');
		$default_trace  = $prio;
		$trace_callback = shift;
	}
	else
	{	$default_log    = $prio;
		$default_trace  = $thing->logPriority(shift);
		$trace_callback = \&_trace_warn;
	}

	($default_log, $default_trace);
}

__PACKAGE__->defaultTrace('WARNINGS');



sub trace(;$$)
{	my $self = shift;

	@_ or return $self->logPriority($self->{MR_trace});

	my $level = shift;
	my $prio  = $levelprio{$level}
		or croak "Unknown trace-level $level.";

	$self->{MR_trace} = $prio;
}



# Implementation detail: the Mail::Box::Parser::C code avoids calls back
# to Perl by checking the trace-level itself.  In the perl code of this
# module however, just always call the log() method, and let it check
# whether or not to display it.

sub log(;$@)
{	if(blessed $_[0])   # instance call
	{	my $self = shift;
		@_ or return $self->logPriority($self->{MR_log});

		my $level = shift;
		my $prio  = $levelprio{$level} or croak "Unknown log-level $level";

		@_ or return $self->{MR_log} = $prio;

		my $text    = join '', @_;
		$trace_callback->($self, $level, $text)
			if $prio >= $self->{MR_trace};

		push @{$self->{MR_report}[$prio]}, $text
			if $prio >= $self->{MR_log};

		return $self;
	}

	# class method
	my ($class, $level) = (shift, shift);
	my $prio  = $levelprio{$level} or croak "Unknown log-level $level";

	$trace_callback->($class, $level, join('', @_))
		if $prio >= $default_trace;

	$class;
}


sub report(;$)
{	my $self    = shift;
	my $reports = $self->{MR_report} || return ();

	if(@_)
	{	my $level = shift;
		my $prio  = $levelprio{$level} or croak "Unknown report level $level.";
		return $reports->[$prio] ? @{$reports->[$prio]} : ();
	}

	my @reports;
	for(my $prio = 1; $prio < @$reports; $prio++)
	{	$reports->[$prio] or next;
		my $level = $levelname[$prio];
		push @reports, map +[ $level, $_ ], @{$reports->[$prio]};
	}

	@reports;
}


sub addReport($)
{	my ($self, $other) = @_;
	my $from = $other->{MR_report} || return ();

	for(my $prio = 1; $prio < @$from; $prio++)
	{	my $take = $from->[$prio] or next;
		push @{$self->{MR_report}[$prio]}, @$take;
	}
	$self;
}


sub reportAll(;$)
{	my $self = shift;
	map +[ $self, @$_ ], $self->report(@_);
}


sub warnings(@) { $_[0]->report('WARNINGS') }
sub errors(@)   { $_[0]->report('ERRORS') }


sub notImplemented(@)
{	my $self    = shift;
	my $package = ref $self || $self;
	my $sub     = (caller 1)[3];

	$self->log(ERROR => "Package $package does not implement $sub.");
	confess "Please warn the author, this shouldn't happen.";
}


sub logPriority($)
{	my $level = $levelprio{$_[1]} or return undef;
	dualvar $level, $levelname[$level];
}


sub AUTOLOAD(@)
{	my $thing   = shift;
	our $AUTOLOAD;
	my $class  = ref $thing || $thing;
	my $method = $AUTOLOAD =~ s/^.*\:\://r;

	$Carp::MaxArgLen=20;
	confess "Method $method() is not defined for a $class.\n";
}

#--------------------

sub DESTROY { $_[0] }

1;
