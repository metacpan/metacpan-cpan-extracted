#FEATURE: distinguish ABBR and ACR

=head1 NAME

Konstrukt::Plugin::wiki::markup::acronym - Inline plugin to handle acronyms

=head1 SYNOPSIS
	
	my $a = use_plugin 'wiki::markup::acronym';
	my $rv = $a->process($tag);

=head1 DESCRIPTION

This one will look for acronyms with an explanation and replace it:

	IP(Internet Protocol) => <span title="Internet Protocol">IP</span>

Actually it will work for every "word" that does not contain spaces and is
followed by some text in parenthesis.

=head1 EXAMPLE

	TCP(Transmission Control Protocol)/IP(Internet Protocol)
	
	Foo-Bar(baz)

=cut

package Konstrukt::Plugin::wiki::markup::acronym;

use strict;
use warnings;

use base 'Konstrukt::Plugin::wiki::markup::inlineplugin';
use Konstrukt::Plugin; #import use_plugin

=head1 METHODS

=head2 install

Installs the templates.

B<Parameters:>

none

=cut
sub install {
	my ($self) = @_;
	return $Konstrukt::Lib->plugin_file_install_helper($Konstrukt::Settings->get("wiki/template_path"));
}
# /install

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
	
	#container to collect the nodes. the type is arbitrary
	my $container = Konstrukt::Parser::Node->new({ type => 'wikinodecontainer' });
	my $template = use_plugin 'template';
	my $template_path = $Konstrukt::Settings->get("wiki/template_path");
	
	#split all nodes into tokens.
	my $node = $nodes->{first_child};
	#we will save the found acronym and its description nodes
	my $acronym;
	my $description;
	while (defined $node) {
		#save next node since $node->{next} might get overwritten
		#when moving this node around in the tree.
		my $next_node = $node->{next};
		if (not $node->{wiki_finished} and $node->{type} eq 'plaintext') {
			my @tokens = split /([^\s\(\)\\\/:;=]{2,}\(|\))/o, $node->{content};
			foreach my $token (@tokens) {
				if (not defined $acronym and $token =~ /^[^\s\(\)\\\/]+\(/) {
					#opening acronym description
					$acronym = substr($token, 0, length($token) - 1);
					$description = '';
				} elsif (defined $acronym and $token eq ")") {
					#closing description. add acronym template
					my $template_node = $template->node("${template_path}markup/acronym.template", { acronym => $acronym, description => $description });
					$container->add_child($template_node);
					$acronym = undef;
					$description = undef;
				} elsif (defined $acronym) {
					#append plaintext to the description
					$description .= $token;
				} else {
					#add as plaintext node
					$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 0, type => 'plaintext', content => $token}));
				}
			}
		} else {
			#ignored node
			$container->add_child($node);
		}
		$node = $next_node;
	}
	
	#check if there is an unclosed acronym left
	$container->add_child($template->node("${template_path}markup/acronym.template", { acronym => $acronym, description => $description })) if defined $acronym;
	
	#move created nodes to the result node
	$nodes->{first_child} = $nodes->{last_child} = undef; #dirty hack...
	$container->move_children($nodes);
	
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

__DATA__

-- 8< -- textfile: markup/acronym.template -- >8 --

<nowiki><span class="wiki_acronym" title="<+$ description $+>(no description)<+$ / $+>"><+$ acronym / $+></span></nowiki>

