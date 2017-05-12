###########################################################################
#
#   Priority.pm
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
package Log::Agent::Tag::Priority;

require Log::Agent::Tag::String;
use vars qw(@ISA);
@ISA = qw(Log::Agent::Tag::String);

use Log::Agent::Priorities qw(level_from_prio prio_from_level);

#
# ->make
#
# Creation routine.
#
# Calling arguments: a hash table list.
#
# The keyed argument list may contain:
#	-POSTFIX	whether to postfix log message or prefix it.
#   -SEPARATOR  separator string to use between tag and message
#   -DISPLAY    a string like '[$priority:$level])'
#   -PRIORITY   the log priority string, e.g. "warning".
#   -LEVEL      the log level value, e.g. 4.
#
# Attributes:
#   none, besides the inherited ones
#
sub make {
	my $type = shift;
	my (%args) = @_;
	my $separator = " ";
	my $postfix = 0;
	my ($display, $priority, $level);

	my %set = (
		-display	=> \$display,
		-postfix	=> \$postfix,
		-separator	=> \$separator,
		-priority	=> \$priority,
		-level		=> \$level,
	);

	while (my ($arg, $val) = each %args) {
		my $vset = $set{lc($arg)};
		next unless ref $vset;
		$$vset = $val;
	}

	#
	# Normalize $priority to the full name (e.g. "err" -> "error")
	#

	$priority = prio_from_level level_from_prio $priority;

	#
	# Format according to -display specs.
	#
	# Since priority and level are fixed for this object, the resulting
	# string need only be computed once, i.e. now.
	#
	# The following variables are recognized:
	#
	#		$priority	 			priority name (e.g. "warning")
	#		$level					logging level
	#
	# We recognize both $level and ${level}.
	#

	$display =~ s/\$priority\b/$priority/g;
	$display =~ s/\$\{priority}/$priority/g;
	$display =~ s/\$level\b/$level/g;
	$display =~ s/\$\{level}/$level/g;

	#
	# Now create the constant tag string.
	#

	my $self = Log::Agent::Tag::String->make(
		-name		=> "priority",
		-value		=> $display,
		-postfix	=> $postfix,
		-separator	=> $separator,
	);

	return bless $self, $type;		# re-blessed in our package
}

1;			# for "require"
__END__

=head1 NAME

Log::Agent::Tag::Priority - a log priority tag string

=head1 SYNOPSIS

 Not intended to be used directly
 Inherits from Log::Agent::Tag.

=head1 DESCRIPTION

This class represents a log priority tag string.

=head1 CREATION ROUTINE PARAMETERS

The following parameters are defined, in alphabetical order:

=over 4

=item C<-display> => I<string>

Specifies the priority/level string to display, with minimal variable
substitution.  For instance:

 -display => '[$priority/$level]'

The defined variables are documented in the B<DISPLAY VARIABLES> section
underneath.

=item C<-level> => I<level>

This parameter is internally added by C<Log::Agent> when computing the
priority tag, since only it knows the level of the current message.

=item C<-postfix> => I<flag>

Whether tag should be placed after or before the log message.
By default, it is prepended to the log message, i.e. this parameter is false.

=item C<-priority> => I<prio>

This parameter is internally added by C<Log::Agent> when computing the
priority tag, since only it knows the priority of the current message.

=item C<-separator> => I<string>

The separation string between the tag and the log message.
A single space by default.

=back

=head1 DISPLAY VARIABLES

The C<-display> switch understands a few variables that can be substituted
in the supplied string.  Both $var and C<${var}> forms are supported.
Unknown variables are left untouched.

=over 4

=item C<$priority>

The full priority name of the logged message, e.g. "warning" or "error".

=item C<$level>

The associated priority level of the logged message, a number.  For instance,
the level associated to "warning" is C<4>.  See L<Log::Agent::Priorities>
for the default name -> level mapping.

=back

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent::Tag(3), Log::Agent::Message(3), Log::Agent::Priorities(3).

=cut
