package Markup::TreeNode;
$VERSION = '1.1.6';

####################################################
# This module is protected under the terms of the
# GNU GPL. Please see
# http://www.opensource.org/licenses/gpl-license.php
# for more information.
####################################################

use strict;
use Carp;

require Exporter;

our @ISA = qw(Exporter);
our $empty = '(empty)';

sub new {
	my $invocant = shift();
	my $class = ref($invocant) || $invocant;
	$class = bless {
		element_type	=> 'tag',
		tagname		=> '',
		attr		=> { },
		level		=> 0,
		parent		=> $empty,
		child_num	=> 0,
		children	=> [ ],
		text		=> ''
	}, $class;
	$class->init (@_);
	return $class;
}

sub init {
	my $self = shift();
	my %args = @_;

	foreach (keys %args) {
		# enforce integrity
		if ($_ eq 'parent' && $args{$_} ne $empty) {
			$self->attach_parent($args{$_});
			next;
		}

		# enforce integrity
		if ($_ eq 'children' && scalar(@{$args{$_}})) {
			$self->attach_children($args{$_});
			next;
		}

		if (exists $self->{$_}) {
			$self->{$_} = $args{$_};
		}
		else {
			croak ("unrecognized node option $_");
		}
	}
}

sub attach_parent {
	my ($self, $parent) = @_;

	$self->{'parent'} = $parent;
	# if setting parent, add us to [bottom of] parent children
	my $child_count = scalar(@{$self->{'parent'}->{'children'} || []});
	$self->{'parent'}->{'children'}->[$child_count] = $self;
	$self->{'child_num'} = $child_count;

	return $self;
}

sub attach_child {
	my ($self, $child) = @_;
	my $child_count = scalar(@{ $self->{'children'} });

	$self->{'children'}->[$child_count] = $child;
	# if setting child, add us as parent of child
	$child->{'parent'} = $self;
	$child->{'child_num'} = $child_count;

	return $self;
}

sub attach_child_before {
	my ($self, $child) = @_;
	my $child_count = scalar(@{ $self->{'children'} });

	for (my $i = 0; $i < $child_count; $i++) {
		$self->{'children'}->[($i + 1)] = $self->{'children'}->[$i];
		$self->{'children'}->[($i + 1)]->{'child_num'}++;
	}

	$self->{'children'}->[0] = $child;
	# if setting child, add us as parent of child
	$child->{'parent'} = $self;
	$child->{'child_num'} = 0;

	return $self;
}


sub attach_children {
	my ($self, $childref) = @_;
	my $cnt = 0;

	$self->{'children'} = $childref;
	# if setting children, add us as parent of all children
	foreach (@{ $self->{'children'} }) {
		if (!UNIVERSAL::isa($_, 'Markup::TreeNode')) {
			croak ("$_ is not a recognized child");
		}

		$_->{'parent'} = $self;
		$_->{'child_num'} = $cnt++;
	}

	return $self;
}

sub get_text {
	my $self = shift();

	if ($self->{'element_type'} eq '-->text') { return $self->{'text'}; }

	my $next_node = $self->next_node();

	return (($next_node->{'element_type'} eq '-->text') ? $next_node->{'text'} : undef);
}

sub next_node {
	my $self = shift();

	if (scalar(@{ $self->{'children'} })) {
		return $self->{'children'}->[0];
	}

	my $recurse = sub {
		my ($me, $myself) = @_;
		if ($myself->{'parent'} ne $empty) {
			if ($myself->{'child_num'} < (scalar(@{ $myself->{'parent'}->{'children'} || [] }) - 1)) {
				return ($myself->{'parent'}->{'children'}->[($myself->{'child_num'} + 1)]);
			}

			return ($me->($me, $myself->{'parent'}));
		}

		return undef;
	};

	return ($recurse->($recurse, $self));
}

