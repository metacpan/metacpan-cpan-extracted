###########################################################################
#
#   Tag.pm
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
package Log::Agent::Tag;

#
# ->make
#
# Creation routine.
#
sub make {
	my $self = bless {}, shift;
	require Carp;
	Carp::confess("deferred");
}

#
# Attribute access
#

sub postfix		{ $_[0]->{'postfix'} }
sub name		{ $_[0]->{'name'} }
sub separator	{ $_[0]->{'separator'} }

#
# ->_init
#
# Initialization routine for common attributes:
#
#   postfix            if true, appends tag to message, otherwise prepends
#   name               the tag name
#   separator          the string to use before or after tag (defaults to " ")
#
# Called by each creation routine in heirs.
#
sub _init {
	my $self = shift;
	my ($name, $postfix, $separator) = @_;
	$separator = " " unless defined $separator;
	$self->{name}      = $name;
	$self->{postfix}   = $postfix;
	$self->{separator} = $separator;
	return;
}

#
# ->string			-- deferred
#
# Build tag string.
# Must be implemented by heirs.
#
sub string {
	require Carp;
	Carp::confess("deferred");
}

#
# ->insert			-- frozen
#
# Merge string into the log message, according to our configuration.
#
sub insert {
	my $self = shift;
	my ($str) = @_;			# A Log::Agent::Message object

	my $string = $self->string;
	my $separator = $self->separator;

	#
	# Merge into the Log::Agent::Message object string.
	#

	if ($self->postfix) {
		$str->append($separator . $string);
	} else {
		$str->prepend($string . $separator);
	}

	return;
}

1;			# for "require"
__END__

=head1 NAME

Log::Agent::Tag - formats caller information

=head1 SYNOPSIS

 Intended to be inherited from

=head1 DESCRIPTION

This class is meant to be inherited by all the classes implementing a log
message tag.

A message tag is a little string that is either appended or prepended to
all log messages.

For instance, and oversimplifying a bit, a tag meant to be prepended will be
inserted in front of the current log message, separated by I<separator>,
which defaults to a single space:

   +------------+-----------+---------------------------------+
   | tag string | separator |      current log message        |
   +------------+-----------+---------------------------------+

This operation is called I<tag insertion>. The whole string then becomes
the I<current log message>, and can be the target of another tag insertion.

The reality is a little bit more complex, to allow successive tags to be
prepended or appended in the order they are specified, and not in reverse
order as they would be if naively implemented.  See L<Log::Agent::Message>
for the exact semantics of append() and prepend() operations.

=head1 FEATURES

This section documents the interface provided to heirs, in case you wish
to implement your own tag class.

=over 4

=item _init(I<name>, I<postfix>, I<separator>)

Initialization routine that should be called by all heirs during creation
to initialize the common attributes.

=item postfix

When true, the tag is meant to be appended to the log message.  Otherwise,
it is prepended.

=item name

The name of this tag.  It is meant to provide by-name access to tags, check
whether a given tag is recorded, etc...  The names "caller" and "priority"
are architecturally defined to refer to C<Log::Agent::Tag::Caller> and
C<Log::Agent::Tag::Priority> objects.

B<NOTE>: Currently unused by any client code.

=item separator

The sperating string inserted between the tag and the log message.
It defaults to C<" "> if not specified, i.e. left to C<undef> when
calling _init().

=item string()

A B<deferred> routine, to be implemented by heirs.

Returns the tag string only, without the separator, since its exact placement
depends on the value of the C<postfix> attribute.

=item insert(I<message>)

Insert this tag withing the C<Log::Agent::Message> I<message>, according
to the tag specifications (placement, separator).  Calls string() to produce
the tag string.

This routine is B<frozen> and should not be redefined by heirs.

=back

=head1 STANDARD TAGGING CLASSES

Tagging classes define via their C<string()> routine what is the string
to be used as a tag.  The insertion of the tag within the log message
is done via a frozen routine from the C<Log::Agent::Tag> ancestor.

The following classes are provided by C<Log::Agent>:

=over 4

=item C<Log::Agent::Tag::Callback>

The C<string()> routine invokes a user-supplied callback, given as a
C<Callback> object.  You need the Callback module from CPAN if you
wish to use this class.

=item C<Log::Agent::Tag::Caller>

Used internally to compute the caller and format it according
to user specifications.

=item C<Log::Agent::Tag::Priority>

Used internally to format message priorities and add them to the log messages.

=item C<Log::Agent::Tag::String>

Defines a constant tagging string that should be added in all the
log messages, e.g. a web session ID.

=back

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent::Message(3).

=cut
