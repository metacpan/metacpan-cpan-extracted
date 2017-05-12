package KiokuDB::TypeMap::Default;
BEGIN {
  $KiokuDB::TypeMap::Default::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::TypeMap::Default::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: A standard KiokuDB::TypeMap with predefined entries.

use namespace::clean -except => 'meta';

with qw(KiokuDB::TypeMap::Composite);

has intrinsic_sets => (
    isa     => "Bool",
    is      => "ro",
    default => 0,
);

has [qw(
    core_typemap
    tie_typemap
    path_class_typemap
    uri_typemap
    datetime_typemap
    authen_passphrase_typemap
)] => (
    traits     => [qw(KiokuDB::TypeMap)],
    does       => "KiokuDB::Role::TypeMap",
    is         => "ro",
    lazy_build => 1,
);

requires qw(
    _build_path_class_typemap
    _build_uri_typemap
    _build_datetime_typemap
    _build_authen_passphrase_typemap
);

sub _build_core_typemap {
    my $self = shift;

    $self->_create_typemap(
        entries => { $self->reftype_entries },
        isa_entries => {
            'KiokuDB::Set::Base' => {
                type      => "KiokuDB::TypeMap::Entry::Set",
                intrinsic => $self->intrinsic_sets,
            },
        },
    );
}

sub reftype_entries {
    return (
        'ARRAY'  => "KiokuDB::TypeMap::Entry::Ref",
        'HASH'   => "KiokuDB::TypeMap::Entry::Ref",
        'SCALAR' => "KiokuDB::TypeMap::Entry::Ref",
        'REF'    => "KiokuDB::TypeMap::Entry::Ref",
        'GLOB'   => "KiokuDB::TypeMap::Entry::Ref",
        'CODE'   => "KiokuDB::TypeMap::Entry::Closure",
    );
}

sub _build_tie_typemap {
    my $self = shift;

    $self->_create_typemap(
        isa_entries => {
            'Tie::RefHash' => {
                type      => 'KiokuDB::TypeMap::Entry::StorableHook',
                intrinsic => 1,
            },
        },
        entries => {
            'Tie::IxHash' => {
                type      => 'KiokuDB::TypeMap::Entry::Naive',
                intrinsic => 1,
            },
        },
    );
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::TypeMap::Default - A standard KiokuDB::TypeMap with predefined entries.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    # the user typemap implicitly inherits from the default one, which is
    # provided by the backend.

    my $dir = KiokuDB->new(
        backend => $b,
        typemap => $user_typemap,
    );

=head1 DESCRIPTION

The default typemap is actually defined per backend, in
L<KiokuDB::TypeMap::Default::JSON> and L<KiokuDB::TypeMap::Default::Storable>.
The list of classes handled by both is the same, but the typemap entries
themselves are tailored to the specific backend's requirements/capabilities.

The entries have no impact unless you are actually using the listed modules.

The default typemap is created using L<KiokuDB::TypeMap::Composite> and accepts
all the standard options

=head1 SUPPORTED TYPES

The following typemaps provide support for these classes:

=over 4

=item core

L<KiokuDB::Set>

=item tie

L<Tie::RefHash>, L<Tie::IxHash>

=item datetime

L<DateTime>

=item uri_typemap

L<URI>, L<URI::WithBase>

=item path_class

L<Path::Class::Entity>

=item authen_passphrase

L<Authen::Passphrase>

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
