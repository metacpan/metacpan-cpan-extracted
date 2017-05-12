=head1 NAME

Konstrukt::Plugin::wiki::markup::htmlescape - Inline plugin to escape HTML markup

=head1 SYNOPSIS
	
	my $h = use_plugin 'wiki::markup::htmlescacpe';
	my $rv = $h->process($tag);

=head1 DESCRIPTION

This one will do a simple search and replace for a some critical characters
(i.e. <, >, & and ") and will replace them.

The replacement will only be done on text nodes, that are not wiki_finished.

You might want to put this one as late as possible in the filter chain.

=head1 EXAMPLE

	This <html> will be escaped.
	
	<nowiki><em>This</em> HTML won't be escaped.</nowiki>
	
=cut

package Konstrukt::Plugin::wiki::markup::htmlescape;

use strict;
use warnings;

use base 'Konstrukt::Plugin::wiki::markup::inlineplugin';

=head1 METHODS

=head2 process

This method will do the work.

B<Parameters>:

=over

=item * $nodes - Container node (of type L<Konstrukt::Parser::Node>) containing
all (text-)nodes of this documents.

=back

=cut
sub process {
	my ($self, $nodes) = @_;
	
	#walk through all nodes and apply replacements
	my $node = $nodes->{first_child};
	while (defined $node) {
		if (not $node->{wiki_finished} and $node->{type} eq 'plaintext') {
			$node->{content} = $Konstrukt::Lib->html_escape($node->{content});
		}
		$node = $node->{next};
	}
	
	return 1;
}
# /process

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::wiki>

=cut
