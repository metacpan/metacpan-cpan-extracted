package KiokuDB::Test::Fixture::Overwrite;
BEGIN {
  $KiokuDB::Test::Fixture::Overwrite::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Test::Fixture::Overwrite::VERSION = '0.57';
use Moose;

use Test::More;
use Test::Exception;

use Scalar::Util qw(refaddr);

use KiokuDB::Test::Person;
use KiokuDB::Test::Employee;
use KiokuDB::Test::Company;

{
    package KiokuDB::Test::BLOB;
BEGIN {
  $KiokuDB::Test::BLOB::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Test::BLOB::VERSION = '0.57';
    use Moose;

    with qw(KiokuDB::Role::ID::Content);

    sub kiokudb_object_id {
        my $self = shift;
        $self->data;
    }

    has data => (
        isa => "Str",
        is  => "ro",
        required => 1,
    );
}

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
            name    => "blah",
        ),
        KiokuDB::Test::BLOB->new(
            data => "lalala",
        ),
    );
}

sub populate {
    my $self = shift;

    {
        my $s = $self->new_scope;

        my ( $p, $b ) = $self->create;

        isa_ok( $p, "KiokuDB::Test::Person" );
        isa_ok( $b, "KiokuDB::Test::BLOB" );

        $self->store_ok( person => $p, $b );

        $self->live_objects_are($p, $b);
    }

    $self->no_live_objects;
}

sub verify {
    my $self = shift;

    {
        my $s = $self->new_scope;

        my $p = $self->lookup_ok("person");

        isa_ok( $p, "KiokuDB::Test::Person" );

        is( $p->name, "blah", "name attr" );

        $p->name("new name");

        lives_ok {
            $self->directory->store($p);
        } "update";
    }

    $self->no_live_objects;

    {
        my $s = $self->new_scope;

        my $b = $self->lookup_ok("lalala");

        isa_ok( $b, "KiokuDB::Test::BLOB" );

        is( $b->data, "lalala", "data attr" );

        my $entry = $self->directory->live_objects->object_to_entry($b);

        lives_ok {
            $self->directory->store($b);
        } "update (noop)";

        my $new_entry = $self->directory->live_objects->object_to_entry($b);

        is( refaddr($new_entry), refaddr($entry), "entry refaddr unchanged" );
    }

    $self->no_live_objects;

    dies_ok {
        my $s = $self->new_scope;
        $self->txn_do(sub {
            $self->directory->store( person => KiokuDB::Test::Person->new( name => "duplicate" ) );
        });
    } "can't insert duplicate";

    $self->no_live_objects;

    lives_ok {
        my $s = $self->new_scope;
        $self->txn_do(sub {
            my $id = $self->directory->store( KiokuDB::Test::BLOB->new( data => "lalala" ) );
        });
    } "not an error to insert a duplicate of a content addressed object";

    $self->no_live_objects;

    lives_ok {
        my $s = $self->new_scope;

        my $b = $self->lookup_ok("lalala");

        $self->txn_do(sub {
            my $id = $self->directory->store( KiokuDB::Test::BLOB->new( data => "lalala" ) );
        });
    } "not an error to insert a duplicate of a live content addressed object";

    $self->no_live_objects;
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Test::Fixture::Overwrite

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
