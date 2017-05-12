=head1 NAME

Konstrukt::Plugin::sortlines - Sort all lines of plaintext nodes

=head1 SYNOPSIS
	
B<Usage:>

	<& sortlines &>
		some
		<!-- comments -->
		unsorted
		lines
		<!-- will be put -->
		here
		<!-- on top of the list -->
	<& / &>

B<Result:>

	<!-- comments -->
	<!-- will be put -->
	<!-- on top of the list -->
	here
	lines
	some
	unsorted

=head1 DESCRIPTION

This plugin will sort the input lines

=cut

package Konstrukt::Plugin::sortlines;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance

use Konstrukt::Parser::Node;

=head1 METHODS

=head2 prepare

If the input is not dynamic, we can already sort in the prepare step.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub prepare {
	my ($self, $tag) = @_;
	
	unless ($tag->{dynamic}) {
		return $self->process($tag);
	} else {
		#don't do anything
		return undef;
	}
}
#= /prepare

=head2 execute

Sort the input.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute {
	my ($self, $tag) = @_;
	return $self->process($tag);
}
#= /execute

=head2 process

As prepare and execute are almost the same each run will just call this method.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub process {
	my ($self, $tag) = @_;
	
	#collect comment and plaintext nodes
	my @comments;
	my $plaintext = '';
	my $node = $tag->{first_child};
	while (defined $node) {
		if ($node->{type} eq 'plaintext') {
			$plaintext .= $node->{content};
		} elsif ($node->{type} eq 'comment') {
			push @comments, $node;
		}
		$node = $node->{next};
	}
	
	#sort plaintext
	my @lines = split /\r?\n|\r/, $plaintext;
	@lines = sort { $a cmp $b } @lines;
	$plaintext = join "\n", @lines;
	
	#put out nodes
	$self->reset_nodes();
	foreach my $node (@comments) {
		$self->add_node($node);
	}
	$self->add_node($plaintext);
	
	return $self->get_nodes();
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
