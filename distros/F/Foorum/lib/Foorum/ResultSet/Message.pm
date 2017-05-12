package Foorum::ResultSet::Message;

use strict;
use warnings;
our $VERSION = '1.001000';
use base 'DBIx::Class::ResultSet';

sub remove_from_db {
    my ( $self, $message_id ) = @_;

    my $schema = $self->result_source->schema;

    $self->search( { message_id => $message_id } )->delete;
    $schema->resultset('MessageUnread')
        ->search( { message_id => $message_id } )->delete;
}

sub are_messages_unread {
    my ( $self, $user_id, $message_ids ) = @_;

    return unless ($user_id);

    my $schema = $self->result_source->schema;
    my @rs     = $schema->resultset('MessageUnread')->search(
        {   user_id    => $user_id,
            message_id => $message_ids,
        },
        { columns => ['message_id'], }
    )->all;

    my $unread;
    $unread->{ $_->message_id } = 1 foreach (@rs);

    return $unread;
}

sub get_unread_cnt {
    my ( $self, $user_id ) = @_;

    my $schema = $self->result_source->schema;
    my $cache  = $schema->cache();

    my $cachekey = "global|message_unread_cnt|user_id=$user_id";
    my $cacheval = $cache->get($cachekey);

    if ($cacheval) {
        return $cacheval->{val};
    } else {
        my $cnt = $schema->resultset('MessageUnread')
            ->count( { user_id => $user_id } );
        $cache->set( $cachekey, { val => $cnt, 1 => 2 }, 1800 )
            ;    # half an hour

        return $cnt;
    }
}

1;
