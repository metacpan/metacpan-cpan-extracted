###########################################################################
#
#   Prefixer.pm
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

use strict;

########################################################################
package Log::Agent::Prefixer;

#
# Ancestor for logging channels wishing to implement native prefixing
#

#
# Attribute access: those attributes must be filled by our heirs
#

sub prefix			{ $_[0]->{'prefix'} }
sub stampfmt		{ $_[0]->{'stampfmt'} }
sub showpid			{ $_[0]->{'showpid'} }
sub no_ucfirst		{ $_[0]->{'no_ucfirst'} }
sub no_prefixing	{ $_[0]->{'no_prefixing'} }
sub no_newline		{ $_[0]->{'no_newline'} }
sub crlf			{ $_[0]->{'crlf'} }

#
# ->prefixing_string
#
# Compute prefixing string: stamping and "prefix: " to be emitted before
# the logged string.
#
# Usage:
#
#   $str = $self->prefixing_string();    # no ucfirst support possible
#   $str = $self->prefixing_string(\$log_message);
#
# Leading char of to-be-logged string is upper-cased in-place if
# neither prefix nor pid are present, and behaviour was not disabled
# via a -no_ucfirst, and the second call form with a scalar ref is used.
#
sub prefixing_string {
	my $self = shift;

	#
	# This routine is called often...
	# Bypass the attribute access routines.
	#

	my $prefix = $self->{prefix};
	$prefix = '' unless defined $prefix;
	if ($self->{showpid}) {
		if ($prefix eq '') {
			$prefix = $$;
		} else {
			$prefix .= "[$$]";
		}
	} elsif ($prefix eq '') {
		my $rstr = $_[0];
		$$rstr =~ s/^(.)/\u$1/ if ref $rstr && !$self->{no_ucfirst};
	}
	my $stamp = &{$self->{stampfmt}};
	return
		($stamp eq '' ? '' : "$stamp ") .
		($prefix eq '' ? '' : "$prefix: ");
}

1;	# for require
