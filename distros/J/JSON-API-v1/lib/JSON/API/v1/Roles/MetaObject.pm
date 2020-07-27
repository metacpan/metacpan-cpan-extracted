package JSON::API::v1::Roles::MetaObject;
our $VERSION = '0.002';
use Moose::Role;
use namespace::autoclean;

# ABSTRACT: An role that implements the default meta object

has meta_object => (
    is        => 'ro',
    isa       => 'Defined',
    predicate => 'has_meta_object',
    init_arg  => 'meta',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::API::v1::Roles::MetaObject - An role that implements the default meta object

=head1 VERSION

version 0.002

=head1 SYNOPSIS

=head1 DESCRIPTION

This role makes sure that you never have to implement a meta object. Added
because L<Moose> already has a C<meta> function, so we need to rename it a bit.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
