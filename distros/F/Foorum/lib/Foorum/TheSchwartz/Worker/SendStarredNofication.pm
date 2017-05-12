package Foorum::TheSchwartz::Worker::SendStarredNofication;

use strict;
use warnings;
our $VERSION = '1.001000';
use base qw( TheSchwartz::Moosified::Worker );
use Foorum::SUtils qw/schema/;
use Foorum::XUtils qw/config base_path cache/;

sub work {
    my $class = shift;
    my $job   = shift;

    my ($args) = $job->arg;
    my ( $object_type, $object_id, $from_id ) = @$args;

    my $schema     = schema();
    my $config     = config();
    my $cache      = cache();
    my $base_path  = base_path();
    my $user_model = $schema->resultset('User');

    # if it is a starred item and settings send_starred_notification is Y
    my $starred_rs = $schema->resultset('Star')->search(
        {   object_type => $object_type,
            object_id   => $object_id
        },
        { columns => ['user_id'], }
    );
    my @user_ids;
    while ( my $r = $starred_rs->next ) {
        push @user_ids, $r->user_id;
    }
    if ( scalar @user_ids ) {
        my $object = get_object( $schema, $cache, $object_type, $object_id );
        my $from = $user_model->get( { user_id => $from_id } );

        foreach my $user_id (@user_ids) {
            my $user = $user_model->get( { user_id => $user_id } );
            next unless ($user);
            next if ( $user->{user_id} == $from->{user_id} );   # skip himself
                 # Send Notification Email

            # Send Notification Email
            $schema->resultset('ScheduledEmail')->create_email(
                {   template => 'starred_notification',
                    to       => $user->{email},
                    lang     => $user->{lang},
                    stash    => {
                        rept   => $user,
                        from   => $from,
                        object => $object,
                    }
                }
            );
        }
    }

    $job->completed();
}

sub get_object {
    my ( $schema, $cache, $object_type, $object_id ) = @_;

    my $user_model = $schema->resultset('User');

    if ( 'topic' eq $object_type ) {
        my $object = $schema->resultset('Topic')
            ->find( { topic_id => $object_id, } );
        return unless ($object);
        my $author = $user_model->get( { user_id => $object->author_id } );
        return {
            object_type => 'topic',
            object_id   => $object_id,
            title       => $object->title,
            author      => $author,
            url         => '/forum/' . $object->forum_id . "/$object_id",
            last_update => $object->last_update_date,
        };
    } elsif ( 'poll' eq $object_type ) {
        my $object
            = $schema->resultset('Poll')->find( { poll_id => $object_id, } );
        return unless ($object);
        my $author = $user_model->get( { user_id => $object->author_id } );
        return {
            object_type => 'poll',
            object_id   => $object_id,
            title       => $object->title,
            author      => $author,
            url         => '/forum/' . $object->forum_id . "/poll/$object_id",
            last_update => '-',
        };
    }
}

1;
__END__

=pod

=head1 NAME

Foorum::TheSchwartz::Worker::SendStarredNofication - Send notification when starred object gets update

=head1 SYNOPSIS

  # check bin/cron/TheSchwartz_client.pl and bin/cron/TheSchwartz_worker.pl for usage

=head1 DESCRIPTION

When one topic updated, we must send mails to those people who starred the topic.
If the count of those people are huge like 1000 or more, it's too slow to handle in Catalyst App.
So that's what this module for.

=head1 SEE ALSO

L<TheSchwartz>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
