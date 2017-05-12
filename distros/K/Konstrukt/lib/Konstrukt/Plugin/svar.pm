=head1 NAME

Konstrukt::Plugin::svar - Access to session values

=head1 SYNOPSIS
	
B<Usage:>

	<!-- set value -->
	<& svar var="var_name" set="value "/ &>
	
	<!-- print out value -->
	<& svar var="var_name" / &>

B<Result:>

	<!-- set value -->
	
	<!-- print out value -->
	value

=head1 DESCRIPTION

Plugin to support access to session values

=cut

package Konstrukt::Plugin::svar;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance

use Konstrukt::Parser::Node;

=head1 METHODS

=head2 prepare

The date is a very volatile data. We don't want to cache it...

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub prepare {
	my ($self, $tag) = @_;
	
	#Don't do anything beside setting the dynamic-flag
	$tag->{dynamic} = 1;
	
	return undef;
}
#= /prepare

=head2 execute

Checks the passed tag for attributes like var="varname" and set="value".

With only 'var' being passed, the according value of the session variable will be put out.

With additionaly 'set' being passed, the according value of the session will be changed and nothing will be put out.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute {
	my ($self, $tag) = @_;

	#reset the collected nodes
	$self->reset_nodes();
	
	if (exists $tag->{tag}->{attributes}->{var} and defined $tag->{tag}->{attributes}->{var}) {
		#var attribute is set
		if (exists $tag->{tag}->{attributes}->{set} and defined $tag->{tag}->{attributes}->{set}) {
			#set attribute is also set
			#set the value and return an empty string
			$Konstrukt::Session->set($tag->{tag}->{attributes}->{var}, $tag->{tag}->{attributes}->{set});
		} else {
			#only var attribute. no set. return the value.
			my $value = $Konstrukt::Session->get($tag->{tag}->{attributes}->{var});
			$self->add_node($value) if defined $value;
		}
	} else {
		$Konstrukt::Debug->debug_message("The session variable '$tag->{tag}->{attributes}->{var}' is not defined!") if Konstrukt::Debug::ERROR;
	}

	return $self->get_nodes();
}
#= /execute

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin>, L<Konstrukt>

=cut
