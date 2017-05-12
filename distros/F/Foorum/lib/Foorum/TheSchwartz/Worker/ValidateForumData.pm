package Foorum::TheSchwartz::Worker::ValidateForumData;

use strict;
use warnings;
our $VERSION = '1.001000';
use base qw( TheSchwartz::Moosified::Worker );
use Foorum::SUtils qw/schema/;
use Foorum::Logger qw/error_log/;

sub work {
    my $class = shift;
    my $job   = shift;

    my @args = $job->arg;

    my $schema = schema();
    my $error_log;

    # check data in forum with topic and comments table
    my $forum_rs = $schema->resultset('Forum');
    my $topic_rs = $schema->resultset('Topic');
    while ( my $forum = $forum_rs->next ) {
        my $forum_id      = $forum->forum_id;
        my $total_topics  = $forum->total_topics;
        my $total_replies = $forum->total_replies;

        my ( $topics, $replies ) = ( 0, 0 );
        my $topic_search = $topic_rs->search( { forum_id => $forum_id } );
        while ( my $topic = $topic_search->next ) {
            my $c_replies
                = $schema->resultset('Comment')
                ->count(
                { object_type => 'topic', object_id => $topic->topic_id } );
            $c_replies--;    # one is topic body

            $topics++;
            $replies += $c_replies;
            if ( $topic->total_replies != $c_replies ) {
                $topic_rs->update_topic( $topic->topic_id,
                    { total_replies => $c_replies } );
            }
        }

        if ( $total_topics != $topics || $total_replies != $replies ) {
            $forum_rs->update_forum( $forum_id,
                { total_topics => $topics, total_replies => $replies } );
            $error_log
                .= "Forum $forum_id record: topics - $topics, replies - $replies\n";
        }
    }

    error_log( $schema, 'info', $error_log ) if ($error_log);

    $job->completed();
}

1;
