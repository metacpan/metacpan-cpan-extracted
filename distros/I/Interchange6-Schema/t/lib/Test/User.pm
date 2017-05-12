package Test::User;

use Test::Exception;
use Test::MockTime qw( :all );
use Test::More;
use Try::Tiny;
use Test::Roo::Role;
use DateTime;

test 'simple user tests' => sub {

    my $self = shift;

    # make sure there is no mess and stash user fixture count
    $self->clear_users;
    my $user_count = $self->users->count;

    my $schema = $self->ic6s_schema;

    my $rset_user = $schema->resultset('User');

    my ( $data, $result, $roles );

    throws_ok(
        sub { $rset_user->create( {} ) },
        qr/username cannot be unde/,
        "fail User create with empty hashref"
    );

    throws_ok(
        sub { $result = $rset_user->create( { username => undef } ) },
        qr/username cannot be unde/,
        "fail User create with undef username"
    );

    lives_ok(
        sub {
            $result =
              $rset_user->create(
                { username => "AnonymousUsername", is_anonymous => 1 } );
        },
        "User create with good username and is_anonymous => 1"
    );
    $user_count++;

    lives_ok(
        sub {
            $result =
              $rset_user->create( { username => undef, is_anonymous => 1 } );
        },
        "User create with undef username and is_anonymous => 1"
    );
    $user_count++;

    like( $result->username, qr/^anonymous-\w+/, "anonymous username look OK" );
    ok( !$result->active, "user is not active" );
    lives_ok( sub { $result = $rset_user->find( $result->id ) },
        "re-fetch user" );
    isa_ok(
        $result->password,
        'Authen::Passphrase::RejectAll',
        'RejectAll'
    ) or diag explain $result->password->as_crypt;
    ok(!$result->check_password('*'), "cannot login");

    lives_ok( sub { $roles = $result->roles }, "get roles" );

    cmp_ok( $roles->count, '==', 1, "one roles" );

    cmp_ok( $roles->first->name, 'eq', "anonymous", "role is anonymous" );

    # code coverage
    lives_ok { $result = $rset_user->find( { users_id => $result->id } ) }
    "find user using { users_id => \$id }";
    ok $result, "got the user";

    lives_ok(
        sub {
            $result =
              $rset_user->search( { users_id => $result->id }, { rows => 1 } )
              ->hri->single;
        },
        "get hri user"
    );
    cmp_ok( $result->{password}, 'eq', '*',
        "default_value for password is good" );

    lives_ok(
        sub { $result = $rset_user->create( { username => '  MixedCase ' } ) },
        "User create with mixed case username and spaces"
    );
    cmp_ok( $result->username, 'eq', 'mixedcase', "username is 'mixedcase'" );
    lives_ok( sub { $result->delete }, "delete user" );

    throws_ok(
        sub { $rset_user->create( { username => ' ' } ) },
        qr/username cannot be empty string/,
        "fail User create with empty string username"
    );

    lives_ok(
        sub {
            $result =
              $rset_user->create( { username => 'nevairbe@nitesi.de' } );
        },
        "create user"
    );
    cmp_ok $result->username, 'eq', 'nevairbe@nitesi.de', "username is correct";

    lives_ok( sub { $roles = $result->roles }, "get roles" );

    cmp_ok( $roles->count, '==', 1, "one roles" );

    cmp_ok( $roles->first->name, 'eq', "user", "role is user" );

    dies_ok { $result->username(undef) } "cannot change username to undef";

    dies_ok { $result->username('') } "cannot change username to empty string";

    lives_ok { $result->username('nevairbe@nitesi.de') } "change username";

    throws_ok(
        sub { $rset_user->create( { username => 'nevairbe@nitesi.de' } ) },
        qr/DBI Exception/i,
        "fail to create duplicate username"
    );

    lives_ok(
        sub { $result->update( { username => '  MixedCase ' } ) },
        "change username to mixed case"
    );
    cmp_ok( $result->username, 'eq', 'mixedcase', "username is 'mixedcase'" );
    lives_ok( sub { $result->delete }, "delete user" );

    cmp_ok( $rset_user->count, '==', $user_count, "user count is $user_count" );
    my $role_count = $schema->resultset('Role')->count;

    $data = {
        username => 'nevairbe@nitesi.de',
        email    => 'nevairbe@nitesi.de',
        password => 'nevairbe',
    };

    lives_ok( sub { $result = $rset_user->create($data) }, "create user" );

    isa_ok(
        $result->password,
        "Authen::Passphrase::BlowfishCrypt",
        "password class"
    );
    is( $result->password->cost, 14, "password rounds is 2^14" );
    like( $result->password->as_crypt, qr/^\$2a\$14\$.{53}$/,
        "password hash has correct format" );
    ok( $result->check_password('nevairbe'), "check_password" );

    cmp_ok( $result->user_roles->count, '==', 1, "user has 1 user_roles" );
    cmp_ok( $result->roles->first->name, 'eq', 'user', "role is 'user'" );
    cmp_ok( $rset_user->count, '==', ++$user_count,
        "we have $user_count users" );
    cmp_ok( $schema->resultset('UserRole')->count,
        '==', $user_count, "$user_count user role" );
    cmp_ok( $schema->resultset('Role')->count,
        '==', $role_count, "$role_count roles" );

    lives_ok( sub { $result->delete }, "delete user" );

    cmp_ok( $rset_user->count, '==', --$user_count,
        "we have $user_count users" );
    cmp_ok( $schema->resultset('UserRole')->count,
        '==', $user_count, "$user_count user role" );
    cmp_ok( $schema->resultset('Role')->count,
        '==', $role_count, "$role_count roles" );

    $data = {
        username => 'user@example.com',
        email    => 'user@example.com',
    };

    lives_ok( sub { $result = $rset_user->create($data) },
        "create user with no password" );
    isa_ok($result, "Interchange6::Schema::Result::User", "User obj");

    # refetch user from DB so that default_value of password is set since
    # otherwise check_password tests below will pass because password is
    # undef and *not* because ''/undef are passed to check_password
    $result = $rset_user->find( $result->id );

    ok(!$result->check_password(''), "cannot login with empty password");
    ok(!$result->check_password(undef), "cannot login with undef password");

    lives_ok { $result = $self->users->find({ nickname => "Cust1" }) }
    "find user by nickname";

    cmp_ok $result->username, 'eq', 'customer1', 'we found customer1';

    $self->clear_users;
};

