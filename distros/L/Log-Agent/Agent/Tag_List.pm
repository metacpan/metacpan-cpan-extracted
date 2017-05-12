###########################################################################
#
#   Tag_List.pm
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
package Log::Agent::Tag_List;

require Tie::Array;				# contains Tie::StdArray
use vars qw(@ISA);
@ISA = qw(Tie::StdArray);

#
# A list of all log message tags recorded, with dedicated methods to
# manipulate them.
#

#
# ->make
#
# Creation routine.
#
sub make {
	my $self = bless [], shift;
	my (@tags) = @_;
	@$self = @tags;
	return $self;
}

#
# _typecheck
#
# Make sure only objects of the proper type are given in the list.
# Croaks when type checking detects an error.
#
sub _typecheck {
	my $self = shift;
	my ($type, $list) = @_;
	my @bad = grep { !ref $_ || !$_->isa($type) } @$list;
	return unless @bad;

	my $first = $bad[0];
	require Carp;
	Carp::croak(sprintf
		"Expected list of $type, got %d bad (first one is $first)",
		scalar(@bad));
}

#
# ->append
#
# Append list of Log::Agent::Tag objects to current list.
#
sub append {
	my $self = shift;
	my (@tags) = @_;
	$self->_typecheck("Log::Agent::Tag", \@tags);
	push @$self, @tags;
}

#
# ->prepend
#
# Prepend list of Log::Agent::Tag objects to current list.
#
sub prepend {
	my $self = shift;
	my (@tags) = @_;
	$self->_typecheck("Log::Agent::Tag", \@tags);
	unshift @$self, @tags;
}

1;	# for require
__END__

=head1 NAME

Log::Agent::Tag_List - user-defined tags to add to every log

=head1 SYNOPSIS

 use Log::Agent qw(logtags);

 my $taglist = logtags();
 $taglist->append(@tags);        # adds @tags at the tail of list
 $taglist->prepend(@tags);       # adds @tags at the head of list

=head1 DESCRIPTION

This class handles the list of user-defined tags, which are added to
each log message.  The initial list is taken from the C<-tags> argument
of the logconfig() routine. See Log::Agent(3).

=head1 INTERFACE

The following interface is available:

=over 4

=item append I<list>

Append I<list> of C<Log::Agent::Tag> objects to the existing list.

=item prepend I<list>

Prepends I<list> of C<Log::Agent::Tag> objects to the existing list.

=back

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent(3), Log::Agent::Tag(3).

=cut
