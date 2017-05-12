=head1 NAME

Konstrukt::Plugin::perlvar - Access to Perl variables

=head1 SYNOPSIS
	
B<Usage:>

	<!-- set value -->
	<& perlvar var="$Foo::Bar" set="baz" / &>
	
	<!-- print out value -->
	<& perlvar var="$Foo::Bar" / &>
	<& perlvar var="undef" &>this default will be used<& / &>

	<!-- unset value -->
	<& perlvar var="$Foo::Bar" unset="1" / &>
	
B<Result:>

	<!-- set value -->
	
	<!-- print out value -->
	baz
	this default will be used
	
	<!-- unset value -->
	
=head1 DESCRIPTION

Plugin to support access to variables.

In fact the statement in the var-attribute is eval'ed. so when using it without set,
the return value of any perl statement will be returned. Use it with care!

=cut

package Konstrukt::Plugin::perlvar;

use strict;
use warnings;

use base 'Konstrukt::SimplePlugin'; #inheritance

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

With only var being passed, the value of the will be put out.

With additionaly set being passed, the according value of the variable will be changed and nothing will be put out.

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
			eval $tag->{tag}->{attributes}->{var}." = '".$tag->{tag}->{attributes}->{set}."';";#TODO: without eval?
			if ($@) {
				$Konstrukt::Debug->error_message("Error @ '" . $Konstrukt::Handler->{filename} . "'! Could not set perl variable $tag->{tag}->{attributes}->{var}") if Konstrukt::Debug::ERROR;
			}
		} elsif (exists $tag->{tag}->{attributes}->{unset} and $tag->{tag}->{attributes}->{unset}) {
			#unset attribute is set. undef the var.
			eval $tag->{tag}->{attributes}->{var} . " = undef";
			if ($@) {
				$Konstrukt::Debug->error_message("Error @ '" . $Konstrukt::Handler->{filename} . "'! Could not unset perl variable $tag->{tag}->{attributes}->{var}") if Konstrukt::Debug::ERROR;
			}
		} else {
			#only var attribute. no set
			#return the value if defined
			if (defined $tag->{tag}->{attributes}->{var}) {
				my $result = eval $tag->{tag}->{attributes}->{var};
				if ($@) {
					$Konstrukt::Debug->error_message("Error @ '" . $Konstrukt::Handler->{filename} . "'! Could not read perl variable $tag->{tag}->{attributes}->{var}") if Konstrukt::Debug::ERROR;
				} else {
					if (defined $result) {
						$self->add_node($result);
					} else {
						#replace by default value
						return $tag;
					}
				}
			} else {
				$Konstrukt::Debug->debug_message("The variable '$tag->{tag}->{attributes}->{var}' is not defined!") if Konstrukt::Debug::INFO;
			}
		}
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
