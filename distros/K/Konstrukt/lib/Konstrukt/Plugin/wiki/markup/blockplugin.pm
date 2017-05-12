=head1 NAME

Konstrukt::Plugin::wiki::markup::blockplugin - Base class for wiki block plugins

=head1 SYNOPSIS
	
	use base 'Konstrukt::Plugin::wiki::markup::blockplugin';
	
	#read the docs

=head1 DESCRIPTION

Its main purpose it the documentation of the creation of custom
wiki block plugins.

It also provides a method which will help your plugin splitting a block into
lines.

=cut

package Konstrukt::Plugin::wiki::markup::blockplugin;

use strict;
use warnings;

=head1 METHODS

=head2 new

Constructor of this class. You will most likely inherit this one.

=cut
sub new {
	my ($class) = @_;
	return bless {}, $class;
}
#= /new

=head2 init

Initialization. May be overwriten by your class. Your class should set its
default settings here.

=cut
sub init {
	my ($self) = @_;
	#set default settings
	#$Konstrukt::Settings->set("wiki/foo", 'bar') unless defined $Konstrukt::Settings->get("wiki/foo");
	return 1;
}
#= /init

=head2 install

Installation of your plugin. For example you may want to create template files
for your markup here.

For more information take a look at the documentation at L<Konstrukt::Plugin/install>.

B<Parameters:>

none

=cut
sub install {
	return 1;
}
# /install

=head2 process

This method will do the work of your plugin.

A block node containing several child nodes (maybe of type 'plaintext', maybe not)
will be passed to this method.

Usually you will only work on nodes matching this criteria

	$node->{type} eq 'plaintext' and not $node->{wiki_finished}

as you should leave alone non-plaintext nodes and finally parsed nodes.

If you detect that this block cannot be handled by your plugin, you must return
undef. Otherwise you should modify the block (e.g. add text-nodes before or
behind it, add/remove nodes, replace the nodes by a template node etc.) and return
a true value. The block node will then be replaced by its children.

After your plugin processed the block, its output will be post-processed:
All returned template nodes (if any) will be prepared recursively so that
their plaintext result will be in the tree and plugins later in the chain may
also work on the results (what they couldn't properly if there are tempalte-tag
nodes). The result will also be scanned for <nowiki>-areas again to prevent other
plugins to work on parts of your results (e.g. HTML-tags).

B<Parameters>:

=over

=item * $block - Block node (of type L<Konstrukt::Parser::Node>) containing the
(text-)nodes of this block.

=back

=cut
sub process {
	my ($self, $block) = @_;
	
	return undef;
}
# /process

=head2 split_block_into_lines

Will split a passed block into lines. The child nodes of the block will be
removed. For each line a new child node will be added under the block node.
This node will contain the nodes which belong to one line. Nodes containing
more than one line will be splitted.

This one is very similar to L<Konstrukt::Plugin::wiki/split_into_blocks>.

B<Parameters>:

=over

=item * $block - Reference to the block (and its children) that shall be split into lines.

=back

=cut
sub split_block_into_lines {
	my ($self, $tag) = @_;
	
	#are there any nodes?
	if (defined $tag->{first_child}) {
		#node which holds all lines
		my $container = Konstrukt::Parser::Node->new({ type => 'wikilinecontainer' });
		
		#initial line
		my $current_line = Konstrukt::Parser::Node->new({ type => 'wikiline' });
		$container->add_child($current_line);
		
		my $node = $tag->{first_child};
		while (defined $node) {
			#save next node since $node->{next} might get overwritten
			#when moving this node around in the tree
			my $next_node = $node->{next};
			if (not $node->{wiki_finished} and $node->{type} eq 'plaintext') {
				#split node into lines
				my @tokens = split /(\r?\n|\r)/, $node->{content};
				#add token to the current line or create a new line nodes
				for (my $i = 0; $i < @tokens; $i++) {
					my $token = $tokens[$i];
					if ($token =~ /(\r?\n|\r)/) {
						#start new line if there is still content left
						if ($i < @tokens - 1 or defined $next_node) {
							$current_line = Konstrukt::Parser::Node->new({ type => 'wikiline' });
							$container->add_child($current_line);
						}
					} else {
						#add content to current line
						$current_line->add_child(Konstrukt::Parser::Node->new({ type => 'plaintext', content => $token }));
					}
				}
			} else {
				#just add it without any modifications
				$current_line->add_child($node);
			}
			$node = $next_node;
		}
		
		#now delete all the children of the tag node...
		$tag->{first_child} = $tag->{last_child} = undef; #dirty hack...
		#... and add the line nodes as the new children of the tag node
		$node = $container->{first_child};
		while (defined $node) {
			my $next_node = $node->{next};
			$tag->add_child($node);
			$node = $next_node;
		}
	}
}

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::wiki>

=cut
