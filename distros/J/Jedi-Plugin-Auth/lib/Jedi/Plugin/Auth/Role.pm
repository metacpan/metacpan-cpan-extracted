#
# This file is part of Jedi-Plugin-Auth
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Plugin::Auth::Role;

# ABSTRACT: Imported Role for L<Jedi::Plugin::Auth>

use strict;
use warnings;
our $VERSION = '0.01';    # VERSION

use feature 'state';
use Carp;
use Digest::SHA1 qw/sha1_hex/;
use Data::UUID;
use Path::Class;
use Jedi::Plugin::Auth::DB;
use DBIx::Class::Migration;
use JSON;

my $uuid_generator = Data::UUID->new;

# connect / create / prepare db
sub _prepare_database {
    my ($dbfile)     = @_;
    my @connect_info = ( "dbi:SQLite:dbname=" . $dbfile->stringify );
    my $schema       = Jedi::Plugin::Auth::DB->connect(@connect_info);

    my $migration = DBIx::Class::Migration->new( schema => $schema, );

    $migration->install_if_needed;
    $migration->upgrade;

    return $schema;
}

sub _user_to_hash {
    my ($user) = @_;

    return {
        user  => $user->user,
        uuid  => $user->uuid,
        info  => decode_json( $user->info ),
        roles => [ map { $_->name } $user->roles->all() ],
    };
}

use Moo::Role;

# init the BDB databases
has '_jedi_auth_db' => ( is => 'lazy' );

sub _build__jedi_auth_db {
    my ($self)      = @_;
    my $class       = ref $self;
    my $sqlite_path = $self->jedi_config->{$class}{auth}{sqlite}{path};
    if ( !defined $sqlite_path ) {
        $sqlite_path = dir( File::ShareDir::dist_dir('Jedi-Plugin-Auth') );
    }
    croak
        "SQLite path is missing and cannot be guest. Please setup the configuration file."
        if !defined $sqlite_path;
    my $app_dir = dir( $sqlite_path, split( /::/x, $class ) );
    my $sqlite_db_file = file( $app_dir . '.db' );
    $sqlite_db_file->dir->mkpath;
    return _prepare_database($sqlite_db_file);
}

before jedi_app => sub {
    my ($app) = @_;
    croak "You need to include and configure Jedi::Plugin::Session first."
        if !$app->can('jedi_session_setup');
};

# sign in
sub jedi_auth_signin {
    my ( $self, %params ) = @_;
    delete $params{roles} if ref $params{roles} ne 'ARRAY';
    delete $params{roles} if !@{ $params{roles} };

    my @missing;
    for my $key (qw/user password roles/) {
        push @missing, $key if !defined $params{$key};
    }
    return { status => 'ko', missing => \@missing } if @missing;

    $params{roles} = [] if ref $params{roles} ne 'ARRAY';
    $params{info}  = {} if ref $params{info} ne 'HASH';

    my $user;

    return { status => 'ko', error_msg => "$@" }
        if !eval {
        $user = $self->_jedi_auth_db->resultset('User')->create(
            {   user     => $params{user},
                password => sha1_hex( $params{password} ),
                uuid     => $uuid_generator->create_str(),
                info     => encode_json( $params{info} ),
            }
        );
        1;
        };

    $user->set_roles( [ map { { name => $_ } } @{ $params{roles} } ] );

    return {
        status => 'ok',
        %{ _user_to_hash($user) }
    };
}

# sign out
sub jedi_auth_signout {
    my ( $self, $username ) = @_;
    return { status => 'ko', missing => ['user'] } if !defined $username;
    my $user = $self->_jedi_auth_db->resultset('User')
        ->search( { user => $username } );
    return { status => 'ko', error_msg => 'user not found' } if !$user->count;
    $user->delete_all;
    return { status => 'ok' };
}

# login
sub jedi_auth_login {
    my ( $self, $request, %params ) = @_;
    return { status => 'ko' }
        if !defined $params{user} || !defined $params{password};

    my $user
        = $self->_jedi_auth_db->resultset('User')
        ->search(
        { user => $params{user}, password => sha1_hex( $params{password} ) } )
        ->first;
    return { status => 'ko' } if !defined $user;

    my $session = $request->session_get // {};
    $session->{auth} = _user_to_hash($user);
    $request->session_set($session);

    return {
        status => 'ok',
        %{ $session->{auth} }
    };
}

# logout
sub jedi_auth_logout {
    my ( $self, $request ) = @_;
    my $session = $request->session_get;
    if ( defined $session ) {
        delete $session->{auth};
        $request->session_set($session);
    }
    return { status => 'ok' };
}

# update
sub jedi_auth_update {
    my ( $self, $request, %params ) = @_;

    my ( $username, $password, $info, $roles )
        = @params{qw/user password info roles/};
    return { status => 'ko', missing => ['user'] } if !defined $username;

    my $user = $self->_jedi_auth_db->resultset('User')
        ->find( { user => $username } );
    return { status => 'ko', error_msg => 'user not found' }
        if !defined $user;

    # password
    $user->password( sha1_hex($password) ) if defined $password;

    # info
    if ( ref $info eq 'HASH' ) {
        my $current_info = decode_json( $user->info );
        for my $k ( keys %$info ) {
            my $v = $info->{$k};
            if ( defined $v ) {
                $current_info->{$k} = $v;
            }
            else {
                delete $current_info->{$k};
            }
        }
        $user->info( encode_json($current_info) );
    }

    if ( ref $roles eq 'ARRAY' ) {
        $user->set_roles( [ map { { name => $_ } } @$roles ] );
    }

    $user->update();
    my $user_info = _user_to_hash($user);

    my $session = $request->session_get;
    if (   defined $session
        && exists $session->{auth}
        && $session->{auth}{user} eq $username )
    {
        $session->{auth} = $user_info;
        $request->session_set($session);
    }

    return { status => 'ok', %{$user_info} };

}

# list of user with a specific role
sub jedi_auth_users_with_role {
    my ( $self, $rolename ) = @_;
    return [] if !defined $rolename;

    my $role = $self->_jedi_auth_db->resultset('Role')
        ->find( { name => $rolename } );
    return [] if !defined $role;

    my @users = $role->users;
    return [ map { $_->user } @users ];
}

# count of user
sub jedi_auth_users_count {
    my ($self) = @_;
    return $self->_jedi_auth_db->resultset('User')->count;
}

# list of all users with info or just some of them
sub jedi_auth_users {
    my ( $self, @usernames ) = @_;

    my $users = $self->_jedi_auth_db->resultset('User');
    $users = $users->search( { user => \@usernames } ) if @usernames;

    return [ map { _user_to_hash($_) }
            $users->search( {}, { prefetch => { 'user_roles' => 'role' } } )
            ->all ];
}

1;

__END__

=pod

=head1 NAME

Jedi::Plugin::Auth::Role - Imported Role for L<Jedi::Plugin::Auth>

=head1 VERSION

version 0.01

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
