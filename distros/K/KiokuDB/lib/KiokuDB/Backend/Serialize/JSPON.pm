package KiokuDB::Backend::Serialize::JSPON;
BEGIN {
  $KiokuDB::Backend::Serialize::JSPON::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::Serialize::JSPON::VERSION = '0.57';
use Moose::Role;
# ABSTRACT: JSPON serialization helper

use KiokuDB::Backend::Serialize::JSPON::Expander;
use KiokuDB::Backend::Serialize::JSPON::Collapser;

use namespace::clean -except => 'meta';

with qw(
    KiokuDB::Backend::TypeMap::Default::JSON
    KiokuDB::Backend::Serialize::JSPON::Converter
);

has expander => (
    isa => "KiokuDB::Backend::Serialize::JSPON::Expander",
    is  => "rw",
    lazy_build => 1,
    handles => [qw(expand_jspon)],
);

sub _build_expander {
    my $self = shift;

    KiokuDB::Backend::Serialize::JSPON::Expander->new($self->_jspon_params);
}

has collapser => (
    isa => "KiokuDB::Backend::Serialize::JSPON::Collapser",
    is  => "rw",
    lazy_build => 1,
    handles => [qw(collapse_jspon)],
);

sub _build_collapser {
    my $self = shift;

    KiokuDB::Backend::Serialize::JSPON::Collapser->new($self->_jspon_params);
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::Serialize::JSPON - JSPON serialization helper

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    with qw(KiokuDB::Backend::Serialize::JSPON);

=head1 DESCRIPTION

This serialization role provides JSPON semantics for L<KiokuDB::Entry> and
L<KiokuDB::Reference> objects.

For serialization to JSON strings see L<KiokuDB::Backend::Serialize::JSON>.

=head1 METHODS

=over 4

=item expand_jspon

See L<KiokuDB::Backend::Serialize::JSPON::Expander/expand_jspon>

=item collapse_jspon

See L<KiokuDB::Backend::Serialize::JSPON::Collapser/collapse_jspon>

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
