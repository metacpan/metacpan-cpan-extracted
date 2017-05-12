package KiokuDB::TypeMap::Default::Passthrough;
BEGIN {
  $KiokuDB::TypeMap::Default::Passthrough::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::TypeMap::Default::Passthrough::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: A KiokuDB::TypeMap::Default instance suitable for Storable.

use namespace::clean -except => 'meta';

with qw(KiokuDB::TypeMap::Default);

sub _build_datetime_typemap {
    my $self = shift;

    $self->_create_typemap(
        isa_entries => {
            'DateTime' => => {
                type      => 'KiokuDB::TypeMap::Entry::Passthrough',
                intrinsic => 1,
            },
            'DateTime::Duration' => => {
                type      => 'KiokuDB::TypeMap::Entry::Passthrough',
                intrinsic => 1,
            },
        },
    );
}

sub _build_path_class_typemap {
    my $self = shift;

    $self->_create_typemap(
        isa_entries => {
            'Path::Class::Entity' => {
                type      => "KiokuDB::TypeMap::Entry::Passthrough",
                intrinsic => 1,
            },
        },
    );
}

sub _build_uri_typemap {
    my $self = shift;

    $self->_create_typemap(
        isa_entries => {
            'URI' => {
                type      => "KiokuDB::TypeMap::Entry::Passthrough",
                intrinsic => 1,
            },
        },
        entries => {
            'URI::WithBase' => {
                type      => "KiokuDB::TypeMap::Entry::Passthrough",
                intrinsic => 1,
            },
        },
    );
}

sub _build_authen_passphrase_typemap {
    my $self = shift;

    $self->_create_typemap(
        isa_entries => {
            # since Authen::Passphrase dynamically loads subcomponents based on
            # type, passthrough causes issues with the class not being defined
            # at load time unless explicitly loaded by the user.
            # this works around this issue
            #'Authen::Passphrase' => {
            #    type      => "KiokuDB::TypeMap::Entry::Passthrough",
            #    intrinsic => 1,
            #},
            'Authen::Passphrase' => {
                type      => "KiokuDB::TypeMap::Entry::Callback",
                intrinsic => 1,
                collapse  => "as_rfc2307",
                expand    => "from_rfc2307",
            },
        },
    );
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::TypeMap::Default::Passthrough - A KiokuDB::TypeMap::Default instance suitable for Storable.

=head1 VERSION

version 0.57

=head1 DESCRIPTION

This typemap lets most of the default data types be passed through untouched,
so that their own L<Storable> hooks may be invoked.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
