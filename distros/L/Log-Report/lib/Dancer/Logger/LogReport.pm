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

package Dancer::Logger::LogReport;{
our $VERSION = '1.41';
}

use base 'Dancer::Logger::Abstract', 'Exporter';

use strict;
use warnings;

use Scalar::Util            qw/blessed/;
use Log::Report             'log-report', import => 'report';
use Log::Report::Dispatcher ();

our $AUTHORITY = 'cpan:MARKOV';

our @EXPORT    = qw/
	trace
	assert
	notice
	alert
	panic
/;

my %level_dancer2lr =
( core  => 'TRACE',
	debug => 'TRACE'
);

#--------------------

# Add some extra 'levels'
sub trace   { goto &Dancer::Logger::debug  }
sub assert  { goto &Dancer::Logger::assert }
sub notice  { goto &Dancer::Logger::notice }
sub panic   { goto &Dancer::Logger::panic  }
sub alert   { goto &Dancer::Logger::alert  }

sub Dancer::Logger::assert { my $l = logger(); $l && $l->_log(assert => _serialize(@_)) }
sub Dancer::Logger::notice { my $l = logger(); $l && $l->_log(notice => _serialize(@_)) }
sub Dancer::Logger::alert  { my $l = logger(); $l && $l->_log(alert  => _serialize(@_)) }
sub Dancer::Logger::panic  { my $l = logger(); $l && $l->_log(panic  => _serialize(@_)) }

sub _log {
	my ($self, $level, $params) = @_;

	# all dancer levels are the same as L::R levels, except:
	my $msg;
	if(blessed $params && $params->isa('Log::Report::Message'))
	{	$msg = $params;
	}
	else
	{	$msg = $self->format_message($level => $params);
		$msg =~ s/\n+$//;
	}

	# The levels are nearly the same.
	my $reason = $level_dancer2lr{$level} // uc $level;

	# Gladly, report() does not get confused between Dancer's use of
	# Try::Tiny and Log::Report's try() which starts a new dispatcher.
	report +{ is_fatal => 0 }, $reason => $msg;

	undef;
}

1;
