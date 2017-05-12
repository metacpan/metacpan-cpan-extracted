package Forest::Tree::Indexer::SimpleUIDIndexer;
use Moose;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

with 'Forest::Tree::Indexer';

sub build_index {
    my $self  = shift;
    my $root  = $self->get_root;
    my $index = $self->index;

    (!exists $index->{$root->uid})
        || confess "Tree root has already been indexed, you must clear it before re-indexing";

    $index->{$root->uid} = $root;

    $root->traverse(sub {
        my $t = shift;
        (!exists $index->{$t->uid})
            || confess "Duplicate tree id (" . $t->uid . ") found";
        $index->{$t->uid} = $t;
    });

};

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Forest::Tree::Indexer::SimpleUIDIndexer - Indexes a Forest::Tree heiarchy by it's UID

=head1 DESCRIPTION

This creates an index of a Forest::Tree heiarchy using the UID as the key.

=head1 METHODS

=over 4

=item B<build_index>

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
