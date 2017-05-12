###########################################################################
#
#   Priorities.pm
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
package Log::Agent::Priorities;

require Exporter;
use AutoLoader 'AUTOLOAD';
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS @LEVELS);
@ISA = qw(Exporter);

@LEVELS = qw(NONE EMERG ALERT CRIT ERROR WARN NOTICE INFO DEBUG);

@EXPORT = qw(priority_level);
@EXPORT_OK = qw(prio_from_level level_from_prio);
push(@EXPORT_OK, @LEVELS);

%EXPORT_TAGS = (LEVELS => \@LEVELS);

BEGIN {
	sub NONE ()		{-1}
	sub EMERG ()	 {0}
	sub ALERT ()	 {1}
	sub CRIT ()		 {2}
	sub ERROR ()	 {3}
	sub WARN ()		 {4}
	sub NOTICE ()	 {6}
	sub INFO ()		 {8}
	sub DEBUG ()	{10}
}

use vars qw(@basic_prio %basic_level);

@basic_prio = qw(
	emergency
	alert
	critical
	error
	warning warning
	notice notice
	info info);

%basic_level = (
	'em'	=> EMERG,		# emergency
	'al'	=> ALERT,		# alert
	'cr'	=> CRIT,		# critical
	'er'	=> ERROR,		# error
	'wa'	=> WARN,		# warning
	'no'	=> NOTICE,		# notice
	'in'	=> INFO,		# info
	'de'	=> DEBUG,		# debug
);

1;
__END__

#
# prio_from_level
#
# Given a level, compute suitable priority.
#
sub prio_from_level {
	my ($level) = @_;
	return 'none' if $level < 0;
	return 'debug' if $level >= @basic_prio;
	return $basic_prio[$level];
}

#
# level_from_prio
#
# Given a syslog priority, compute suitable level.
#
sub level_from_prio {
	my ($prio) = @_;
	return -1 if lc($prio) eq 'none';		# none & notice would look alike
	my $canonical = lc(substr($prio, 0, 2));
	return 10 unless exists $basic_level{$canonical};
	return $basic_level{$canonical} || -1;
}

#
# priority_level
#
# Decompiles priority which can be either a single digit, a "priority" string
# or a "priority:digit" string. Returns the priority (computed if none) and
# the level (computed if none).
#
sub priority_level {
	my ($id) = @_;
	return (prio_from_level($id), $id) if $id =~ /^\d+$/;
	return ($1, $2) if $id =~ /^([^:]+):(\d+)$/;
	return ($id, level_from_prio($id));
}

=head1 NAME

Log::Agent::Priorities - conversion between syslog priorities and levels

=head1 SYNOPSIS

 Not intended to be used directly

=head1 DESCRIPTION

This package contains routines to convert between syslog priorities
and logging levels: level_from_prio("crit") yields 2, and
prio_from_level(4) yields "warning", as does prio_from_level(5).

Here are the known priorities (which may be abbreviated to the first
2 letters, in a case-insensitive manner) and their corresponding
logging level:

      Name    Level   Traditional    Export
    --------- -----  --------------  ------
    none       -1                    NONE    (special, see text)
    emergency   0    (emerg, panic)  EMERG
    alert       1                    ALERT
    critical    2    (crit)          CRIT
    error       3    (err)           ERROR
    warning     4                    WARN
    notice      6                    NOTICE
    info        8                    INFO
    debug       10                   DEBUG

The values between parenthesis show the traditional syslog priority tokens.
The missing levels (5, 7, 9) are there for possible extension.
They currently map to the level immediately below.

The Export column lists the symbolic constants defined by this package.
They can be imported selectively, or alltogether via the C<:LEVELS>
tag, as in:

    use Log::Agent::Priorities qw(:LEVELS);

The special token "none" may be used (and spelled out fully) on special
occasions: it maps to -1, and is convenient when specifying a logging
level, for instance: specifying "none" ensures that B<no logging> will
take place, even for emergency situations.

Anywhere where a I<priority> is expected, one may specify a number taken
as a logging level or a string taken as a priority. If the default
mapping outlined above is not satisfactory, it can be redefined by
specifying, for instance C<"notice:9">. It will be taken as being of
level 9, but with a C<notice> priority nonetheless, not C<info> as
it would have been implicitely determined otherwise.

The routine priority_level() decompiles C<"notice:9"> into ("notice", 9),
and otherwise uses prio_from_level() or level_from_prio() to compute the
missing informatin.  For instance, given "critical", priority_level()
routine will return the tuple ("critical", 2).

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent(3), Log::Agent::Logger(3).

=cut
