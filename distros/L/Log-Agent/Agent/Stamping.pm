###########################################################################
#
#   Stamping.pm
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
require Exporter;

########################################################################
package Log::Agent::Stamping;

#
# Common time-stamping routines
#

use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);

@EXPORT = qw(stamping_fn);

my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @days = qw(Sun Mon Tue Wed Thu Fri Sat);

#
# stamp_none
#
# No timestamp
#
sub stamp_none {
	return '';
}

#
# stamp_syslog
#
# Syslog-like stamping: "Oct 27 21:09:33"
#
sub stamp_syslog {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	return sprintf "%s %2d %.2d:%.2d:%.2d",
		$months[$mon], $mday, $hour, $min, $sec;
}

#
# stamp_date
#
# Date format: "[Fri Oct 22 16:23:10 1999]"
#
sub stamp_date {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	return sprintf "[%s %s %2d %.2d:%.2d:%.2d %d]",
		$days[$wday], $months[$mon], $mday, $hour, $min, $sec, 1900 + $year;
}

#
# stamp_own
#
# Own format: "99/10/24 09:43:49"
#
sub stamp_own {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	return sprintf "%.2d/%.2d/%.2d %.2d:%.2d:%.2d",
		$year % 100, ++$mon, $mday, $hour, $min, $sec;
}

my %stamping = (
	'none'		=> \&stamp_none,
	'syslog'	=> \&stamp_syslog,
	'date'		=> \&stamp_date,
	'own'		=> \&stamp_own,
);

#
# stamping_fn
#
# Return proper time stamping function based on its 'tag'
# If tag is unknown, use stamp_own.
#
sub stamping_fn {
	my ($tag) = @_;
	return $stamping{$tag} if defined $tag && defined $stamping{$tag};
	return \&stamp_own;
}

1;	# for require
__END__

=head1 NAME

Log::Agent::Stamping - time-stamping routines

=head1 SYNOPSIS

 Not intended to be used directly

=head1 DESCRIPTION

This package contains routines to generate the leading time-stamping
on logged messages.  Formats are identified by a name, and the
stamping_fn() function converts that name into a CODE ref, defaulting
to the "own" format when given an unknown name.

Here are the known formats:

 date      "[Fri Oct 22 16:23:10 1999]"
 none
 own       "99/10/22 16:23:10"
 syslog    "Oct 22 16:23:10"

Channels or Drivers which take a C<-stampfmt> switch expect either a string
giving the format name (e.g. "date"), or a CODE ref.  That referenced
routine will be called every time we need to compute a time stamp.
It should not expect any parameter, and should return a stamping string.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent(3), Log::Agent::Channel(3), Log::Agent::Driver(3).

=cut
