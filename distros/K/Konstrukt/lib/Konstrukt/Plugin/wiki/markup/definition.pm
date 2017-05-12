#TODO: use templates instead of printing HTML?

=head1 NAME

Konstrukt::Plugin::wiki::markup::definition - Block plugin to handle definition lists

=head1 SYNOPSIS
	
	my $d = use_plugin 'wiki::markup::definition';
	my $rv = $d->process($block);

=head1 DESCRIPTION

This one will match if the first line of the block start with a semicolon ";"
followed by at least one whitespace or tab.

Multiple definition terms (indicated by a ";" at the beginning of the line)
per list and multiple definitions per term (indicated by a ":" at the beginning
of the line) are possible.

This plugin has some similarities with L<Konstrukt::Plugin::wiki::markup::list>.

=head1 EXAMPLE

	; definition term
	: first definition
	: second definition
	; another definition term
	: first definition
	: second definition

=cut

package Konstrukt::Plugin::wiki::markup::definition;

use strict;
use warnings;

use Konstrukt::Parser::Node;
use base 'Konstrukt::Plugin::wiki::markup::blockplugin';

=head1 METHODS

=head2 process

This method will do the work.

B<Parameters>:

=over

=item * $block - Block node (of type L<Konstrukt::Parser::Node>) containing the
(text-)nodes of this block.

=back

=cut
sub process {
	my ($self, $block) = @_;
	
	if (not $block->{first_child}->{wiki_finished} and $block->{first_child}->{type} eq 'plaintext' and $block->{first_child}->{content} =~ /^;[ \t]+/) {
		#split block into lines
		$self->split_block_into_lines($block);
		
		#container to collect the nodes of the transformed block
		my $container = Konstrukt::Parser::Node->new({ type => 'wikiblockcontainer' });
		
		#open definition list
		$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 1, type => 'plaintext', content => "<dl class=\"wiki\">\n" }));
		
		#look for lines starting with ; or :
		my $line = my $first_line = $block->{first_child};
		while (defined $line) {
			#save next line since $line->{next} might get overwritten
			#when moving this node around in the tree
			my $next_line = $line->{next};
			#check if the first line start with some bullets
			if (not $line->{first_child}->{wiki_finished} and $line->{first_child}->{type} eq 'plaintext' and $line->{first_child}->{content} =~ /^([:;])\s*(.*)$/) {
				my ($type, $text) = ($1 eq ';' ? 't' : 'd', $2);
				#new definition term or definition
				#open dt or dd
				$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 1, type => 'plaintext', content => "<d$type class=\"wiki\">" }));
				#remove the semicolon or colon
				$line->{first_child}->{content} = $text;
				#add line
				$container->add_child($line);
				$line->replace_by_children();
				#close dt or dd
				$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 1, type => 'plaintext', content => "</d$type>\n" }))
			} else {
				#add a space before this line
				$line->{first_child}->{content} = " $line->{first_child}->{content}" if (not $line->{first_child}->{wiki_finished} and $line->{first_child}->{type} eq 'plaintext');
				#add this line to the last definition (term)
				$container->{last_child}->prepend($line);
				$line->replace_by_children();
			}
			$line = $next_line;
		}
		#close definition list
		$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 1, type => 'plaintext', content => "</dl>\n" }));

		#add additional newline for code beauty
		$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 1, type => 'plaintext', content => "\n" }));
		
		#now delete all the children of the block...
		$block->{first_child} = $block->{last_child} = undef; #dirty hack...
		#... and add the list nodes as the new children of the block node
		my $node = $container->{first_child};
		while (defined $node) {
			my $next_node = $node->{next};
			$block->add_child($node);
			$node = $next_node;
		}
		
		return 1;
	} else {
		#doesn't match
		return undef;
	}
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