test 'user attribute tests' => sub {

    my $self = shift;

    my $count;

    my $user = $self->users->first;

    # add attribute attibute value relationship
    $user->add_attribute( 'hair_color', 'blond' );

    my $hair_color = $user->find_attribute_value('hair_color');

    ok( $hair_color eq 'blond', "Testing AttributeValue." )
      || diag "hair_color: " . $hair_color;

    # change user attribute_value
    $user->update_attribute_value( 'hair_color', 'red' );

    $hair_color = $user->find_attribute_value('hair_color');

    ok( $hair_color eq 'red', "Testing AttributeValue." )
      || diag "hair_color: " . $hair_color;

    # use find_attribute_value object
    $user->add_attribute( 'fb_token', '10A' );
    my $av_object = $user->find_attribute_value( 'fb_token', { object => 1 } );

    my $fb_token = $av_object->value;

    ok( $fb_token eq '10A', "Testing AttributeValue." )
      || diag "fb_token: " . $fb_token;

    # delete user attribute
    $user->delete_attribute( 'hair_color', 'red' );

    my $del = $user->search_related('user_attributes')
      ->search_related('user_attribute_values');

    ok( $del->count eq '1', "Testing user_attribute_values count." )
      || diag "user_attribute_values count: " . $del->count;

    # return all attributes for $user with search_attributes method
    $user->add_attribute( 'favorite_color', 'green' );
    $user->add_attribute( 'first_car',      '64 Mustang' );

    my $attr = $user->search_attributes;

    ok( $attr->count eq '3', "Testing User Attribute count." )
      || diag "User Attribute count: " . $del->count;

    # cleanup
    lives_ok(
        sub { $user->user_attributes->delete_all },
        "delete_all on user->user_attributes"
    );
};

test 'user role tests' => sub {

    my $self   = shift;
    my $schema = $self->ic6s_schema;
    my $rset_user = $schema->resultset('User');

    # use roles fixture
    $self->roles;

    my ( $admin1, $admin2 );
    my $rset_role = $schema->resultset("Role");

    my $role_admin  = $rset_role->find( { name => 'admin' } );
    my $role_user   = $rset_role->find( { name => 'user' } );
    my $role_editor = $rset_role->find( { name => 'editor' } );

    lives_ok( sub { $admin1 = $self->users->find( { username => 'admin1' } ) },
        "grab admin1 user from fixtures" );

    lives_ok(
        sub { $admin1->set_roles( [ $role_admin, $role_user, $role_editor ] ) },
        "Add admin1 to admin, user and editor roles"
    );

    lives_ok( sub { $admin2 = $self->users->find( { username => 'admin2' } ) },
        "grab admin2 user from fixtures" );

    lives_ok( sub { $admin2->set_roles( [ $role_user, $role_editor ] ) },
        "Add admin2 to user and editor roles" );

    # count via m2m
    cmp_ok( $admin1->roles->count, '==', 3, "admin1 has 3 roles" );
    cmp_ok( $admin2->roles->count, '==', 2, "admin2 has 2 roles" );

    # test reverse relationship

    my %users_expected = (
        user   => { count => 2 },
        admin  => { count => 1 },
        editor => { count => 2 },
    );

    foreach my $name ( keys %users_expected ) {
        my $role     = $rset_role->find( { name => $name } );
        my $count    = $role->users->count;
        my $expected = $users_expected{$name}->{count};

        if ( $name eq 'user' ) {
            $expected = $rset_user->count;
        }
        cmp_ok( $count, '==', $expected, "Test user count for role " . $name );
    }

    # cleanup
    $self->clear_roles;
};

