package KiokuDB::Thunk;
BEGIN {
  $KiokuDB::Thunk::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Thunk::VERSION = '0.57';
use Moose;
# ABSTRACT: Internal only placeholder for deferred objects

use namespace::clean -except => 'meta';

has collapsed => (
    isa => "Ref",
    is  => "ro",
    required => 1,
);

has linker => (
    isa => "KiokuDB::Linker",
    is  => "ro",
);

has attr => (
    isa => "Class::MOP::Attribute",
    is  => "ro",
);

has value => (
    isa => "Ref",
    is  => "ro",
    lazy_build => 1,
);

sub _build_value {
    my $self = shift;

    return $self->linker->expand_object($self->collapsed);
}

sub vivify {
    my ( $self, $instance ) = @_;

    my $value = $self->value;

    my $attr = $self->attr;

    $attr->set_raw_value($instance, $value);

    $attr->_weaken_value($instance)
        if ref $value and $attr->is_weak_ref;

    return $value;
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Thunk - Internal only placeholder for deferred objects

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    # do not use directly,
    # KiokuDB::Meta::Attribute::Lazy, KiokuDB::Meta::Instance and
    # KiokuDB::TypeMap::Entry::MOP will do the actual thunking of data so that
    # the thunk will never be visible unless you break encapsulation.

=head1 DESCRIPTION

This is an internal placeholder object. It will be used on attributes that you
mark with L<KiokuDB::Meta::Attribute::Lazy> automatically, and should never be
visible to the user because L<KiokuDB::Meta::Instance> will automatically
inflate it before it's even seen by the accessor's code.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
