package KiokuDB::TypeMap::Entry::Ref;
BEGIN {
  $KiokuDB::TypeMap::Entry::Ref::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::TypeMap::Entry::Ref::VERSION = '0.57';
use Moose;

no warnings 'recursion';

use namespace::clean -except => 'meta';

with qw(
    KiokuDB::TypeMap::Entry
    KiokuDB::TypeMap::Entry::Std::Compile
    KiokuDB::TypeMap::Entry::Std::ID
);

sub compile_collapse {
    my ( $self, $reftype ) = @_;

    return "visit_ref_fallback";
}

sub compile_expand {
    my ( $self, $reftype ) = @_;

    return "expand_object";
}

sub compile_refresh {
    my ( $self, $class, @args ) = @_;

    return sub {
        my ( $linker, $object, $entry ) = @_;

        my $new = $linker->expand_object($entry);

        require Data::Swap;
        Data::Swap::swap($new, $object); # FIXME remove!

        return $object;
    };
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::TypeMap::Entry::Ref

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