test 'check_password, last_login and fail_count' => sub {

    my $self   = shift;
    my $schema = $self->ic6s_schema;

    my ( $user, $token, $dt );

    lives_ok( sub { $user = $self->users->find({username => 'customer1'}) },
        "find customer1" );

    isa_ok($user, "Interchange6::Schema::Result::User", "customer1");

    lives_ok( sub { $user = $self->users->find({username => ' CusTomer1 '}) },
        "find '  CusTomer1 '" );

    isa_ok($user, "Interchange6::Schema::Result::User", '  CusTomer1 ');
    is( $user->username, 'customer1', "Check lc and space removal" );

    ok(!defined $user->last_login, "last_login is undef");
    cmp_ok($user->fail_count, '==', 0, "fail_count is 0");

    ok(!$user->check_password("badpassword"), "try bad password");
    ok(!defined $user->last_login, "last_login is undef");
    cmp_ok($user->fail_count, '==', 1, "fail_count is 1");

    ok(!$user->check_password("badpassword"), "try bad password");
    cmp_ok($user->fail_count, '==', 2, "fail_count is 2");

    ok($user->check_password("c1passwd"), "try good password");
    ok(defined $user->last_login, "last_login is defined");
    my $now = DateTime->now;
    cmp_ok($user->last_login, '<=', $now, "last_login <= now" );
    cmp_ok(
        $user->last_login, '>',
        $now->subtract( minutes => 1 ),
        "last_login > now minus 1 minute"
    );
    cmp_ok($user->fail_count, '==', 0, "fail_count is 0");
};

