package Forest::Tree::Builder;
use Moose::Role;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

with qw(Forest::Tree::Constructor);

has 'tree' => (
    is         => 'ro',
    writer     => "_tree",
    isa        => 'Forest::Tree::Pure',
    lazy_build => 1,
);

has tree_class => (
    isa => "ClassName",
    is  => "ro",
    reader => "_tree_class",
    default => "Forest::Tree",
);

# horrible horrible kludge to satisfy 'requires' without forcing 'sub
# tree_class {}' in every single class. God i hate roles and attributes
sub tree_class { shift->_tree_class(@_) }

sub _build_tree {
    my $self = shift;

    $self->create_new_subtree(
        children => $self->subtrees,
    );
}

has subtrees => (
    isa => "ArrayRef[Forest::Tree::Pure]",
    is  => "ro",
    lazy_build => 1,
);

requires "_build_subtrees";

# ex: set sw=4 et:

no Moose::Role; 1;

__END__

=head1 NAME

Forest::Tree::Builder - An abstract role for bottom up tree reader

=head1 SYNOPSIS

    package MyBuilder;
    use Moose;

    with qw(Forest::Tree::Builder);

    # implement required builder:

    sub _build_subtrees {
        return [
            $self->create_new_subtree( ... ), # probably a recursive process
        ];
    }


    my $builder = MyBuilder->new(
        tree_class => ...,
        ...
    );

    my $tree = $builder->tree;

=head1 DESCRIPTION

L<Forest::Tree::Builder> replaces L<Forest::Tree::Loader> and
L<Forest::Tree::Reader> with a bottom up construction approach, which is also
suitable for constructing L<Forest::Tree::Pure> derived trees without excessive
cloning.

It provides a declarative API instead of an imperative one, where C<tree> is
lazily constructed on the first use, instead of being constructed immediately
and "filled in" by the C<load> method.

=head1 METHODS

=over 4

=item create_new_subtree

Implemented by L<Forest::Tree::Constructor>

=item _build_tree

Constructs a root node by using the top level C<subtrees> list as the children.

=item _build_subtrees

Build the subtrees.

Abstract method that should return an array ref of L<Forest::Tree::Pure> derived objects.

=back

=head1 SEE ALSO

L<Forest::Tree::Builder::SimpleTextFile>

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Yuval Kogman

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2014 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
