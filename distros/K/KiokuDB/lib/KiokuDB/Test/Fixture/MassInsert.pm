package KiokuDB::Test::Fixture::MassInsert;
BEGIN {
  $KiokuDB::Test::Fixture::MassInsert::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Test::Fixture::MassInsert::VERSION = '0.57';
use Moose;

use Test::More;
use Test::Exception;

use Scalar::Util qw(refaddr);

use KiokuDB::Test::Person;

sub p {
    my @args = @_;
    unshift @args, "name" if @args % 2;
    KiokuDB::Test::Person->new(@args);
}

with qw(KiokuDB::Test::Fixture) => { -excludes => [qw/populate sort/] };

sub sort { 100 }

sub create {
    return map { p("person$_") } (1 .. 1024);
}

sub populate {
    my $self = shift;

    $self->txn_do(sub {
        my $s = $self->new_scope;

        my %people;
        @people{1 .. 1024} = $self->create;
        $self->store_ok(%people);
    });

}

sub verify {
    my $self = shift;

    $self->no_live_objects;

    $self->txn_do(sub {
        my $s = $self->new_scope;
        my $p = $self->lookup_ok(1 .. 1024);
    });

    $self->no_live_objects;
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Test::Fixture::MassInsert

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
