###########################################################################
#
#   Handle.pm
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
require Log::Agent::Channel;
require Log::Agent::Prefixer;
require Log::Agent::File::Native;

########################################################################
package Log::Agent::Channel::Handle;

use vars qw(@ISA);

@ISA = qw(Log::Agent::Channel Log::Agent::Prefixer);

use Log::Agent::Stamping;

#
# ->make			-- defined
#
# Creation routine.
#
# Attributes (and switches that set them):
#
# prefix		the application name
# stampfmt		stamping format ("syslog", "date", "own", "none") or closure
# showpid		whether to show pid after prefix in []
# handle		I/O glob or IO::Handle object
# no_ucfirst    don't capitalize first letter of message when no prefix
# no_prefixing  don't prefix logs
# no_newline	never append any newline character at the end of messages
#
# Other attributes:
#
# crlf          the new-line marker for this OS ("\n" on UNIX)
#
sub make {
	my $self = bless {}, shift;
	my (%args) = @_;

	my %set = (
		-prefix			=> \$self->{'prefix'},
		-stampfmt		=> \$self->{'stampfmt'},
		-showpid		=> \$self->{'showpid'},
		-handle			=> \$self->{'handle'},
		-no_ucfirst		=> \$self->{'no_ucfirst'},
		-no_prefixing	=> \$self->{'no_prefixing'},
		-no_newline		=> \$self->{'no_newline'},
	);

	while (my ($arg, $val) = each %args) {
		my $vset = $set{lc($arg)};
		unless (ref $vset) {
			require Carp;
			Carp::croak("Unknown switch $arg");
		}
		$$vset = $val;
	}

	#
	# Initialize proper time-stamping routine.
	#

	$self->{'stampfmt'} = stamping_fn($self->stampfmt)
		unless ref $self->stampfmt eq 'CODE';

	$self->{'crlf'} = $^O =~ /^dos|win/i ? "\r\n" : "\n";

	return $self;
}

#
# Local attribute access
#

sub handle			{ $_[0]->{'handle'} }

#
# ->write			-- defined
#
# Write logstring to the file.
# Priority is ignored by this channel.
#
sub write {
	my $self = shift;
	my ($priority, $logstring) = @_;

	#
	# This routine is called often...
	# Bypass the attribute access routines.
	#

	my $handle = $self->{handle};
	return unless defined $handle;

	my $prefix = '';
	$prefix = $self->prefixing_string(\$logstring)
		unless $self->{no_prefixing};

	my $crlf = '';
	$crlf = $self->{crlf} unless $self->{no_newline};

	print $handle join '', $prefix, $logstring, $crlf;

	return;
}

#
# ->close			-- defined
#
#
sub close {
	my $self = shift;
	$self->{handle} = undef;

	#
	# Do nothing on the handle itself.
	# We did not open the thing, we don't get to close it.
	#

	return;
}

1;	# for require
__END__

=head1 NAME

Log::Agent::Channel::Handle - I/O handle logging channel for Log::Agent

=head1 SYNOPSIS

 require Log::Agent::Channel::Handle;

 my $driver = Log::Agent::Channel::Handle->make(
     -prefix     => "prefix",
     -stampfmt   => "own",
     -showpid    => 1,
     -handle     => \*FILE,
 );

=head1 DESCRIPTION

The handle channel performs logging to an already opened I/O handle,
along with the necessary prefixing and stamping of the messages.

The creation routine make() takes the following arguments:

=over 4

=item C<-handle> => I<handle>

Specifies the I/O I<handle> to use.  It can be given as a GLOB reference,
such as C<\*FILE>, or as an C<IO::Handle> object.

B<NOTE>: Auto-flushing is not enabled on the I<handle>.  Even when the
channel is closed, the I<handle> is left as-is: we simply stop sending
log messages to it.

=item C<-no_newline> => I<flag>

When set to I<true>, never append any "\n" (on Unix) or "\r\n" (on Windows)
to log messages.

Internally, Log::Agent relies on the channel to delimit logged lines
appropriately, so this flag is not used.  However, it might be useful
for C<Log::Agent::Logger> users.

Default is I<false>, meaning newline markers are systematically appended.

=item C<-no_prefixing> => I<flag>

When set to I<true>, disable the prefixing logic entirely, i.e. the
following options are ignored completely: C<-prefix>, C<-showpid>,
C<-no_ucfirst>, C<-stampfmt>.

Default is I<false>.

=item C<-no_ucfirst> => I<flag>

When set to I<true>, don't upper-case the first letter of the log message
entry when there's no prefix inserted before the logged line.  When there
is a prefix, a ":" character follows, and therefore the leading letter
of the message should not be upper-cased anyway.

Default is I<false>, meaning uppercasing is performed.

=item C<-prefix> => I<prefix>

The application prefix string to prepend to messages.

=item C<-showpid> => I<flag>

If set to true, the PID of the process will be appended within square
brackets after the prefix, to all messages.

Default is I<false>.

=item C<-stampfmt> => (I<name> | I<CODE>)

Specifies the time stamp format to use. By default, my "own" format is used.
See L<Log::Agent::Stamping> for a description of the available format names.

You may also specify a CODE ref: that routine will be called every time
we need to compute a time stamp. It should not expect any parameter, and
should return a string.

=back

=head1 CAVEAT

Beware of chdir().  If your program uses chdir(), you should always specify
logfiles by using absolute paths, otherwise you run the risk of having
your relative paths become invalid: there is no anchoring done at the time
you specify them.  This is especially true when configured for rotation,
since the logfiles are recreated as needed and you might end up with many
logfiles scattered throughout all the directories you chdir()ed to.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent::Logger(3), Log::Agent::Channel(3).

=cut
