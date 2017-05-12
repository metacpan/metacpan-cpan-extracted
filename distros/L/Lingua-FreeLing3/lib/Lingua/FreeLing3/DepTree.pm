package Lingua::FreeLing3::DepTree;

use warnings;
use strict;
use Try::Tiny;

use Lingua::FreeLing3::Bindings;
use parent -norequire, 'Lingua::FreeLing3::Bindings::dep_tree';

our $VERSION = "0.01";

=encoding UTF-8

=head1 NAME

Lingua::FreeLing3::DepTree - Interface to FreeLing3 DepTree object

=head1 SYNOPSIS

   use Lingua::FreeLing3::DepTree;

   $ptree = $sentence->dep_tree;


=head1 DESCRIPTION

=cut

sub _new_from_binding {
    my ($class, $word) = @_;
    return bless $word => $class #amen
}

=head2 ACCESSORS

=over 4

=item C<num_children>

Returns the number of childs for this tree node.

=cut

# *nth_child = *Lingua::FreeLing3::Bindingsc::TreeNode_nth_child;
# *nth_child_ref = *Lingua::FreeLing3::Bindingsc::TreeNode_nth_child_ref;
# *get_info = *Lingua::FreeLing3::Bindingsc::TreeNode_get_info;
# *append_child = *Lingua::FreeLing3::Bindingsc::TreeNode_append_child;
# *hang_child = *Lingua::FreeLing3::Bindingsc::TreeNode_hang_child;
# *clear = *Lingua::FreeLing3::Bindingsc::TreeNode_clear;
# *empty = *Lingua::FreeLing3::Bindingsc::TreeNode_empty;
# *sibling_begin = *Lingua::FreeLing3::Bindingsc::TreeNode_sibling_begin;
# *sibling_end = *Lingua::FreeLing3::Bindingsc::TreeNode_sibling_end;
# *begin = *Lingua::FreeLing3::Bindingsc::TreeNode_begin;
# *end = *Lingua::FreeLing3::Bindingsc::TreeNode_end;

### getInfo returns ::node

##package Lingua::FreeLing3::ParseTreeNode;

# *get_label = *Lingua::FreeLing3::Bindingsc::node_get_label;
# *get_word = *Lingua::FreeLing3::Bindingsc::node_get_word;
# *set_word = *Lingua::FreeLing3::Bindingsc::node_set_word;
# *set_label = *Lingua::FreeLing3::Bindingsc::node_set_label;
# *is_head = *Lingua::FreeLing3::Bindingsc::node_is_head;
# *set_head = *Lingua::FreeLing3::Bindingsc::node_set_head;
# *is_chunk = *Lingua::FreeLing3::Bindingsc::node_is_chunk;
# *set_chunk = *Lingua::FreeLing3::Bindingsc::node_set_chunk;
# *get_chunk_ord = *Lingua::FreeLing3::Bindingsc::node_get_chunk_ord;



=pod

=back

=head2 METHODS

=over 4

=item C<nth_child>

Returns the nth child.

=cut

sub nth_child {
    my ($self, $n) = @_;
    return Lingua::FreeLing3::DepTree->_new_from_binding($self->SUPER::nth_child_ref($n));
}

=item C<dump>

Dumps the tree in a textual format, useful for debug purposes.

=cut

sub dump {
    my $tree = shift;

    my $indent = sub {
        my $str = shift;
        $str =~ s/^/  /mg;
        return $str;
    };

    my $info = $tree->SUPER::get_info();

    my $label = $info->get_label();
    $label .= " (". $tree->get_info->get_word->get_form. ")";
    $label .= "\n";

    for my $child (0..$tree->num_children - 1) {
        $label .= $indent->($tree->nth_child($child)->dump);
    }

    return $label;
}

=pod

=back

=cut

1;

__END__


=head1 SEE ALSO

Lingua::FreeLing3(3) for the documentation table of contents. The
freeling library for extra information, or perl(1) itself.

=head1 AUTHOR

Alberto Manuel Brandão Simões, E<lt>ambs@cpan.orgE<gt>

Jorge Cunha Mendes E<lt>jorgecunhamendes@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2012 by Projecto Natura

=cut


