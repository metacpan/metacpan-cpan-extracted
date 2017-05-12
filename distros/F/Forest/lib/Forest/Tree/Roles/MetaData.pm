package Forest::Tree::Roles::MetaData;
use Moose::Role;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

has 'metadata' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

sub get_metadata_for {
    my ($self, $key) = @_;

    return $self->metadata->{$key};
}

sub fetch_metadata_for {
    my ($self, $key) = @_;

    my $current = $self;

    do {
        if ($current->does(__PACKAGE__)) {
            my $meta = $current->metadata;
            return $meta->{$key}
                if exists $meta->{$key};
        }
        $current = $current->parent;
    } until $current->is_root;

    if ($current->does(__PACKAGE__)) {
        my $meta = $current->metadata;
        return $meta->{$key}
            if exists $meta->{$key};
    }

    return;
}

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Forest::Tree::Roles::MetaData - A role mixin to support tree node metadata

=head1 DESCRIPTION

This role mixin adds support for each tree node to have arbitrary metadata
stored in a HASHref. The metadata is inherited in the tree as well, so a child
will inherit the parents metadata.

This is really useful, at least for me it is :)

=head1 ATTRIBUTES

=over 4

=item I<metadata>

=back

=head1 METHODS

=over 4

=item B<fetch_metadata_for ($key)>

This will first check locally, if it doesn't fund anything then will climb
back to the root looking.

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
