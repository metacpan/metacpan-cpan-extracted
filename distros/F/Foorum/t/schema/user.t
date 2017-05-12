#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => 'DBD::SQLite is required for this test';
    $ENV{TEST_FOORUM} = 1;
    plan tests => 16;
}

use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );
use Foorum::SUtils qw/schema/;
use Foorum::XUtils qw/cache/;
use Foorum::TestUtils qw/rollback_db/;
my $schema = schema();
my $cache  = cache();

my $user_res = $schema->resultset('User');

# test get
my $user = $user_res->get( { user_id => 1 } );
isnt( $user, undef, 'get_one OK' );
is( $user->{user_id}, 1, 'get_one user_id OK' );

# test get_multi
my $users = $user_res->get_multi( user_id => [ 1, 2 ] );
is( scalar( keys %$users ), 2, 'get_multi OK' );
is( $users->{2}->{user_id}, 2, 'get_multi users.2.user_id OK' );

# test get_user_settings
my $settings = $user_res->get_user_settings($user);
is( $settings->{show_email_public},
    'N', 'get_user_settings show_email_public OK' );

# test update_user
my $org_email    = $user->{email};
my $org_username = $user->{username};
$user_res->update_user( $user, { email => 'a@a.com' } );

# test get_from_db
$user = $user_res->get_from_db( { user_id => 1 } );
is( $user->{email}, 'a@a.com', 'update_user OK' );

# data recover back
$user_res->update_user( $user, { email => $org_email } );
$user = $user_res->get( { user_id => 1 } );
is( $user->{email}, $org_email, 'update_user 2 OK' );

# test validate_username
my $st = $user_res->validate_username('5char');
is( $st, 'LENGTH', '5char breaks' );
$st = $user_res->validate_username('22charsabcdefghijklmno');
is( $st, 'LENGTH', '22chars breaks' );
$st = $user_res->validate_username('a cdddf');
is( $st, 'HAS_BLANK', 'HAS_BLANK' );
$st = $user_res->validate_username('a$b@defd');
is( $st, 'HAS_SPECAIL_CHAR', 'HAS_SPECAIL_CHAR' );

$schema->resultset('FilterWord')->create(
    {   word => 'faylandlam',
        type => 'username_reserved'
    }
);
$cache->remove('filter_word|type=username_reserved');

$st = $user_res->validate_username('FaylandLam');
is( $st, 'HAS_RESERVED', 'HAS_RESERVED' );
$st = $user_res->validate_username($org_username);
is( $st, 'DBIC_UNIQUE', 'DBIC_UNIQUE' );

# test validate_email
$st
    = $user_res->validate_email(
    '64charsemail@1234567890qwertyuiopasdfghjklzxcvbnm1234567890qwertyuiopasdfghjkl.com'
    );
is( $st, 'LENGTH', '64 chars break' );
$st = $user_res->validate_email(
    'one wouldnt exist@email.com.withunknownregion');
is( $st, 'EMAIL_LOOSE', 'EMAIL_LOOSE' );
$st = $user_res->validate_email($org_email);
is( $st, 'DBIC_UNIQUE', 'DBIC_UNIQUE' );

END {

    # Keep Database the same from original
    rollback_db();
}

1;
