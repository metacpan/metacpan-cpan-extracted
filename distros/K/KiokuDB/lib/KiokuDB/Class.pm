package KiokuDB::Class;
BEGIN {
  $KiokuDB::Class::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Class::VERSION = '0.57';
use Moose::Exporter;
# ABSTRACT: KiokuDB specific metaclass

use Moose::Util::MetaRole;

use KiokuDB::Meta::Instance;
use KiokuDB::Meta::Attribute::Lazy;

use namespace::clean -except => 'meta';

Moose::Exporter->setup_import_methods( also => 'Moose' );

sub init_meta {
    my ( $class, %args ) = @_;

    my $for_class = $args{for_class};

    Moose->init_meta(%args);

    Moose::Util::MetaRole::apply_metaroles(
        for             => $for_class,
        class_metaroles => {
            instance => [qw(KiokuDB::Meta::Instance)],
        },
    );

    return Class::MOP::get_metaclass_by_name($for_class);
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Class - KiokuDB specific metaclass

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    package Foo;
    use KiokuDB::Class; # instead of Moose

    has bar => (
        traits => [qw(KiokuDB::Lazy)],
        ...
    );

=head1 DESCRIPTION

This L<Moose> wrapper provides some metaclass extensions in order to more
tightly integrate your class with L<KiokuDB>.

Currently only L<KiokuDB::Meta::Attribute::Lazy> is set up (by extending
L<Moose::Meta::Instance> with a custom role to support it), but in the future
indexing, identity, and various optimizations will be supported by this.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
