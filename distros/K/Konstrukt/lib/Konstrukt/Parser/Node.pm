=head1 NAME

Konstrukt::Parser::Node - A node in the parse tree

=head1 SYNOPSIS

	#create root node
	my $root_node = Konstrukt::Parser::Node->new({ type => "root" });
	
	#create text node
	my $text_node = Konstrukt::Parser::Node->new({ type => "plaintext", content => "text" });
	
	#create tag node
	my $tag_node = Konstrukt::Parser::Node->new({ type => "tag", handler_type  => "&", tag => { type => "upcase" } });
	
	#create tree
	$root_node->add_child($tag_node);
	$tag_node->add_child($text_node);
	
	#print out the tree
	print $root_node->tree_to_string();

=head1 DESCRIPTION

Class for the nodes of the parse tree.

Each node has a type and a content. The type will usually be "root" for the root
node, "plaintext" for a text node, "comment" for a comment node or "tag" for a
tag node (which usually has some child nodes).

Generally you will create a root node first and then add child nodes (plaintext
or tags).

This class provides some handy methods for the work with the tree and its nodes.

=cut

package Konstrukt::Parser::Node;

use strict;
use warnings;

use Konstrukt::Debug;

=head1 METHODS

=head2 new

Constructor of this class

B<Parameters>:

=over

=item * $hash - Optional: Hashref that contains the initial data

=back

=cut
sub new {
	my ($class, $init) = @_;
	$init = {} unless defined($init);
	return bless $init, $class;
}
#= /new

=head2 add_child

Adds a child to this node behind the last child node

B<Parameters>:

=over

=item * $child - The child node (a Konstrukt::Parser::Node object) to add

=back

=cut
sub add_child {
	my ($self, $child) = @_;
	
	if (Konstrukt::Debug::WARNING and ref($child) ne "Konstrukt::Parser::Node") {
		$Konstrukt::Debug->error_message("Child is no Konstrukt::Parser::Node!");
		return undef;
	}
	
	if (not defined($self->{first_child})) {
		#first child
		$self->{first_child} = $self->{last_child} = $child;
		$child->{prev} = $child->{next} = undef;
	} else {
		#append child
		$child->{prev} = $self->{last_child};
		$child->{next} = undef;
		$self->{last_child} = $self->{last_child}->{next} = $child;
	}
	$child->{parent} = $self;
}
#= /add_child

=head2 delete

Deletes this child from the tree

=cut
sub delete {
	my ($self) = @_;
	
	#update parent
	my $parent = $self->{parent};
	if (defined $parent) {
		$parent->{first_child} = $self->{next} if $parent->{first_child} eq $self;
		$parent->{last_child}  = $self->{prev} if $parent->{last_child}  eq $self;
	}
	
	#remove from linked list
	$self->{next}->{prev} = $self->{prev} if defined($self->{next});
	$self->{prev}->{next} = $self->{next} if defined($self->{prev});
}
#= /delete

=head2 append

Appends a child behind this one

B<Parameters>:

=over

=item * $node - The node to append

=back

=cut
sub append {
	my ($self, $node) = @_;
	
	if (Konstrukt::Debug::WARNING and ref($node) ne "Konstrukt::Parser::Node") {
		$Konstrukt::Debug->error_message("Node is no Konstrukt::Parser::Node!");
		return undef;
	}
	
	#update parent
	$self->{parent}->{last_child} = $node if defined $self->{parent} and $self->{parent}->{last_child} eq $self;
	
	#link nodes
	$node->{parent} = $self->{parent};
	$node->{next} = $self->{next};
	$node->{prev} = $self;
	$self->{next}->{prev} = $node if defined $self->{next};
	$self->{next} = $node;
}
#= /append

=head2 prepend

Prepends a child before this one

B<Parameters>:

=over

=item * $node - The node to prepend

=back

=cut
sub prepend {
	my ($self, $node) = @_;
	
	if (Konstrukt::Debug::WARNING and ref($node) ne "Konstrukt::Parser::Node") {
		$Konstrukt::Debug->error_message("Node is no Konstrukt::Parser::Node!");
		return undef;
	}
	
	#update parent
	$self->{parent}->{first_child} = $node if defined $self->{parent} and $self->{parent}->{first_child} eq $self;
	
	#link nodes
	$node->{parent} = $self->{parent};
	$node->{next} = $self;
	$node->{prev} = $self->{prev};
	$self->{prev}->{next} = $node if defined $self->{prev};
	$self->{prev} = $node;
}
#= /prepend

=head2 replace_by_node

Replaces this node by a specified other node. The new node should not come from
an other position in a tree as the pointers of the new node will be modified to
fit into the position of the replaced node. The replacement node will be torn out
of its old position.

B<Parameters>:

=over

=item * $node - The new node

=back

=cut
sub replace_by_node {
	my ($self, $node) = @_;
	
	#don't do anything if the new node is the old node
	return if $node eq $self;
	
	if (Konstrukt::Debug::WARNING and ref($node) ne "Konstrukt::Parser::Node") {
		$Konstrukt::Debug->error_message("Node is no Konstrukt::Parser::Node!");
		return undef;
	}
	
	#delete the new node from its old position
	$node->delete();
	
	#update the pointers of the new node
	$node->{parent} = $self->{parent};
	$node->{prev} = $self->{prev};
	$node->{next} = $self->{next};
	
	#update the pointers that pointed to the old node to point to the new node
	$self->{parent}->{first_child} = $node if $self->{parent}->{first_child} eq $self;
	$self->{parent}->{last_child}  = $node if $self->{parent}->{last_child}  eq $self;
	$self->{prev}->{next} = $node if defined $self->{prev};
	$self->{next}->{prev} = $node if defined $self->{next};
}
#= /replace_by_node

