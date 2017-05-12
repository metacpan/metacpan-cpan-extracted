package Foorum::ResultSet::User;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class::ResultSet';

use Object::Signature();
use Email::Valid::Loose;

sub get {
    my ( $self, $cond ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $cache_key = 'user|' . Object::Signature::signature($cond);
    my $cache_val = $cache->get($cache_key);

    if ($cache_val) {
        return $cache_val;
    }

    $cache_val = $self->get_from_db($cond);
    return unless ($cache_val);

    $cache->set( $cache_key, $cache_val, 7200 );    # two hours
    return $cache_val;
}

sub get_multi {
    my ( $self, $key, $val ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my @mem_keys;
    my %val_map_key;
    foreach (@$val) {
        my $cache_key
            = 'user|' . Object::Signature::signature( { $key => $_ } );
        push @mem_keys, $cache_key;
        $val_map_key{$_} = $cache_key;
    }

    my $users;
    if ( $cache->can('get_multi') ) {    # for Cache::Memcached
        $users = $cache->get_multi(@mem_keys);
    } else {
        foreach (@mem_keys) {
            $users->{$_} = $cache->get($_);
        }
    }

    my %return_users;
    foreach my $v (@$val) {
        if ( $users->{ $val_map_key{$v} } ) {
            $return_users{$v} = $users->{ $val_map_key{$v} };
        } else {
            $return_users{$v} = $self->get_from_db( { $key => $v } );
            next unless ( $return_users{$v} );
            $cache->set( $val_map_key{$v}, $return_users{$v}, 7200 )
                ;    # two hours
        }
    }

    return \%return_users;
}

sub get_from_db {
    my ( $self, $cond ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $user = $schema->resultset('User')->find($cond);
    return unless ($user);

    # user_details
    my $user_details = $schema->resultset('UserDetails')
        ->find( { user_id => $user->user_id } );
    $user_details = $user_details->{_column_data} if ($user_details);

    # user role
    my @roles = $schema->resultset('UserRole')
        ->search( { user_id => $user->user_id, } )->all;
    my $roles;
    foreach (@roles) {
        $roles->{ $_->field }->{ $_->role } = 1;
    }
    my @forum_roles = $schema->resultset('UserForum')
        ->search( { user_id => $user->user_id } )->all;
    foreach (@forum_roles) {
        $roles->{ $_->forum_id }->{ $_->status } = 1;
    }

    # user profile photo
    my $profile_photo = $schema->resultset('UserProfilePhoto')
        ->find( { user_id => $user->user_id, } );
    if ($profile_photo) {
        $profile_photo = $profile_photo->{_column_data};
        if ( $profile_photo->{type} eq 'upload' ) {

            my $profile_photo_upload = $schema->resultset('Upload')
                ->get( $profile_photo->{value} );
            $profile_photo->{upload} = $profile_photo_upload
                if ($profile_photo_upload);
        }
    }

    $user                  = $user->{_column_data};
    $user->{details}       = $user_details;
    $user->{roles}         = $roles;
    $user->{profile_photo} = $profile_photo;
    return $user;
}

sub delete_cache_by_user {
    my ( $self, $user ) = @_;

    return unless ($user);

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my @ckeys;
    push @ckeys,
        'user|'
        . Object::Signature::signature( { user_id => $user->{user_id} } );
    push @ckeys,
        'user|'
        . Object::Signature::signature( { username => $user->{username} } );
    push @ckeys,
        'user|' . Object::Signature::signature( { email => $user->{email} } );

    foreach my $ckey (@ckeys) {
        $cache->remove($ckey);
    }

    return 1;
}

sub delete_cache_by_user_cond {
    my ( $self, $cond ) = @_;

    my $user = $self->get($cond);
    $self->delete_cache_by_user($user);
}

# call this update will delete cache.
sub update_user {
    my ( $self, $user, $update ) = @_;

    $self->delete_cache_by_user($user);
    $self->search( { user_id => $user->{user_id} } )->update($update);
}

# update threads and replies count
sub update_threads_and_replies {
    my ( $self, $user ) = @_;

    my $schema = $self->result_source->schema;

    # get $threads + $replies
    my $total = $schema->resultset('Comment')->count(
        {   author_id   => $user->{user_id},
            object_type => 'topic',
        }
    );
    my $replies = $schema->resultset('Comment')->count(
        {   author_id   => $user->{user_id},
            object_type => 'topic',
            reply_to    => 0,
        }
    );

    $self->update_user( $user,
        { threads => $total - $replies, replies => $replies } );
}

# get user_settings
# we don't merge it into sub get_from_db is because it's not used so frequently
sub get_user_settings {
    my ( $self, $user ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    # this cachekey would be delete from Controller/Settings.pm
    my $cachekey = 'user|user_settings|user_id=' . $user->{user_id};
    my $cacheval = $cache->get($cachekey);

    if ($cacheval) {
        $cacheval = $cacheval->{val};
    } else {
        my $settings_rs = $schema->resultset('UserSettings')
            ->search( { user_id => $user->{user_id} } );
        $cacheval = {};
        while ( my $rs = $settings_rs->next ) {
            $cacheval->{ $rs->type } = $rs->value;
        }
        $cache->set( $cachekey, { val => $cacheval, 1 => 2 } )
            ;    # for empty $cacheval
    }

    # if not stored in db, we use default value;
    my $default = {
        'send_starred_notification' => 'Y',
        'show_email_public'         => 'Y',
    };
    my $ret = { %$default, %$cacheval };    # merge
    return $ret;
}

sub validate_username {
    my ( $self, $username ) = @_;

    return 'LENGTH' if ( length($username) < 6 or length($username) > 20 );

    for ($username) {
        return 'HAS_BLANK' if (/\s/);
        return 'HAS_SPECAIL_CHAR' unless (/^[A-Za-z0-9\_]+$/s);
    }

    my $schema = $self->result_source->schema;

    # username_reserved
    my @reserved
        = $schema->resultset('FilterWord')->get_data('username_reserved');
    return 'HAS_RESERVED' if ( grep { lc($username) eq lc($_) } @reserved );

    # unique
    my $cnt = $self->count( { username => $username } );
    return 'DBIC_UNIQUE' if ($cnt);

    return;
}

sub validate_email {
    my ( $self, $email ) = @_;

    return 'LENGTH' if ( length($email) > 64 );

    return 'EMAIL_LOOSE' unless ( Email::Valid::Loose->address($email) );

    # unique
    my $cnt = $self->count( { email => $email } );
    return 'DBIC_UNIQUE' if ($cnt);

    return;
}

1;
__END__

=pod

=head1 NAME

Foorum::ResultSet::User - User object

=head1 FUNCTION

=over 4

=item get

  $schema->resultset('User')->get( { user_id => ? } );
  $c->model('DBIC::User')->get( { username => ? } );
  $c->model('DBIC::User')->get( { email => ? } );

get() do not query database directly, it try to get from cache, if not exists, get_from_db() and set cache. return is a hashref: (we may call it $user_obj below)

  {
    user_id  => 1,
    username => 'fayland',
    # etc. from user table columns
    details  => {
        birthday => '1984-02-06',
        gtalk    => 'fayland'
        # etc. from user_details table columns
    },
    roles    => {
        1 => { admin => 1 },
        site => { admin => 1 },
        # etc. from user_roles, $field => { $role => 1 }
    }
    profile_photo => {
        type  => 'upload',
        value => 10,
        # etc. from user_profile_photo table columns
        upload => {
            upload_id => 10,
            filename  => 'fayland.jpg',
            # etc. from upload table columns
        }
    }
  }

=item get_multi

  $schema->resultset('User')->get_multi( user_id => [1, 2, 3]  );
  $c->model('DBIC::User')->get_multi( username => ['fayland', 'testman'] );

get_multi() is to ease a loop for many users. if cache backend is memcached, it would use $memcached->get_multi(); to get cached user, and use get_from_db() to missing users. return is a hashref:

  # $user_obj is the user hash above
  1 => $user_obj,
  2 => $user_obj,
  # or
  fayland => $user_obj,
  testman => $user_obj,

(TODO: we may use { user_id => { 'IN' => \@user_ids } } for missing users.)

=item get_from_db()

  $schema->resultset('User')->get_from_db( { user_id => ? } );
  $c->model('DBIC::User')->get_from_db( { username => ? } );
  $c->model('DBIC::User')->get_from_db( { email => ? } );

query db directly. return $user_obj

=item update_user()

  $c->model('DBIC::User')->update_user( $user_obj, { update_column => $value } );

the difference between $row->update of L<DBIx::Class> is that it delete cache.

=item delete_cache_by_user()

  $schema->resultset('User')->delete_cache_by_user( $user_obj);

=item delete_cache_by_user_cond

  $schema->resultset('User')->delete_cache_by_user_cond( { user_id => ? } );
  $c->model('DBIC::User')->delete_cache_by_user_cond( { username => ? } );
  $c->model('DBIC::User')->delete_cache_by_user_cond( { email => ? } );

=item update_threads_and_replies

  $schema->resultset('User')->update_threads_and_replies($user);

get the correct 'threads' and 'replies' and update for user

=item get_user_settings

  $c->model('DBIC::User')->get_user_settings( $user_obj);

get records from user_settings table. return is hashref

  {
    send_starred_notification => 'N',
  }

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
