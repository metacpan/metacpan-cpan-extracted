package KiokuDB::Test::Fixture::Clear;
BEGIN {
  $KiokuDB::Test::Fixture::Clear::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Test::Fixture::Clear::VERSION = '0.57';
use Moose;

use Test::More;
use Test::Moose;

use KiokuDB::Test::Person;

use namespace::clean -except => 'meta';

use constant required_backend_roles => qw(Clear);

with qw(KiokuDB::Test::Fixture) => { -excludes => [qw/sort required_backend_roles/] };

sub sort { -10 }

sub create {
    my $self = shift;

    return (
        KiokuDB::Test::Person->new( name => "foo" ),
        KiokuDB::Test::Person->new( name => "bar" ),
    );
}

sub verify {
    my $self = shift;


    $self->txn_lives(sub { $self->lookup_ok(@{ $self->populate_ids } ) });

    $self->txn_lives(sub { $self->backend->clear });

    $self->txn_lives(sub { $self->deleted_ok(@{ $self->populate_ids }) });
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Test::Fixture::Clear

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
