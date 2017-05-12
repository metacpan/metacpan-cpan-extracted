use utf8;

package KiokuDB::Test::Fixture::Unicode;
BEGIN {
  $KiokuDB::Test::Fixture::Unicode::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Test::Fixture::Unicode::VERSION = '0.57';
use Moose;

use Encode;
use Test::More;

use KiokuDB::Test::Person;
use KiokuDB::Test::Employee;
use KiokuDB::Test::Company;

use namespace::clean -except => 'meta';

use constant required_backend_roles => qw(UnicodeSafe);

with qw(KiokuDB::Test::Fixture) => { -excludes => 'required_backend_roles' };

my $unicode = "משה";

sub create {

    return (
        KiokuDB::Test::Person->new(
            name => $unicode,
        ),
    );
}

sub verify {
    my $self = shift;

    $self->txn_lives(sub {
        my $dec = $self->lookup_ok( @{ $self->populate_ids } );

        isa_ok( $dec, "KiokuDB::Test::Person" );

        ok( Encode::is_utf8($dec->name), "preserved is_utf8" );
        is( $dec->name, $unicode, "correct value" );
    });
}
__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Test::Fixture::Unicode

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