sub previous_node {
	my $self = shift();

	if ($self->{'parent'} ne $empty) {
		if (($self->{'child_num'} > 0) && (scalar(@{ $self->{'parent'}->{'children'} }) >= 1)) {
			my $ret = $self->{'parent'}->{'children'}->[($self->{'child_num'} - 1)];
			while (scalar(@{$ret->{'children'} || []})) {
				$ret = $ret->{'children'}->[(scalar(@{$ret->{'children'}}) - 1)];
			}
			return ($ret);
		}

		return ($self->{'parent'});
	}

	return undef;
}

sub drop {
	my $self = shift();
	my $parent = $self->{'parent'};

	return ($self) if ($parent eq $empty);

	splice @{ $parent->{'children'} }, $self->{'child_num'}--, 1;

	if ($self->{'child_num'} < (scalar(@{ $parent->{'children'} || [] })) && $self->{'child_num'} > 0) {
		for (my $i = $self->{'child_num'}; $i < scalar(@{ $parent->{'children'} }); $i++) {
			$parent->{'children'}->[$i]->{'child_num'} = $i;
		}
	}

	$self->{'parent'} = $empty;

	return ($self);
}

sub replace {
	my ($self, $node) = @_;

	if (!UNIVERSAL::isa($node, 'Markup::TreeNode')) {
		croak ("Node is not a Markup::TreeNode");
	}

	$self->insert($node, 'after');
	return ($self->drop());
}

sub insert {
	my ($self, $node, $position) = @_;
	$position = 'after' if (!$position);
	my $child_num;

	if (($position ne 'after') && ($position ne 'before')) {
		croak ("Unknown position '$position'");
	}

	if (!UNIVERSAL::isa($node, 'Markup::TreeNode')) {
		croak ("Node is not a Markup::TreeNode");
	}

	$child_num = $self->{'child_num'} + ($position eq 'after'); # yes, I know what that means :)
	$child_num = 0 if ($child_num < 0);

	if ($self->{'parent'} eq $empty) {
		return ($self->attach_child($node));
	}

	for ($self->{'parent'}->{'children'}) {
		my $oglen = scalar(@{ $_ });
		for (my $i = $oglen; $i >= $child_num; $i--) {
			$_->[($i + 1)] = $_->[$i];
			$_->[($i + 1)]->{'child_num'}++;
		}

		splice (@{$_}, ++$oglen);

		$_->[$child_num] = $node;
		$_->[$child_num]->{'parent'} = $self->{'parent'};
		$_->[$child_num]->{'child_num'} = $child_num;
		return ($_->[$child_num]);
	}
}

sub copy_of {
	my $self = shift();
	my ($newbie => %options); # if you don't know you betta' axe somebody!

	foreach (keys %{ $self }) {
		$options{$_} = $self->{$_};
	}

	for ($self->{'children'}) {
		my $a = scalar(@{$_});
		for (my $i = 0; $i < $a; $i++) {
			$options{'children'}->[$i] = $_->[$i]->copy_of();
		}
	}

	return ($self->new(%options));
}

1;

__END__
=head1 NAME

Markup::TreeNode - Class representing a marked-up node (element)

=head1 SYNOPSIS

    use Markup::TreeNode;
    my $new_node = Markup::TreeNode->new(tagname => 'p');

=head1 DESCRIPTION

This module exists pretty much soley for L<Markup::Tree>. I'm sure
you can find plenty of other uses for it, but that's probably the best.
Please let me know if and how you use this outside of it's purpose,
I'm very intrested :).

=head1 PROPERTIES

At object instantiation (initilization) the following properties can be set.
Addtionally, they can be read/written in a standard hash way: print $node->{'text'}.

=over 4

=item element_type

The type of element in question. Valid values follow:

=over 4

=item tag

This is the default value and it represents a standard document element.

=item -->text

TreeNodes of this element type represent textual objects.

=item -->declaration

