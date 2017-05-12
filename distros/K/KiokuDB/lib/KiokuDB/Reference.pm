package KiokuDB::Reference;
BEGIN {
  $KiokuDB::Reference::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Reference::VERSION = '0.57';
use Moose;
# ABSTRACT: A symbolic reference to another KiokuDB::Entry.

use namespace::clean -except => 'meta';

with qw(MooseX::Clone);

has id => (
    isa => "Str",
    is  => "rw",
    required => 1,
);

has is_weak => (
    isa => "Bool",
    is  => "rw",
);

sub STORABLE_freeze {
    my ( $self, $cloning ) = @_;


    join(",", $self->id, !!$self->is_weak); # FIXME broken
}

sub STORABLE_thaw {
    my ( $self, $cloning, $serialized ) = @_;

    my ( $id, $weak ) = ( $serialized =~ /^(.*?),(1?)$/ );

    $self->id($id);
    $self->is_weak(1) if $weak;

    return $self;
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Reference - A symbolic reference to another KiokuDB::Entry.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    my $ref = KiokuDB::Reference->new(
        id => $some_id,
    );

=head1 DESCRIPTION

This object serves as an internal marker to point to entries by UID.

The linker resolves these references by searching the live object set and
loading entries from the backend as necessary.

=head1 ATTRIBUTES

=over 4

=item id

The ID this entry refers to

=item is_weak

This reference is weak.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
