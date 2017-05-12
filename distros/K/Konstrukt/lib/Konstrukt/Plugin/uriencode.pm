=head1 NAME

Konstrukt::Plugin::uriencode - URI-encode the text 

=head1 SYNOPSIS
	
B<Usage:>

	<& uriencode &>Some Text<& / &>
	<& uriencode encode="all" &>Some Text<& / &>

B<Result:>

	Some%20Text
	%53%6F%6D%65%20%54%65%78%74

=head1 DESCRIPTION

This plugin will convert some special characters in the text to produce
a valid URI-value.

If the attribute C<encode="all"> is passed, B<every> character will be encoded.

=cut

package Konstrukt::Plugin::uriencode;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance

=head1 METHODS

=head2 prepare

As the output of this plugin will not vary with each call with the same input,
all work can be done in the prepare step if there is no dynamic content inside
the content of this tag.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub prepare {
	my ($self, $tag) = @_;
	return $self->process($tag, 0);
}
#= /prepare

=head2 execute

Now there can only be static content below this tag.
We can finally modify and return it.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute {
	my ($self, $tag) = @_;
	return $self->process($tag, 1);
}
#= /execute

=head2 process

As prepare and execute are almost the same each run will just call this method.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=item * $execute - Should be a true value, when we're in the execute-run

=back

=cut
sub process {
	my ($self, $tag, $execute) = @_;
	
	#iterate over all child-nodes of this tag
	my $node = $tag->{first_child};
	while (defined $node) {
		if ($node->{type} eq 'plaintext') {
			#convert plaintext nodes only into upper case
			$node->{content} = $Konstrukt::Lib->uri_encode($node->{content}, lc $tag->{tag}->{attributes}->{encode} eq 'all');
		}
		$node = $node->{next};
	}
	
	#note that the tag will be replaced by the nodes returned by this sub
	#unless the sub returns undef. then the tag will remain in the tree with the
	#modified children.
	if ($tag->{dynamic} and not $execute) {
		#leave this tag inside the tree as there was dynamic content, that couldn't be handled
		return undef;
	} else {
		#all children have been processed. replace the tag
		return $tag;
	}
}
#= /process

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin>, L<Konstrukt>

=cut

