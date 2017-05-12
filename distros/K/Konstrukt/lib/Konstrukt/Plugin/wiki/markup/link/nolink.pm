=head1 NAME

Konstrukt::Plugin::wiki::markup::link::nolink - Plugin to handle !NoLinks

=head1 SYNOPSIS

See L<Konstrukt::Plugin::wiki::markup::linkplugin/SYNOPSIS>.

=head1 DESCRIPTION

This one will catch !NoLink's and remove the exclamation mark.

=head1 EXAMPLE

	!NoLink -> NoLink
	
	!Nocamelcase -> !Nocamelcase
	
=cut

package Konstrukt::Plugin::wiki::markup::link::nolink;

use strict;
use warnings;

use base 'Konstrukt::Plugin::wiki::markup::linkplugin';

=head1 METHODS

=head2 matching_regexps()

See L<Konstrukt::Plugin::wiki::markup::linkplugin/matching_regexps> for a description.

=cut
sub matching_regexps {
	#this one is a bit tricky. it must match "foo !NoLink bar" but must not match "foo!NoLink bar"
	return ('^!(?:[A-Z]+[a-z]+[A-Z]+[A-Za-z]*|\S+://\S+|mailto:\S+|news:\S+|[fF]ile:\S+|[iI]mage:\S+)$', undef);
}
# /matching_regexps

=head2 handle()

See L<Konstrukt::Plugin::wiki::markup::linkplugin/handle> for a description.

B<Parameters>:

=over

=item * $link - The link string.

=back

=cut
sub handle {
	my ($self, $link_string) = @_;
	
	#container to collect the nodes. the type is arbitrary
	my $container = Konstrukt::Parser::Node->new({ type => 'wikinodecontainer' });
	
	#cut leading exclamation mark
	$link_string = substr($link_string, 1);
	
	#create new link node
	$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 1, type => 'plaintext', content => $link_string}));

	return $container;
}
# /handle

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::wiki>

=cut
