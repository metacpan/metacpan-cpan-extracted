#
# This file is part of Jedi-Plugin-Auth
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Plugin::Auth;

# ABSTRACT: Auth for Jedi

use strict;
use warnings;

our $VERSION = '0.01';    # VERSION

use Import::Into;
use Module::Runtime qw/use_module/;

use B::Hooks::EndOfScope;

sub import {
    my $target = caller;
    on_scope_end {
        $target->can('with')->('Jedi::Plugin::Auth::Role');
    };
    return;
}

1;

__END__

=pod

=head1 NAME

Jedi::Plugin::Auth - Auth for Jedi

=head1 VERSION

version 0.01

=head1 DESCRIPTION

Auth for Jedi is a package that handle authentication storage for you.

You can signin, login, logout, signout and get the list of user.

You can also store additional information.

All user have a login and password, and get a unique user id (UUID) at the creation.

You can use that UUID in your database to keep the list of action an user have made.

=head1 SYNOPSIS

  package MyApps;
  use Data::UUID;
  use Jedi::Apps;
  use Jedi::Plugin::Template;
  use Jedi::Plugin::Session; #mandatory for the Auth
  use Jedi::Plugin::Auth;

  sub jedi_apps {
    my ($app) = @_;

    $app->get('/login', $app->can('handle_login'));
    $app->get('/signin', $app->can('handle_signin'));
    $app->get('/activate', $app->can('handle_activate'));

  }

  sub handle_login {
    my ($app, $request, $response) = @_;
  
    my ($login, $password) = map { $request->params->{$_} } qw/user password/;

    my $user = $app->jedi_auth_login($request, user => $user, password => $password);

    if ($user->{status} eq 'ok') {
      #redirect to index
      $response->status('302');
      $response->set_header('Location' => '/');
      return 0; #stop propagation
    } else {
      $response->status('200');
      $response->body($app->template('index'), {error_msg => 'bad login'});
    }
  }

  sub handle_signin {
    my ($app, $request, $response) = @_;
    my ($login, $password, $email, $roles) = map { $request->params->{$_} } qw/user password email roles/;

    my $user = $app->jedi_auth_signin(
      user => $login,
      password => $password, #auto sha1
      roles => [split /,/, $roles // ''],
      info => {
        email => $email,
        activated => 0,
        activate_token => Data::UUID->new->create_str;
      }
    );

    if ($user->{status} eq 'ok') {
      #please activate your account by mail
    } else {
      #display error
      # $user->{missing} if a field is missing
      # $user->{error_msg} for DB error, you can check 'user is not uniq' or stuff like that
    }

  }

  sub handle_activate {
    my ($app, $request, $response) = @_;
    my ($user, $activate_token) = map { $request->params->{$_} } qw/user token/;

    my $users = $app->jedi_auth_users($user);
    my $user = shift @$users;
    if (!defined $user) {
      # user not found
    } else {
      if ($user->{info}{activate_token} eq $activate_token) {
        # activate
        $app->jedi_auth_update($request, user => $user, info => {activate_token => undef, activated => 0});
        # display ok
      } else {
        # display error
      }
    }

  }

=head1 METHODS

=head2 jedi_auth_signin

Create a new user

 $app->jedi_auth_signin(
    user     => 'admin',
    password => 'admin',
    uuid     => 'XXXXXXXXXXXXXXX' #SHA1 Hex Base64
    roles    => ['admin'],
    info     => {
      activated => 0,
      label     => 'Administrator',
      email     => 'admin@admin.local',
      blog      => 'http://blog.celogeek.com',
      live      => 'geistteufel@live.fr',
      created_at => 1388163353,
      last_login => 1388164353,
    }
 );

Roles are dynamically added. Your apps need to handle the relation between each role.

For example : admin include poweruser, user ...

Return :

  {
    status => 'ok',
    user => 'admin',
    uuid => Data::UUID string,
    info => {
      activated => 0,
      label     => 'Administrator',
      email     => 'admin@admin.local',
      blog      => 'http://blog.celogeek.com',
      live      => 'geistteufel@live.fr',
      created_at => 1388163353,
      last_login => 1388164353,
    },
    roles => ['admin'],
  }

In case of missing fields :

  {
    status => 'ko',
    missing => ['list of missing fields'],
  }

For db errors (duplicate ...) :

  {
    status => 'ko',
    error_msg => "$@",
  }

=head2 jedi_auth_signout

Destroy an user

  $app->jedi_auth_signout('admin')

If you want to destroy the current user, ensure to logout first

  if ($request->session_get->{auth}{user} eq 'admin') {
    $app->jedi_auth_logout($request);
  }
  $app->jedi_auth_signout('admin')

=head2 jedi_auth_login

Login the user

  $app->jedi_auth_login(
    $request,
    user     => 'admin',
    password => 'admin',
  );

Return :

  { status => 'ok', uuid => "uuid string", info => { INFO HASH }, roles => [ ROLES ] }
  
  { status => 'ko' }

The user info will be save in the session of user :

  $request->session_get->{auth} = {
    user => 'admin',
    uuid => Data::UUID string,
    info => {
      activated => 0,
      label     => 'Administrator',
      email     => 'admin@admin.local',
      blog      => 'http://blog.celogeek.com',
      live      => 'geistteufel@live.fr',
      created_at => 1388163353,
      last_login => 1388164353,
    },
    roles => ['admin'],
  }

=head2 jedi_auth_logout

Logout the current login user

  $app->jedi_auth_logout($request)

=head2 jedi_auth_update

Update the user account

  $app->jedi_auth_update(
    $request,
    user => 'admin',
    info => {
      activated => 1,
    }
  )

It will update the 'admin' user, and add/change the info.activated to 1. All the other info will be keep.

To clear an info key :

  $app->jedi_auth_update(
    $request,
    user => 'admin',
    info => {
      blog => undef,
    }
  )

=head2 jedi_auth_users_with_role

Return the list of user with a specific role.

Only the "user" key is returned

  $app->jedi_auth_users_with_role('admin');

  # ["admin"]

=head2 jedi_auth_users_count

Return the number of users in the databases

  $app->jedi_auth_users_count()

  # 1

=head2 jedi_auth_users

Return the list of all users with info :

  $app->jedi_auth_users

Return only the info of the user admin :

  $app->jedi_auth_users('admin')

Return the info of user admin and test :

  $app->jedi_auth_users('admin', 'test')

=head1 CONFIGURATION

By default the plugin will store a SQLite DB file into the dist_dir of the Jedi::Plugin::Auth. It will use the classname of your apps to store
the database only for your app.

You can change the root of the storage for your app like this in the configuration of L<Jedi::Launcher> :

  MyApps:
    auth:
      sqlite:
        path: /var/lib/auth/

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/perl-jedi-plugin-auth/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
