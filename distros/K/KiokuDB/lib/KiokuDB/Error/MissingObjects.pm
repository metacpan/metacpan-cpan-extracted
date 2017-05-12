package KiokuDB::Error::MissingObjects;
BEGIN {
  $KiokuDB::Error::MissingObjects::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Error::MissingObjects::VERSION = '0.57';
use Moose;

use namespace::clean -except => "meta"; # autoclean kills overloads

use overload '""' => "as_string";

with qw(KiokuDB::Error);

has ids => (
    isa => "ArrayRef[Str]",
    reader => "_ids",
    required => 1,
);

sub ids { @{ shift->_ids } }

sub as_string {
    my $self = shift;

    local $, = ", ";
    return "Objects missing in database: @{ $self->_ids }";
}

sub missing_ids_are {
    my ( $self, @ids ) = @_;

    my %ids = map { $_ => 1 } $self->ids;

    foreach my $id ( @ids ) {
        return unless delete $ids{$id};
    }

    return ( keys(%ids) == 0 )
}

__PACKAGE__->meta->make_immutable;

# ex: set sw=4 et:

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Error::MissingObjects

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