test 'password reset' => sub {

    my $self   = shift;
    my $schema = $self->ic6s_schema;

    my ( @users, $user, $token, $dt, $result );

    # make sure our test user starts off nice and clean
    lives_ok {
        @users = $self->users->search( undef, { order_by => 'username' } )->all
    }
    "Get an array of all users";

    lives_ok { $user = $users[0] } "get first user from array";
    ok $user, "We have a user";

    lives_ok( sub { $user->reset_expires(undef) },
        "set reset_expires to undef" );

    lives_ok( sub { $user->reset_token(undef) }, "set reset_token to undef" );

    # simple reset token tests

    lives_ok( sub { $token = $user->reset_token_generate }, "get reset token" );

    ok(
        $user->reset_token_verify($token),
        "reset_token_verify on token is true"
    );

    like( $token, qr/^\w{22}_\w{32}$/, "token with checksum looks good" );

    # stash DB reset_token field for later use
    $token =~ m/^(\w+)_/;
    my $db_token = $1;

    cmp_ok( $db_token, 'eq', $user->reset_token,
        "token matches reset_token in db" );

    $dt = DateTime->now->add( hours => 23 );

    cmp_ok( $user->reset_expires, '>', $dt,
        "reset_expires is > 23 hours in the future" );

    $dt->add( hours => 1 );

    cmp_ok( $user->reset_expires, '<=', $dt,
        "reset_expires is <= 24 hours in the future" );

    # test failure after new token is generated

    lives_ok( sub { $user->reset_token_generate }, "get new reset token" );

    ok(
        !$user->reset_token_verify($token),
        "old token with checksum no longer valid"
    );

    lives_ok { $users[1]->update({ reset_token => $db_token }) }
    "give old reset token to some other user";

    ok !$users[1]->reset_token_verify($token),
      "verify token against other user fails";

    my $user2;
    lives_ok { $user2 = $self->users->find_user_with_reset_token($token) }
    "find_user_with_reset_token should not find a user";

    ok !$user2, "yup - no user found";

    # test failure on changed password

    lives_ok( sub { $token = $user->reset_token_generate }, "get reset token" );

    ok(
        $user->reset_token_verify($token),
        "reset_token_verify on token is true"
    );

    lives_ok( sub { $user->password('anewpassword') }, "change user password" );

    ok(
        !$user->reset_token_verify($token),
        "token with checksum no longer valud"
    );

    # 48 hour duration

    lives_ok(
        sub {
            $token = $user->reset_token_generate( duration => { hours => 48 } );
        },
        "get reset token with 48 hour duration"
    );

    like( $token, qr/^\w{22}_\w{32}$/, "token with checksum looks good" );

    ok(
        $user->reset_token_verify($token),
        "reset_token_verify on token is true"
    );

    $dt = DateTime->now->add( hours => 47 );

    cmp_ok( $user->reset_expires, '>', $dt,
        "reset_expires is > 47 hours in the future" );

    $dt->add( hours => 1 );

    cmp_ok( $user->reset_expires, '<=', $dt,
        "reset_expires is <= 48 hours in the future" );

    # undef duration

    lives_ok(
        sub {
            $token = $user->reset_token_generate( duration => undef );
        },
        "get reset token with undef duration"
    );

    like( $token, qr/^\w{22}_\w{32}$/, "token with checksum looks good" );

    ok(
        $user->reset_token_verify($token),
        "reset_token_verify on token is true"
    );

    ok( !$user->reset_expires, "reset_expires is undef" );

    # more entropy

    lives_ok(
        sub {
            $token = $user->reset_token_generate( entropy => 256 );
        },
        "get reset token with 256 bits of entropy"
    );

    like( $token, qr/^\w{43}_\w{32}$/, "token with checksum looks good" );

    ok(
        $user->reset_token_verify($token),
        "reset_token_verify on token is true"
    );

    # bad args to methods

    throws_ok( sub { $user->reset_token_generate( entropy => "QW" ) },
        qr/bad value for entropy/, "bad entropy arg to reset_token_generate");

    throws_ok( sub { $user->reset_token_generate( duration => "QW" ) },
        qr/must be a hashref/, "bad duration arg to reset_token_generate");

    throws_ok( sub { $user->reset_token_verify( "QW" ) },
        qr/Bad argument/, "bad arg reset_token_verify QW");

    throws_ok( sub { $user->reset_token_verify( "QW_" ) },
        qr/Bad argument/, "bad arg reset_token_verify QW_");

    # test that token is no longer valid after expiry time

    lives_ok( sub { set_relative_time(-600) }, "put clock back 10 minutes" );

    lives_ok(
        sub {
            $token =
              $user->reset_token_generate( duration => { minutes => 5 } );
        },
        "get reset token with 5 minute duration"
    );

    ok(
        $user->reset_token_verify($token),
        "reset_token_verify on token is true"
    );

    lives_ok( sub { restore_time() }, "restore time" );

    ok(
        !$user->reset_token_verify($token),
        "reset_token_verify on token is false"
    );

    # find_user_with_reset_token resultset method

    lives_ok( sub { set_relative_time(-600) }, "put clock back 10 minutes" );

    lives_ok { $result = $self->users->find_user_with_reset_token( $token ) }
    "find_user_with_reset_token lives";

    cmp_ok $user->id, '==', $result->id, "correct user returned";

    lives_ok( sub { restore_time() }, "restore time" );

    lives_ok { $result = $self->users->find_user_with_reset_token( $token ) }
    "find_user_with_reset_token lives";

    ok !defined $result, "token has expired" or diag explain $result;

    my $users_id = $user->id;
    my $user_count = $self->users->count;

    lives_ok(
        sub { $token = $user->reset_token_generate },
        "get reset token for " . $user->name
    );

    my $users = $self->users->search( { users_id => { '!=' => $users_id } } );
    while ( my $user = $users->next ) {
        lives_ok(
            sub { $user->reset_token_generate },
            "generate reset token for " . $user->name
        );
    }

    cmp_ok( $self->users->search( { reset_token => { '!=' => undef } } )->count,
        '==', $user_count, "all users now have a reset_token" );

    throws_ok { $user = $self->users->find_user_with_reset_token("q") }
    qr/Bad argument to find_user_with_reset_token/,
      "find_user_with_reset_token with bad arg 'q'";

    throws_ok { $user = $self->users->find_user_with_reset_token("q_") }
    qr/Bad argument to find_user_with_reset_token/,
      "find_user_with_reset_token with bad arg 'q_'";

    throws_ok { $user = $self->users->find_user_with_reset_token("_q") }
    qr/Bad argument to find_user_with_reset_token/,
      "find_user_with_reset_token with bad arg '_q'";

    lives_ok( sub { $user = $self->users->find_user_with_reset_token("q_q") },
        "find_user_with_reset_token with bad token" );

    ok( !$user, "no user found" );

    lives_ok( sub { $user = $self->users->find_user_with_reset_token($token) },
        "find_user_with_reset_token with good token" );

    ok( $user, "user found" ) or diag explain $user;

    cmp_ok( $user->users_id, '==', $users_id, "we got the right user" );

    throws_ok( sub { $self->users->find_user_with_reset_token("_") },
        qr/Bad argument to find_user_with_reset_token/,
        "find_user_with_reset_token('_') dies" );

    throws_ok( sub { $self->users->find_user_with_reset_token(undef) },
        qr/Bad argument to find_user_with_reset_token/,
        "find_user_with_reset_token(undef) dies" );

    # cleanup
    $self->clear_users;
};

1;