=head2 replace_by_children

Replaces this node by its children.

=cut
sub replace_by_children {
	my ($self) = @_;
	
	if (defined $self->{first_child}) {
		#this node has children
		#eventually update the parent
		$self->{parent}->{first_child} = $self->{first_child} if defined $self->{parent} and $self->{parent}->{first_child} eq $self;
		$self->{parent}->{last_child}  = $self->{last_child}  if defined $self->{parent} and $self->{parent}->{last_child}  eq $self;
		
		#update the pointers that pointed to the old node to point to the new nodes
		$self->{prev}->{next} = $self->{first_child} if defined $self->{prev};
		$self->{next}->{prev} = $self->{last_child}  if defined $self->{next};
		
		#update the pointers of the child nodes
		$self->{first_child}->{prev} = $self->{prev} if defined $self->{first_child};
		$self->{last_child}->{next}  = $self->{next} if defined $self->{last_child};
		my $node = $self->{first_child};
		while (defined $node) {
			$node->{parent} = $self->{parent};
			$node = $node->{next};
		}
	} else {
		#this node has no children. delete it
		$self->delete();
	}
}
#= /replace_by_children

=head2 move_children

Moves all children of one node to another node. The child nodes will be deleted
from the source node (the node on which the method is called) and added to the
destination node.

B<Parameters>:

=over

=item * $destination - The destination node

=back

=cut
sub move_children {
	my ($self, $dest) = @_;
	
	my $node = $self->{first_child};
	while (defined $node) {
		my $next_node = $node->{next};
		$dest->add_child($node);
		$node = $next_node;
	}
	#remove all children from this node
	$self->{first_child} = $self->{last_child} = undef;
}
#= /move_children 

=head2 children_to_string

Will join all plaintext- and comment child nodes to a string.
All other nodes will be ignored. Will not recurse into deeper levels.

=cut
sub children_to_string {
	my ($self) = @_;
	
	my $result = '';
	my $node = $self->{first_child};
	while (defined $node) {
		if (($node->{type} eq 'plaintext' or $node->{type} eq 'comment') and defined $node->{content}) {
			$result .= $node->{content};
		}
		$node = $node->{next};
	}
	
	return $result;
}
#= /children_to_string

=head2 tree_to_string

Creates a human readable tree string from the specified node. Mainly used for
debugging.

=cut
sub tree_to_string {
	my ($self, $depth) = @_;
	
	$depth ||= 0;
	my $result = '';
	
	#show node information
	if ($self->{type} eq 'root') {
		$result .= "* root\n";
	} elsif ($self->{type} eq 'plaintext' or $self->{type} eq 'comment') {
		$result .= ("  " x $depth) . "* " . $self->{type} . ": " . $self->{content} . "\n";
	} elsif ($self->{type} eq 'dummy') {
		$result .= ("  " x $depth) . "* dummy\n";
	} elsif ($self->{type} eq 'tag') {
		if (exists $self->{content}->{preliminary}) {
			$result .= ("  " x $depth) . "* " . $self->{type} . ": (preliminary) - type: " . (defined($self->{handler_type}) ? $self->{handler_type} : "(no handler type)") . " - executionstage: " . ($self->{content}->{executionstage} || $self->{content}->{tag}->{attributes}->{executionstage} || "(not defined)") . "\n";
			$result .= ("  " x $depth) . "  children inside this tag:\n";
			$result .= $self->{content}->tree_to_string($depth + 1);
		} else {
			$result .= ("  " x $depth) . "* " . $self->{type} . ": (final) - type: " . (defined($self->{handler_type}) ? $self->{handler_type} : "(no handler type)") . " " . ($self->{tag}->{type} || "(none)") . " - dynamic: " . (defined($self->{dynamic}) ? 1 : 0) . " - executionstage: " . (defined($self->{dynamic}) ? $self->{executionstage} || $self->{tag}->{attributes}->{executionstage} || "(not defined)": "(not defined - no dynamic tag)") . "\n";
		}
	}
	
	#show children, if any
	if (($self->{type} eq 'tag' or $self->{type} eq 'root' or $self->{type} eq 'tagcontent') and defined $self->{first_child}) {
		$result .= ("  " x $depth) . "  children below this tag:\n" unless $self->{type} eq 'tagcontent';
		my $node = $self->{first_child};
		while (defined $node) {
			#recurse
			$result .= $node->tree_to_string($depth + 1);
			$node = $node->{next};
		}
	}
	
	return $result;
}
#= /tree_to_string

=head2 Undocumented debug methods

=head3 remove_cross_references

Removes all cross references that fuck up the data dump.

=head3 restore_cross_references

Add some not really neccessary but handy cross references.

=cut
#removes all cross references that fuck up Data::Dump and cloning
sub remove_cross_references {
	my ($self) = @_;
	
	#save deleted references to allow to restore them
	my @deleted = ($self->{parent}, $self->{prev});
	
	#recursively delete the stuff
	delete($self->{parent});
	delete($self->{prev});
	delete($self->{last_child});
	my $node = $self->{first_child};
	while (defined $node) {
		$node->remove_cross_references();
		$node = $node->{next};
	}
	
	return @deleted;
}

#add some not always neccessary but handy cross references
sub restore_cross_references {
	my ($self, $parent, $prev) = @_;
	
	$self->{parent} = $parent;
	$self->{prev} = $prev;
	my $node = $self->{first_child};
	my $last_node = undef;
	while (defined $node) {
		$node->restore_cross_references($self, $last_node);
		$last_node = $node;
		$node = $node->{next};
	}
	$self->{last_child} = $last_node if defined $last_node;
}

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Parser>

=cut
