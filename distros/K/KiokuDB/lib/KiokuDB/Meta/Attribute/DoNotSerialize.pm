package KiokuDB::Meta::Attribute::DoNotSerialize;
BEGIN {
  $KiokuDB::Meta::Attribute::DoNotSerialize::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Meta::Attribute::DoNotSerialize::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: Trait for skipped attributes

use Moose::Util qw(does_role);

use namespace::clean -except => 'meta';

sub Moose::Meta::Attribute::Custom::Trait::KiokuDB::DoNotSerialize::register_implementation { __PACKAGE__ }

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Meta::Attribute::DoNotSerialize - Trait for skipped attributes

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    # in your class:

    package Foo;
    use Moose;

    has bar => (
        traits => [qw(KiokuDB::DoNotSerialize)],
        isa => "Bar",
        is  => "ro",
        lazy_build => 1,
    );

=head1 DESCRIPTION

This L<Moose::Meta::Attribute> trait provides tells L<KiokuDB> to skip an
attribute when serializing.

L<KiokuDB> also recognizes L<MooseX::Meta::Attribute::Trait::DoNotSerialize>,
but if you don't want to install L<MooseX::Storage> you can use this instead.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
