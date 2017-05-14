# ABSTRACT: display a Forest::Tree as a gtk tree view
package Forest::Tree::Viewer::Gtk2;
use Gtk2;
use Moose;
has tree=>(is=>'ro');
has column_name=>(is=>'ro',default=>"?");
sub _append_to_tree_store {
    my ($tree,$tree_store,$parent) = @_;
    my $iter = $tree_store->append($parent);
    $tree_store->set($iter,0=>,$tree->node);
    for (@{$tree->children}) {
        _append_to_tree_store($_,$tree_store,$iter);
    }
}
sub tree_store {
    my ($self) = @_;
    my $tree_store = Gtk2::TreeStore->new(qw/Glib::String/);
    _append_to_tree_store($self->tree,$tree_store);
    $tree_store;
}
sub view {
    my ($self) = @_;
    my $tree_view = Gtk2::TreeView->new($self->tree_store);
    $tree_view->append_column (_create_column($self->column_name,0));
    $tree_view;

}
sub _create_column {
    my ($text,$column) = @_;
    my $tree_column = Gtk2::TreeViewColumn->new();
    $tree_column->set_title ($text);
    my $renderer = Gtk2::CellRendererText->new;
    $tree_column->pack_start ($renderer,'FALSE');
    $tree_column->add_attribute($renderer, text => $column);
    $tree_column;
}
1;

=head1 SYNOPSIS

  use Gtk2 -init;

  use Forest::Tree;
  use Forest::Tree::Viewer::Gtk2;

  my $tree = Forest::Tree->new(node=>'root',children=>[
    Forest::Tree->new(node=>'child1'),
    Forest::Tree->new(node=>'child2'),
  ]);

  my $viewer = Forest::Tree::Viewer::Gtk2->new(tree=>$tree);

  # wrap the tree view in a simple gtk2 application
  my $window = Gtk2::Window->new('toplevel');
  $window->add($viewer->view);
  $window->show_all;
  Gtk2->main;

=head1 NAME

Forest::Tree::Viewer::Gtk2 - a simple Gtk2 using tree viewer

=head1 ATTRIBUTES

=over 4

=item B<tree>

The tree we want to display

=back

=head1 METHODS

=over 4

=item B<view>

Return the Gtk2::TreeView for our tree

=item B<tree_store>

Return the Gtk2::TreeStore for our tree

=back

