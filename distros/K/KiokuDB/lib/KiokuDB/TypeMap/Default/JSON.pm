package KiokuDB::TypeMap::Default::JSON;
BEGIN {
  $KiokuDB::TypeMap::Default::JSON::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::TypeMap::Default::JSON::VERSION = '0.57';
use Moose;

use namespace::clean -except => 'meta';

extends qw(KiokuDB::TypeMap);

with 'KiokuDB::TypeMap::Default::Canonical' => {
    -excludes => [qw(reftype_entries)],
};

has json_boolean_typemap => (
    traits     => [qw(KiokuDB::TypeMap)],
    does       => "KiokuDB::Role::TypeMap",
    is         => "ro",
    lazy_build => 1,
);

sub reftype_entries {
    my $self = shift;

    return (
        $self->KiokuDB::TypeMap::Default::Canonical::reftype_entries,
        SCALAR => "KiokuDB::TypeMap::Entry::JSON::Scalar",
        REF    => "KiokuDB::TypeMap::Entry::JSON::Scalar",
    );
}

sub _build_json_boolean_typemap {
    my $self = shift;

    $self->_create_typemap(
        isa_entries => {
            'JSON::Boolean' => {
                type      => "KiokuDB::TypeMap::Entry::Passthrough",
                intrinsic => 1,
            },
            'JSON::PP::Boolean' => {
                type      => "KiokuDB::TypeMap::Entry::Passthrough",
                intrinsic => 1,
            },
        },
    );
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::TypeMap::Default::JSON

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