In the real-world you'll probably have one or none of these.
It is the declaration that the XML or HTML tree has provided.
Look at the C<text> property to see what the declaration was
(intact minus the <! >.

=item -->comment

This is a representation of comments in markup.

=item -->ignore

C<element_types> marked with -->ignore will be overlooked
(but not children of -->ignore (unless they also are -->ignore))
by L<Markup::Tree>'s C<foreach_node> and C<save_as> methods.

=item -->pi

Processing Instruction. The C<tagname> will be either
C<asp-style> or C<php-style> depending on wheter the
tag was started and ended with % or ?.

Because it would disturb the natural flow of things later,
pis are treated differently when they are found within quotes,
as in an attribute. Instead of thier normal tagging, <pi language="style"></pi>
they are instead represented in the following format:
{pi:language=style:the pi information found}.

Example:

	<p>some text</p>
	<?php print "<p>some more text</p>"; ?>

becomes

	<p>
		some text
	</p>
	<pi language = "php-style">
		print "<p>some more text</p>";
	</pi>

whereas

	<p class = "<?=print "classname";?>">some text</p>

becomes

	<p class = "{pi:language=php-style:=print %QUOTE%classname%QUOTE%;}">
		some text
	</p>

Make sense?

=item -->section

Indicates a marked section. The tagname is the
name of the section. In the future you
will be able to use this section to get different
object of a marked-up page. $tree->get_section('navigation')
or something like that. Currently used only by the
C<Markup::Match*> modules.

=back

=item tagname

For tag C<element_type>s this is the name of the element.

For -->pi C<element_type>s this is either
C<asp-style> or C<php-style> depending on wheter the
tag was started and ended with % or ?.

For all other elements it is usually the same as C<element_type>.

=item attr

A reference to an anonymous hash. This represents
the elements attributes in name => value pairs (a hash).

=item level

Internally this setting is never used. L<Markup::Tree> uses
it to represent the depth or indentation level. You may find
other uses for it. Default value is 0.

=item parent

When present, this is the reference to the parent C<Markup::TreeNode>.
If empty the value of this property is '(empty)'.

=item child_num

Internally this is used to represent which child number of our parent we are.
Again, you may find another use for it.

=item children

A reference to an anonymous array of C<Markup::TreeNodes>s.

=item text

The text of the object. Likely -->text or -->declaration will have this set.

=back

=head1 METHODS

=over 4

=item attach_parent (C<Markup::TreeNode>)

The safe way of assigning a parent. Adds the current node to the last of
the new parent's children list.

=item attach_child (C<Markup::TreeNode>)

The safe way of assigning a child. Adds proper parent links and C<child_num>s.

=item attach_child_before (C<Markup::TreeNode>)

The safe way of assigning a child. Adds proper parent links and C<child_num>s.

The difference between this method and the C<attach_child> method is that this
method will add the specified child as the B<first> child of it's children,
rather than the B<last>.

=item attach_children (ARRAYREF)

The safe way of assigning a children to a parent. Adds proper parent links and C<child_num>s.

=item get_text ( )

If the current object is a -->text object it simply returns its text; Otherwise
if the C<next_node> is a text, returns its text. If all fails, undef is returned.

=item next_node ( )

Returns the next C<Markup::TreeNode> in the tree or undef if at the bottom
(or if the algo screwed up).

=item previous_node ( )

Returns the previous C<Markup::TreeNode> in the tree or undef if at the top
(or if the algo screwed up).

=item drop ( )

Drops (deletes) the current node and all of its children. Returns the dropped node.

=item replace (C<Markup::TreeNode>)

Replaces the current node with the specified one. Returns the replaced node.

=item insert (C<Markup::TreeNode>, position)

Arguments:

=over 4

=item C<Markup::TreeNode>

The node you want to insert

=item position

May be one of 'before' or 'after'. The default is 'after'.

=back

This method will insert the specified node either before or after itself, depending on the C<position>.

=item copy_of

Returns a B<copy> of the current node. This means you can safely modify
the returned node without affecting the original node or node tree. All
references to children or are also copies, but refrences to parents are,
in fact, refrences.

=back

=head1 BUGS

Please let me know if you find any bugs.

=head1 SEE ALSO

L<Markup::Tree>

=head1 AUTHOR

BPrudent (Brandon Prudent)

Email: xlacklusterx@hotmail.com
