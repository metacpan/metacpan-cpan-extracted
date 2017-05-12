package Forest::Tree::Loader::SimpleUIDLoader;
use Moose;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

with 'Forest::Tree::Loader';

has 'row_parser' => (
    is      => 'ro',
    isa     => 'CodeRef',
    default => sub {
        sub {
            my $row = shift;
            $row->{node}, $row->{uid}, $row->{parent_uid}
        }
    },
);

sub load {
    my ($self, $table) = @_;

    my $root       = $self->tree;
    my $row_parser = $self->row_parser;

    my %index;

    foreach my $row (@$table) {
        my ($node, $uid, undef) = $row_parser->($row);
        # NOTE: uids MUST be true values ...
        if ($uid) {
            my $t = $self->create_new_subtree(
                node => $node,
                uid  => $uid,
            );
            $index{ $uid } = $t;
        }
    }

    my @orphans;
    foreach my $row (@$table) {
        my (undef, $uid, $parent_uid) = $row_parser->($row);
        # NOTE: uids MUST be true values ...
        if ($uid) {
            my $tree = $index{ $uid };
            if (my $parent = $index{ $parent_uid }) {
                $parent->add_child($tree);
            }
            else {
                push @orphans => $tree;
            }
        }
    }

    if (@orphans) {
        $root->add_children(@orphans);
    }
    else {
        $root->add_child( $index{ (sort keys %index)[0] } );
    }

    $root;
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Forest::Tree::Loader::SimpleUIDLoader - Loads a Forest::Tree heirarchy using UIDs

=head1 DESCRIPTION

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
