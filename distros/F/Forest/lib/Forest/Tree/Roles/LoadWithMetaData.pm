package Forest::Tree::Roles::LoadWithMetaData;
use Moose::Role;

our $VERSION   = '0.10';
our $AUTHORITY = 'cpan:STEVAN';

has 'metadata' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'metadata_key' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { 'uid' },
);

around 'create_new_subtree' => sub {
    my $next = shift;
    my $self = shift;
    my $tree = $self->$next(@_);

    ($tree->does('Forest::Tree::Roles::MetaData'))
        || confess "Your subtrees must do the MetaData role";

    my $key = $self->metadata_key;
    if (my $metadata = $self->metadata->{ $tree->$key() }) {
        $tree->metadata($metadata);
    }

    return $tree;
};

no Moose::Role; 1;

__END__

=pod

=head1 NAME

Forest::Tree::Roles::LoadWithMetaData - A Moosey solution to this problem

=head1 SYNOPSIS

  use Forest::Tree::Roles::LoadWithMetaData;

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
