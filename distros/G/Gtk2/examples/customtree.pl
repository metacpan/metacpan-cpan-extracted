#!/usr/bin/perl

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2 '-init';
use HTML::TreeBuilder;


my $NODE_POS  = 0;
my $NODE_DATA = $NODE_POS++;
my $NODE_NAME = $NODE_POS++;


exit main() unless caller;


sub main {
	local $| = 1;
	my ($html) = @ARGV;
	$html = \qq{
<html>
	<body>
		<p>Hello
			<s>world</s>
		</p>
		<a hrf='http://www.gnome.org/'>link</a>
		<b>bold</b>
		<i>italic</i>
	</body>
</html>

	} unless $html;
	my $document = parse_html($html);
	my $model = my::HtmlTreeModel->new($document);

	my $window = Gtk2::Window->new();
	$window->set_size_request(200, 200);

	my $view = create_tree_view();
	$view->set_model($model);
	$window->add(scrollify($view));

	$window->signal_connect(destroy => sub {Gtk2->main_quit(); });

	$window->show_all();
	Gtk2->main();

	return 0;
}


sub create_tree_view {
	my $view = Gtk2::TreeView->new();
	$view->set_fixed_height_mode(TRUE);

	my $cell = Gtk2::CellRendererText->new();
	my $column = Gtk2::TreeViewColumn->new();
	$column->pack_end($cell, TRUE);

	$column->set_title('Element');
	$column->set_resizable(TRUE);
	$column->set_sizing('fixed');
	$column->set_fixed_width(150);
	$column->set_attributes($cell, text => $NODE_NAME);

	$view->append_column($column);

	return $view;
}


sub scrollify {
	my ($widget, $width, $height) = @_;
	$width = -1 unless defined $width;
	$height = -1 unless defined $height;

	my $scroll = Gtk2::ScrolledWindow->new();
	$scroll->set_policy('automatic', 'automatic');
	$scroll->set_shadow_type('in');
	$scroll->set_size_request($width, $height);

	$scroll->add($widget);
	return $scroll;
}


sub parse_html {
	my ($html) = @_;
	if (ref $html) {
		return HTML::TreeBuilder->new_from_content($$html);
	}
	return HTML::TreeBuilder->new_from_file($html);
}


package my::HtmlTreeModel;

##
## Implementation of a TreeModel that wraps a HTML::TreeBuilder tree. This tree
## model shows only the element nodes and hides all content nodes (the text
## inside an element node).
##
## This TreeModel has 2 columns per row: the element's name and the actual node.
## At the moment only the name field is used.
##

use Glib qw(TRUE FALSE);
use Carp;
use Scalar::Util 'refaddr';

use Glib::Object::Subclass 'Glib::Object' =>
	interfaces => [ 'Gtk2::TreeModel' ]
;

sub new {
	my $class = shift;
	my ($node) = @_ or croak "Usage: ${class}->new(node)";

	my $self = $class->SUPER::new();
	$self->{stamp} = sprintf '%d', rand (1<<31);
	$self->{node}  = $node;
	$self->{types} = [ 'Glib::Scalar', 'Glib::String' ];

	return $self;
}

sub GET_FLAGS { [ 'iters-persist' ] }
sub GET_N_COLUMNS { 2 }
sub GET_COLUMN_TYPE {
	my ($self, $index) = @_;
	return $self->{types}[$index];
}


sub GET_ITER {
	my ($self, $path) = @_;

	# We don't need the first level
	my (undef, @pos) = split /:/, $path->to_string;

	my $node = $self->{node};
	foreach my $pos (@pos) {
		# We keep only the element nodes, this tree doesn't show the content nodes
		my @nodes = grep { is_element($_) } $node->content_list;
		$node = $nodes[$pos];
	}

	return $self->new_iter($node);
}


