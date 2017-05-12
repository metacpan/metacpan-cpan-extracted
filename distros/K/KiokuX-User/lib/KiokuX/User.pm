#!/usr/bin/perl

package KiokuX::User;
use MooseX::Role::Parameterized;

use namespace::clean -except => 'meta';

our $VERSION = "0.02";

parameter id => (
    isa     => 'HashRef',
    default => sub { +{} },
);

parameter password => (
    isa     => 'HashRef',
    default => sub { +{} },
);

role {
    my ($p) = @_;

    with 'KiokuX::User::ID' => $p->id,
         'KiokuX::User::Password' => $p->password;
};

__PACKAGE__

__END__

=pod

=head1 NAME

KiokuX::User - A generic role for user objects stored in L<KiokuDB>

=head1 SYNOPSIS

    package MyFoo::Schema::User;
    use Moose;

    use KiokuX::User::Util qw(crypt_password);

    with qw(KiokuX::User);

    my $user = MyFoo::Schema::User->new(
        id       => $user_id,
        password => crypt_password($password),
    );

    $user->kiokudb_object_id; # "user:$user_id"

    if ( $user->check_password($read_password) ) {
        warn "Login successful";
    } else {
        warn "Login failed";
    }

=head1 DESCRIPTION

This role provides a fairly trivial set of attributes and methods designed to
ease the storage of objects representing users in a KiokuDB database.

It consumes L<KiokuX::User::ID> which provides the C<id> attribute and related
methods as well as L<KiokuDB::Role::ID> integration, and
L<KiokuX::User::Password> which provides an L<Authen::Passphrase> based
C<password> attribute and a C<check_password> method.

=head1 USE AS A DELEGATE

This role strictly implements a notion of an authenticatable identity, not of a
user.

If you want to support renaming, multiple authentication methods (e.g. a
password and/or an openid), it's best to create identity delegates that consume
this role, and have them point at the actual user object:

    package MyFoo::Schema::Identity;
    use Moose::Role;

    has user => (
        isa => "MyFoo::Schema::User",
        is  => "ro",
        required => 1,
    );

And here's an example username identity:

    package MyFoo::Schema::Identity::Username;
    use Moose;

    with qw(
        MyFoo::Schema::Identity
        KiokuX::User
    );

and then point back to these identities from the user:

    has identities => (
        isa      => "ArrayRef[MyFoo::Schema::Identity]",
        is       => "rw",
        required => 1,
    );

Since the identity is part of the objects' ID uniqueness is enforced in a
portable way (you don't need to use the DBI backend and a custom unique
constraint).

This also allows you to easily add additional authentication schemes, change
them, provide namespacing support and so on without affecting the high level
user object, which represents the actual account holder regardless of the
authentication scheme they used.

=head1 VERSION CONTROL

L<http://github.com/nothingmuch/kiokux-user/>

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

    Copyright (c) 2008, 2009 Yuval Kogman, Infinity Interactive. All
    rights reserved This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=cut

# ex: set sw=4 et:

