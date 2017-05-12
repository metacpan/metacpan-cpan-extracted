package KiokuDB::Set::Transient;
BEGIN {
  $KiokuDB::Set::Transient::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Set::Transient::VERSION = '0.57';
use Moose;
# ABSTRACT: Implementation of in memory sets.

use Carp qw(croak);

use namespace::clean -except => 'meta';

with qw(KiokuDB::Set);

extends qw(KiokuDB::Set::Base);

sub loaded { 1 }

sub includes { shift->_objects->includes(@_) }
sub remove   { shift->_objects->remove(@_) }
sub members  { shift->_objects->members }

sub insert   {
    my ( $self, @objects ) = @_;
    croak "Can't insert non reference into a KiokuDB::Set" if grep { not ref } @objects;
    $self->_objects->insert(@objects)
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Set::Transient - Implementation of in memory sets.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    my $set = KiokuDB::Set::Transient->new(
        set => Set::Object->new( @objects ),
    );

    # or

    use KiokuDB::Util qw(set);

    my $set = set(@objects);

=head1 DESCRIPTION

This class implements sets conforming to the L<KiokuDB::Set> API.

These sets can be constructed by the user for insertion into storage.

See L<KiokuDB::Set> for more details.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
