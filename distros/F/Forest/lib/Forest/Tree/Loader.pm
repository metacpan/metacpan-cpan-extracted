package Forest::Tree::Loader;
use Moose::Role;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

with 'Forest::Tree::Constructor';

has 'tree' => (
    is      => 'ro',
    writer  => "_tree",
    isa     => 'Forest::Tree',
    lazy    => 1,

    # FIXME should really be shift->create_new_subtree() but that breaks
    # compatibility when this method is overridden and shouldn't apply to the
    # root node... anyway, Loader should be deprecated anyway
    default => sub { Forest::Tree->new },
);

# more compatibility, the tree class is determined by the class of the root
# which might not be Forest::Tree in subclasses or with explicit
# ->new( tree => ... )
has tree_class => (
    isa => "ClassName",
    is  => "ro",
    reader => "_tree_class",
    default => sub { ref shift->tree },
);

sub tree_class { shift->_tree_class(@_) }

requires 'load';

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Forest::Tree::Loader - An abstract role for loading trees

=head1 DESCRIPTION

B<This role should generally not be used, it has been largely superseded by Forest::Tree::Builder>.

This is an abstract role to be used for loading trees from

=head1 METHODS

=over 4

=item B<>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2014 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
