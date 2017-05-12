###########################################################################
#
#   String.pm
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
package Log::Agent::Tag::String;

require Log::Agent::Tag;
use vars qw(@ISA);
@ISA = qw(Log::Agent::Tag);

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
#   -NAME       tag's name (optional)
#   -VALUE      string value to use
#
# Attributes:
#   string      the string value
#
sub make {
	my $self = bless {}, shift;
	my (%args) = @_;
	my ($name, $postfix, $separator, $value);

	my %set = (
		-name		=> \$name,
		-value		=> \$value,
		-postfix	=> \$postfix,
		-separator	=> \$separator,
	);

	while (my ($arg, $val) = each %args) {
		my $vset = $set{lc($arg)};
		next unless ref $vset;
		$$vset = $val;
	}

	$self->_init($name, $postfix, $separator);
	$self->{string} = $value;

	return $self;
}

#
# Defined routines
#

sub string		{ $_[0]->{'string'} }

1;			# for "require"
__END__

=head1 NAME

Log::Agent::Tag::String - a constant tag string

=head1 SYNOPSIS

 require Log::Agent::Tag::String;
 # Inherits from Log::Agent::Tag.

 my $tag = Log::Agent::Tag::String->make(
     -name      => "session id",
     -value     => $session,
     -postfix   => 1,
     -separator => " -- ",
 );

=head1 DESCRIPTION

This class represents a constant tag string.

=head1 CREATION ROUTINE PARAMETERS

The following parameters are defined, in alphabetical order:

=over 4

=item C<-name> => I<name>

The name of this tag.  Currently unused.

=item C<-postfix> => I<flag>

Whether tag should be placed after or before the log message.
By default, it is prepended to the log message, i.e. this parameter is false.

=item C<-separator> => I<string>

The separation string between the tag and the log message.
A single space by default.

=item C<-value> => I<string>

The tag's value.

=back

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent::Tag(3), Log::Agent::Message(3).

=cut
