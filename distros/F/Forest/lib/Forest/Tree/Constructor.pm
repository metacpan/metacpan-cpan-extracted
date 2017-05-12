package Forest::Tree::Constructor;
use Moose::Role;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

requires "tree_class";

sub create_new_subtree {
    my ($self, %options) = @_;
    my $node = $options{node};

    if (blessed($node) && $node->isa('Forest::Tree::Pure')) {
        # when node is an tree object we assume that it's a prototype of a tree
        # node to be filled in

        # remove meaningless keys
        delete $options{node};
        delete $options{children} if exists $options{children} and not @{ $options{children} };

        # nothing left to be done if the option cleanup deleted all keys
        return $node unless keys %options;

        if ( $node->child_count == 0 ) {
            if ( $node->isa("Forest::Tree") ) {
                # mutable trees get modified

                foreach my $key ( keys %options ) {
                    $node->$key( $options{$key} );
                }

                return $node;
            }
            else {
                # pure trees get cloned
                return $node->clone(%options);
            }
        }
        else {
            # i suppose $options{children} could be appended to $node->children
            # if there are any, but that doesn't really make sense IMHO, might
            # as well write your own builder at that point instead of kludging
            # it with the parser callback for the simple text loader or something
            confess("Can't override children from proto node");
        }
    }
    else {
        return $self->tree_class->new(%options);
    }
}


# ex: set sw=4 et

no Moose::Role; 1;

__END__

=head1 NAME

Forest::Tree::Constructor - An abstract role for tree factories

=head1 SYNOPSIS

    with qw(Forest::Tree::Constructor);

    sub tree_class { ... }

    sub foo {
        $self->create_new_subtree( ... )
    }

=head1 DESCRIPTION

This role provides the C<create_new_subtree> method as required by
L<Forest::Tree::Builder> and L<Forest::Tree::Loader>/L<Forest::Tree::Reader>.

See L<Forest::Tree::Builder> for the reccomended usage.

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
