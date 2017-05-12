use strict;
use warnings FATAL => 'all';

package HTML::Tested::Value::Tree;
use base 'HTML::Tested::Value';

sub transform_value { return $_[2]; }

sub _render_from_selection_tree {
	my ($self, $context, $nodes, $sel_tree, $ident) = @_;
	my $res = "$ident<ul>\n";
	for my $n (@$nodes) {
		my $sa = $context->{selection_attribute};
		my $n_sel = $sa ? $sel_tree->{ $n->{ $sa } } : undef;
		my $new_ident = "$ident  ";
		$res .= "$new_ident<li>\n";
		if ($n_sel) {
			$res .= $self->_render_selected_node(
					$context, $n, "$new_ident  ");
			$res .= $self->_render_from_selection_tree(
					$context, $n->{children}, $n_sel, 
					"$ident    ") if $n->{children};
		} else {
			$res .=	$self->_render_collapsed_node(
					$context, $n, "$new_ident  ");
		}
		$res .= "$new_ident</li>\n";
	}
	return $res . "$ident</ul>\n";
}

sub _build_selection_tree {
	my ($self, $nodes, $selections, $sel_attr) = @_;
	my $tree = {};
	for my $n (@$nodes) {
		my $v = $n->{$sel_attr};
		my $nt = {};
		if (my $c = $n->{children}) {
			$nt = $self->_build_selection_tree(
						$c, $selections, $sel_attr);
		}
		next unless (%$nt || $selections->{$v});
		$tree->{$v} = $nt;
	}
	return $tree;
}

sub _get_tree_option {
	my ($self, $caller, $val, $opt) = @_;
	my $res = $val->{$opt};
	return $res if ($res || !$caller);

	$res = $caller->ht_get_widget_option($self->name, $opt);
	$val->{$opt} = $res;
	return $res;
}

sub value_to_string {
	my ($self, $name, $val, $caller) = @_;

	# Copy var aside, we'll modify it in _get_tree_option
	$val = $val ? { %$val } : {};

	my $input = $self->_get_tree_option($caller, $val, 'input_tree');
	my $sel_attr = $self->_get_tree_option($caller, $val
			, 'selection_attribute');

	# Put those into context
	$self->_get_tree_option($caller, $val, 'collapsed_format');
	$self->_get_tree_option($caller, $val, 'selected_format');

	my $tree = $val->{selection_tree};
	$tree = $self->_build_selection_tree($input
			, { map { ($_, 1) } @{ $val->{selections} } }
			, $sel_attr) if (!$tree && $sel_attr);
	return $self->_render_from_selection_tree($val, $input, $tree, '');
}

sub _render_from_format {
	my ($self, $format, $node, $ident) = @_;
	my $res = $ident . $format . "\n";
	while (my ($n, $v) = each %$node) {
		$res =~ s/\%$n\%/$v/g;
	}
	return $res;
}

sub _render_selected_node {
	my ($self, $context, $node, $ident) = @_;
	return $self->_render_from_format($context->{selected_format}
				|| '<span class="selected">%value%</span>'
			, $node, $ident);
}

sub _render_collapsed_node {
	my ($self, $context, $node, $ident) = @_;
	return $self->_render_from_format($context->{collapsed_format}
			|| '<a href="#">%value%</a>', $node, $ident);
}

1;
