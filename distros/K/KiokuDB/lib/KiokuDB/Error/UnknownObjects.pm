package KiokuDB::Error::UnknownObjects;
BEGIN {
  $KiokuDB::Error::UnknownObjects::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Error::UnknownObjects::VERSION = '0.57';
use Moose;

use namespace::clean -except => "meta"; # autoclean kills overloads

use overload '""' => "as_string";

with qw(KiokuDB::Error);

has objects => (
    isa => "ArrayRef[Ref]",
    reader => "_objects",
    required => 1,
);

sub objects { @{ shift->_objects } }

sub as_string {
    my $self = shift;

    local $, = ", ";
    return "Unregistered objects cannot be updated in database: @{ $self->_objects }"; # FIXME Devel::PartialDump?
}

__PACKAGE__->meta->make_immutable;

# ex: set sw=4 et:

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Error::UnknownObjects

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
