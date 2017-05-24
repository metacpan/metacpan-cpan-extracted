#!perl

use strict;
use warnings;

use Etcd3;
use Test::More;
use Test::Exception;
use Data::Dumper;

my ($host, $port);

if ( $ENV{ETCD_TEST_HOST} and $ENV{ETCD_TEST_PORT}) {
    $host = $ENV{ETCD_TEST_HOST};
    $port = $ENV{ETCD_TEST_PORT};

    plan tests => 16;
}
else {
    plan skip_all => "Please set environment variable ETCD_TEST_HOST and ETCD_TEST_PORT.";
}

my $etcd = Etcd3->new( { host => $host, port => $port } );

my ($user, $role);

# add user
lives_ok(
    sub {
        $user =
          $etcd->user( { name => 'samba', password => 'foo' } )->add;
    },
    "add a new user"
);

#print STDERR Dumper($user);

cmp_ok( $user->{response}{success}, '==', 1, "add new user success" );

# add new role
lives_ok( sub { $role = $etcd->role( { name => 'myrole' } )->add;
    },
    "add a new role" );

#print STDERR Dumper($role);

cmp_ok( $role->{response}{success}, '==', 1, "add new role success" );

# role get
lives_ok(
    sub {
        $role =
          $etcd->role( { role => 'myrole' } )->get;
    },
    "get role"
);
cmp_ok( $role->{response}{success}, '==', 1, "get role success" );

#print STDERR Dumper($role);


# grant role
lives_ok(
    sub {
        $role =
          $etcd->user_role( { user => 'samba', role => 'myrole' } )->grant;
    },
    "grant role"
);

#print STDERR Dumper($role);

cmp_ok( $role->{response}{success}, '==', 1, "grant role success" );

# list role
lives_ok(
    sub {
        $role =
          $etcd->role->list;
    },
    "list role"
);

cmp_ok( $role->{response}{success}, '==', 1, "add role to user success" );
#print STDERR Dumper($role);


# revoke role
lives_ok(
    sub {
        $user =
          $etcd->user_role( { name => 'samba', role => 'myrole' } )->revoke;
    },
    "remove role from user"
);

cmp_ok( $user->{response}{success}, '==', 1, "revoke role success" );

#print STDERR Dumper($user);

# delete role
lives_ok( sub { $user = $etcd->role( { role => 'myrole' } )->delete; },
    "delete role" );


cmp_ok( $user->{response}{success}, '==', 1, "role delete success" );


# delete user
lives_ok( sub { $user = $etcd->user( { name => 'samba' } )->delete; },
    "deleted user" );


#print STDERR Dumper($user);

cmp_ok( $user->{response}{success}, '==', 1, "delete user success" );

1;
