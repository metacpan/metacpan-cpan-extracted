=head1 NAME

Konstrukt::Plugin::wiki::markup::list - Block plugin to handle ordered and unoderered lists (using templates)

=head1 SYNOPSIS
	
	my $l = use_plugin 'wiki::markup::list';
	my $rv = $l->process($block);

=head1 DESCRIPTION

This one will match if the first character of the first line of the block is a
* (-> unordered list) or # (->ordered list).

The block will then be enclosed by <ul> and </ul> or <ol> and </ol>.
Each line with leading bullets will be added as a list item. Deeper levels in
the list can be achieved by putting more than one bullet in from of the line.

=head1 EXAMPLE

	* this
	** is
	*** an
	** unordered
	* list
	
	# this
	## one
	### will
	## be
	# ordered

=cut

package Konstrukt::Plugin::wiki::markup::list_template;

use strict;
use warnings;

use Konstrukt::Parser::Node;
use base 'Konstrukt::Plugin::wiki::markup::blockplugin';

=head1 METHODS

=head2 install

Installs the templates.

B<Parameters:>

none

=cut
sub install {
	my ($self) = @_;
	return $Konstrukt::Lib->plugin_file_install_helper($self->{template_path});
}
# /install

=head2 process

This method will do the work.

It's logic is a little bit freaky to convert handle improper markup into
valid HTML.

B<Parameters>:

=over

=item * $block - Block node (of type L<Konstrukt::Parser::Node>) containing the
(text-)nodes of this block.

=back

=cut
sub process {
	my ($self, $block) = @_;
	
	if (not $block->{first_child}->{wiki_finished} and $block->{first_child}->{type} eq 'plaintext' and $block->{first_child}->{content} =~ /^([*#]+)\s/) {
		my $type = substr($1, 0, 1);
		
		#initialize indentation level
		my $level = my $start_level = length($1) - 1;
		
		#split block into lines
		$self->split_block_into_lines($block);
		
		#container to collect the nodes of the transformed block. the type is arbitrary
		my $container = Konstrukt::Parser::Node->new({ type => 'wikiblockcontainer' });
		
		#look for lines starting with bullets
		my $line = my $first_line = $block->{first_child};
		while (defined $line) {
			#save next line since $line->{next} might get overwritten
			#when moving this node around in the tree
			my $next_line = $line->{next};
			#check if the first line start with some bullets
			if (not $line->{first_child}->{wiki_finished} and $line->{first_child}->{type} eq 'plaintext' and $line->{first_child}->{content} =~ /^([*#]+)\s*(.*)$/) {
				my ($bullets, $text) = ($1, $2);
				my $new_level = length($bullets);
				$new_level = $start_level + 1 if $new_level < $start_level + 1;
				if ($level < $new_level) {
					#open new lists, if this line is on different indentation level than the last one
					while ($level < $new_level) {
						$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 1, type => 'plaintext', content => "\n" . ($type eq '*' ? "<ul>\n" : "<ol>\n") . "<li>" }));
						$level++;
					}
				} elsif ($level >= $new_level) {
					#close lists
					while ($level > $new_level) {
						$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 1, type => 'plaintext', content => "</li>\n" . ($type eq '*' ? "</ul>\n" : "</ol>\n") }));
						$level--;
					}
					#close old list item and open new one
					$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 1, type => 'plaintext', content => "</li>\n<li>" }));
				}
				#remove the bullets
				$line->{first_child}->{content} = $text;
			} elsif (not $line->{first_child}->{wiki_finished} and $line->{first_child}->{type} eq 'plaintext') {
				#add a space before this line
				$line->{first_child}->{content} = " $line->{first_child}->{content}";
			}
			#add this line
			$container->add_child($line);
			$line->replace_by_children();
			#proceed
			$line = $next_line;
		}
		#close list tags
		while ($level > $start_level) {
			$container->add_child(Konstrukt::Parser::Node->new({ wiki_finished => 1, type => 'plaintext', content => "</li>\n" . ($type eq '*' ? "</ul>\n" : "</ol>\n") }));
			$level--;
		}
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
