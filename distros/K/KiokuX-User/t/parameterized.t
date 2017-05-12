use strict;
use warnings;

use Test::More 0.88;
use Test::Moose;

use ok 'KiokuX::User';
use ok 'KiokuX::User::Util' => qw(crypt_password);

{
    package Foo::User;
    use Moose;

    with 'KiokuX::User' => {
        id => {
            id_attribute => 'name',
            user_prefix  => 'login:',
        },
        password => { password_attribute => 'pw' },
    };
}

my $o = Foo::User->new(
    name => "bar",
    pw   => crypt_password("foo"),
);

does_ok( $o, "KiokuX::User" );
does_ok( $o, "KiokuX::User::ID" );
does_ok( $o, "KiokuDB::Role::ID" );
does_ok( $o, "KiokuX::User::Password" );

is $o->name, "bar", "user ID";
is $o->kiokudb_object_id, "login:bar", "object ID";

isa_ok $o->pw, 'Authen::Passphrase';

ok $o->check_password("foo"), "check pasword";

ok !$o->check_password("fo"), "bad password";

ok !$o->check_password(""), "bad password";

ok !$o->check_password("fooo"), "bad password";

is eval { $o->name("lala") }, undef, "can't change ID";

$o->set_password("bar");

ok !$o->check_password("foo"), "password changed";

ok $o->check_password("bar"), "new password";

done_testing;

# ex: set sw=4 et:
