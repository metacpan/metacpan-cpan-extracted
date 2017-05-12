package Foorum::ResultSet::UserForum;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class::ResultSet';

sub create_user_forum {
    my ( $self, $info ) = @_;

    $self->create(
        {   user_id  => $info->{user_id},
            forum_id => $info->{forum_id},
            status   => $info->{status},
            time     => time(),
        }
    );

    $self->clear_cached_policy($info);
}

sub remove_user_forum {
    my ( $self, $info ) = @_;

    my @wheres;
    push @wheres, ( user_id  => $info->{user_id} )  if ( $info->{user_id} );
    push @wheres, ( forum_id => $info->{forum_id} ) if ( $info->{forum_id} );
    push @wheres, ( status   => $info->{status} )   if ( $info->{status} );

    return unless ( scalar @wheres );

    $self->search( { @wheres, } )->delete;

    $self->clear_cached_policy($info);
}

sub clear_cached_policy {
    my ( $self, $info ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    if ( $info->{user_id} ) {

        # clear user cache too
        $schema->resultset('User')
            ->delete_cache_by_user_cond( { user_id => $info->{user_id} } );
    }

    if ( $info->{forum_id} ) {
        $cache->remove("policy|user_role|forum_id=$info->{forum_id}");
    }

}

sub get_forum_moderators {
    my ( $self, $forum_id ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    # for forum_id is an ARRAYREF: [1,2], we don't cache it because
    # when remove_user_role, we don't know how to clear all forum1's keys.

    my $mem_key;
    if ( $forum_id =~ /^\d+$/ ) {
        $mem_key = "policy|user_role|forum_id=$forum_id";
        my $mem_val = $cache->get($mem_key);
        return $mem_val if ($mem_val);
    }

    my @users = $self->search(
        {   status   => [ 'admin', 'moderator' ],
            forum_id => $forum_id,
        }
    )->all;

    my $roles;
    foreach (@users) {
        my $user
            = $schema->resultset('User')->get( { user_id => $_->user_id, } );
        next unless ($user);
        if ( $_->status eq 'admin' ) {
            $roles->{ $_->forum_id }->{'admin'} = {    # for cache
                username => $user->{username},
                nickname => $user->{nickname}
            };
        } elsif ( $_->status eq 'moderator' ) {
            push @{ $roles->{ $_->forum_id }->{'moderator'} }, $user;
        }
    }

    $cache->set( $mem_key, $roles ) if ($mem_key);

    return $roles;
}

sub get_forum_admin {
    my ( $self, $forum_id ) = @_;

    my $schema = $self->result_source->schema;

    # get admin
    my $rs = $self->search(
        {   forum_id => $forum_id,
            status   => 'admin',
        }
    )->first;
    return unless ($rs);
    my $user = $schema->resultset('User')->get( { user_id => $rs->user_id } );
    return $user;
}

1;