sub GET_PATH {
	my ($self, $iter) = @_;
	my $path = Gtk2::TreePath->new();

	my $node = $self->get_node($iter) or return undef;
	my @indexes;
	for (; $node; $node = $node->parent) {
		my $index = 0;

		# We must use a list context here otherwise we could get a content node and
		# we will not be able to perform a call to <left>.
		foreach my $left ($node->left) {
			# Because we want only the elements to appear in the tree we have to
			# exclude some nodes
			next unless is_element($left);
			++$index;
		}

		push @indexes, $index;
	}

	foreach my $index (reverse @indexes) {
		$path->append_index($index);
	}

	return $path;
}


sub GET_VALUE {
	my ($self, $iter, $column) = @_;
	my $node = $self->get_node($iter) or return "broken iter?";

	if ($column == 0) {
		return $node;
	}
	elsif ($column == 1) {
		return $node->tag;
	}

	return "Which column?";
}


sub ITER_NEXT {
	my ($self, $iter) = @_;

	my $node = $self->get_node($iter) or return undef;

	# We have to get the list of nodes because calling node->right is scalar
	# context can return a content node and then we lose the capability to go to
	# the next node.
	foreach my $next ($node->right) {
		return $self->new_iter($next) if is_element($next);
	}

	return undef;
}


sub ITER_CHILDREN {
	my ($self, $iter) = @_;

	if ($iter) {
		my $node = $self->get_node($iter) or return undef;

		foreach my $child ($node->content_list) {
			return $self->new_iter($child) if is_element($child);
		}

		return undef;
	}


	return $self->new_iter($self->{node});
}


sub ITER_HAS_CHILD {
	my ($self, $iter) = @_;

	my $node = $self->get_node($iter) or return FALSE;

	foreach my $child ($node->content_list) {
		return TRUE if is_element($child);
	}

	return FALSE;
}


sub ITER_N_CHILDREN {
	my ($self, $iter) = @_;

	my $node = $iter ? $self->get_node($iter) : $self->{node};
	return undef unless $node;

	my $count = 0;
	foreach my $child ($node->content_list) {
		# We only want element nodes
		++$count if is_element($child);
	}

	return $count;
}


sub ITER_NTH_CHILD {
	my ($self, $iter, $n) = @_;

	# Special case: if iter == NULL, return number of top-level rows
	my $node = $iter ? $self->get_node($iter) : $self->{node};
	return undef unless $node;

	# Get the nodes in list context because if we are given a content node we will
	# no be able to todo $node->right.
	my @nodes = $node->right;
	for (my $i = 0; $i < $n;) {
		$node = shift @nodes or return undef;
		++$i if is_element($node);
	}

	return $self->new_iter($node);
}


sub ITER_PARENT {
	my ($self, $iter) = @_;
	my $node = $self->get_node($iter) or return undef;
	return $self->new_iter($node->parent);
}


# Returns TRUE if the given node is and element. HTML::Tree has to types of
# nodes: Elements and cotent (text strings).
sub is_element {
	my $ref = ref $_[0];
	return ($ref eq 'HTML::Element' || $ref eq 'HTML::TreeBuilder');
}


# Builds the arrayref that most methods should return.
sub new_iter {
	my ($self, $node) = @_;
	return $node ? [ $self->{stamp}, 0, $node, undef ] : undef;
}


# Returns a node from a given iter. This method complements <new_iter>. If the
# iter has no node then undef is returned instead.
sub get_node {
	my ($self, $iter) = @_;

	return undef if $iter->[0] == 0
		and $iter->[1] == 0
		and ! defined $iter->[2]
		and ! defined $iter->[3]
	;

	my $node = $iter->[2];
	if (! $node) {
		Carp::cluck "Iter has no node: ", iter_dumper($iter);
		return undef;
	}

	return $node;
}


# Used for debugging purposes.
sub iter_dumper {
	my ($iter) = @_;
	return is_element($iter->[2]) ? $iter->[2] . " - " . $iter->[2]->tag : $iter->[2];
}

