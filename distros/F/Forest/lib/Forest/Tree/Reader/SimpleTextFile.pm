package Forest::Tree::Reader::SimpleTextFile;
use Moose;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

use Forest::Tree::Builder::SimpleTextFile;

with qw(Forest::Tree::Reader Forest::Tree::Constructor); # see new_subtree_callback below

# FIXME these are for compat... remove them?

has 'tab_width' => (
    is      => 'rw',
    isa     => 'Int',
    default => 4
);

has 'parser' => (
    is      => 'rw',
    isa     => 'CodeRef',
    lazy    => 1,
    builder => 'build_parser',
);

sub build_parser {
    return sub {
        my ($self, $line) = @_;
        my ($indent, $node) = ($line =~ /^(\s*)(.*)$/);
        my $depth = ((length $indent) / $self->tab_width);
        return ($depth, $node);
    }
}

sub parse_line { $_[0]->parser->(@_) }

# compat endscreate_new_subtree(@_);},

sub read {
    my ($self, $fh) = @_;

    my $builder = Forest::Tree::Builder::SimpleTextFile->new(
        tree_class           => ref( $self->tree ),
        tab_width            => $self->tab_width,
        parser               => $self->parser,
        fh                   => $fh,

        # since it's possible to subclass reader and implement this method, we
        # include Forest::Tree::Constructor into this class as well, and make
        # the builder use that definition (which under normal circumstances
        # will be the same, Forest::Tree::Constructor::create_new_subtree)
        new_subtree_callback => sub {
            my ( $builder, @args ) = @_;
            $self->create_new_subtree(@args);
        },
    );

    $self->tree->add_child($_) for @{ $builder->subtrees };
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

Forest::Tree::Reader::SimpleTextFile - A reader for Forest::Tree heirarchies

=head1 DESCRIPTION

B<This module is deprecated>. You should use L<Forest::Tree::Builder::SimpleTextFile> instead.

This reads simple F<.tree> files, which are basically the tree represented
as a tabbed heirarchy.

=head1 ATTRIBUTES

=over 4

=item I<tab_width>

=back

=head1 METHODS

=over 4

=item B<read ($fh)>

=item B<build_parser>

=item B<create_new_subtree (%options)>

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
