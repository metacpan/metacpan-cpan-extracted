package KiokuDB::Test::Fixture::Refresh;
BEGIN {
  $KiokuDB::Test::Fixture::Refresh::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Test::Fixture::Refresh::VERSION = '0.57';
use Moose;

use Test::More;
use Test::Exception;

use KiokuDB::Test::Person;

sub p {
    my @args = @_;
    unshift @args, "name" if @args % 2;
    KiokuDB::Test::Person->new(@args);
}

with qw(KiokuDB::Test::Fixture) => { -excludes => [qw/populate sort/] };

sub sort { -100 }

sub create {
    return (
        KiokuDB::Test::Person->new(
            name => "julie",
            age => 10,
        ),
    );
}

sub populate {
    my $self = shift;

    {
        my $s = $self->new_scope;

        my $obj = $self->create;

        isa_ok( $obj, "KiokuDB::Test::Person" );

        $self->store_ok( refresh_obj => $obj );

        $self->live_objects_are($obj);
    }

    $self->no_live_objects;
}

sub verify {
    my $self = shift;

    $self->txn_lives(sub {
        my $obj = $self->lookup_ok("refresh_obj");

        isa_ok( $obj, "KiokuDB::Test::Person" );

        is( $obj->name, "julie", "name" );

        my $dir = $self->directory;

        isa_ok( my $entry = $dir->live_objects->object_to_entry($obj), "KiokuDB::Entry" );

        my $updated = $entry->clone( prev => $entry );
        $updated->data->{age} = 1841;

        is( $obj->age, 10, "age attr" );

        $dir->backend->insert( $updated );

        is( $obj->age, 10, "age attr not updated even though it was written" );

        lives_ok { $dir->refresh($obj) } "no error in refresh";

        is( $obj->age, 1841, "age updated" );
    });
}
__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Test::Fixture::Refresh

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
