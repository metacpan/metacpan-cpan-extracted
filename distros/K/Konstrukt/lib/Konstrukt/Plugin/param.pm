=head1 NAME

Konstrukt::Plugin::param - Displays the value of a specified HTTP parameter

=head1 SYNOPSIS
	
B<Usage:>

	<& param key="param_name" &>default value if not defined<& / &>

B<Result:> (when invoked like: /page.html?param_name=foo)

	foo

=head1 DESCRIPTION

Displays the value of a specified HTTP parameter, like
	
	$Konstrukt::CGI->param('param_name');
	
would do in Perl.

=cut

package Konstrukt::Plugin::param;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance

use Konstrukt::Parser::Node;

=head1 METHODS

=head2 prepare

The HTTP parameters are volatile data. We don't want to cache it...

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

Put out the parameters value.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute {
	my ($self, $tag) = @_;

	my $value = $Konstrukt::CGI->param($tag->{tag}->{attributes}->{var});
	if (defined $value) {
		#reset the collected nodes
		$self->reset_nodes();
		$self->add_node($value);
		return $self->get_nodes();
	} else {
		#replace by default value
		return $tag;
	}
}
#= /execute

return 1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin>, L<Konstrukt>

=cut
