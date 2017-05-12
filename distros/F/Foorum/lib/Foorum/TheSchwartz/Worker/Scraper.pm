package Foorum::TheSchwartz::Worker::Scraper;

use strict;
use warnings;
our $VERSION = '1.001000';
use base qw( TheSchwartz::Moosified::Worker );
use Foorum::SUtils qw/schema/;
use Foorum::Logger qw/error_log/;
use Foorum::XUtils qw/cache/;
use Foorum::Scraper::MailMan;
use Foorum::Utils qw/encodeHTML/;
use POSIX qw(strftime);
use File::Spec;
use Encode qw/from_to/;
use YAML::XS qw/LoadFile/;
use Cwd qw/abs_path/;
my ( undef, $path ) = File::Spec->splitpath(__FILE__);
$path = abs_path($path);
my $scraper_config = LoadFile(
    File::Spec->catfile(
        $path, '..', '..', '..', '..', 'conf', 'scraper.yml'
    )
);

my @FullName_months = (
    '',       'January',   'February', 'March',
    'April',  'May',       'June',     'July',
    'August', 'September', 'October',  'November',
    'December'
);

my @Re_s = ( 'Re\:', '答复\:' );

sub work {
    my $class = shift;
    my $job   = shift;

    # if not setted, just return
    unless ($scraper_config) {
        return $job->completed();
    }

    my @args   = $job->arg;
    my $schema = schema();
    my $cache  = cache();
    my $log_text;

    my @gmtimes        = gmtime( time() - 86400 );    # check one day before
    my $year           = $gmtimes[5] + 1900;
    my $month          = $gmtimes[4] + 1;
    my $fullname_month = $FullName_months[$month];
    my $postfix = "$year-$fullname_month/thread.html";
    my $scraper = new Foorum::Scraper::MailMan();

    my @mailmans = @{ $scraper_config->{scraper}->{mailman} };
    foreach my $mailman (@mailmans) {
        $log_text .= "Working on $mailman->{name}\n";
        next unless ( $mailman->{forum_id} );
        my $forum_id    = $mailman->{forum_id};
        my $user_id     = $mailman->{user_id};
        my $name        = $mailman->{name};
        my $last_msg_id = get_last_scraped_msg_id( $schema, $forum_id,
            "scraper-mailman-$name" );
        next if ( $last_msg_id == -1 );    # non-exists
        my $scraper_url = $mailman->{url} . $postfix;

        # scraper as a hash of array
        my $ret = $scraper->scraper($scraper_url);

        # group by title
        my %title_related;
        foreach (@$ret) {
            if ( exists $title_related{ $_->{title} } ) {
                push @{ $title_related{ $_->{title} } }, $_;
            } else {
                $title_related{ $_->{title} } = [$_];
            }
        }

        my $is_changed   = 0;    # flag to update forum or not
        my $last_post_id = 0;    # set forum's last_post_id

        # start to skip/insert
        foreach my $title ( keys %title_related ) {
            $title =~ s/(^\s+|\s+$)//isg;
            next unless ( length($title) );
            $log_text .= "\n[title] $title : ";

            my @populate_contents;
            my @contents = @{ $title_related{$title} };
            @contents = sort { $a->{msg_id} <=> $b->{msg_id} } @contents;
            foreach my $content (@contents) {
                my $msg_id = $content->{msg_id};
                if ( $msg_id <= $last_msg_id ) {
                    $log_text .= "Skip $msg_id, ";
                } else {
                    $log_text .= "Insert $msg_id, ";
                    push @populate_contents, $content;
                }
            }
            if ( scalar @populate_contents ) {

                # get topic_id or create one
                my ( $topic_id, $reply_to )
                    = get_topic_or_create( $schema, $forum_id, $title,
                    $user_id, scalar @populate_contents - 1 );
                $last_post_id = $topic_id;
                foreach my $content (@populate_contents) {
                    my $text
                        = qq~<p><strong>$content->{who}</strong> posted on <i>$content->{when}</i>:</p><pre>$content->{text}</pre>~;
                    my $comment = $schema->resultset('Comment')->create(
                        {   object_type => 'topic',
                            object_id   => $topic_id,
                            author_id   => $user_id,
                            title       => $title,
                            text        => $text,
                            formatter   => 'html',
                            post_on     => time(),
                            post_ip     => '127.0.0.1',
                            reply_to    => $reply_to,
                            forum_id    => $forum_id,
                            upload_id   => 0,
                        }
                    );
                    $is_changed = 1;

                    # if $reply_to == 0 means new topic
                    # then we use the first comment's comment_id as reply_to
                    $reply_to = $comment->comment_id if ( $reply_to == 0 );

                    # update $last_msg_id so that no need to run again
                    $last_msg_id = $content->{msg_id}
                        if ( $content->{msg_id} > $last_msg_id );
                }

                # clear cache
                my $cache_key
                    = "comment|object_type=topic|object_id=$topic_id";
                $cache->remove($cache_key);

            }
        }

        # update last_msg_id
        update_last_scraped_msg_id( $schema, "scraper-mailman-$name",
            $last_msg_id );

        # update threads|replies count for forum and user
        if ( $is_changed and $last_post_id ) {
            update_forum( $schema, $cache, $forum_id, $last_post_id );
            my $user
                = $schema->resultset('User')->get( { user_id => $user_id } );
            $schema->resultset('User')->update_threads_and_replies($user);
        }
    }

    error_log( $schema, 'info', $log_text );
    $job->completed();
}

sub get_last_scraped_msg_id {
    my ( $schema, $forum_id, $name ) = @_;

    my $count
        = $schema->resultset('Forum')->count( { forum_id => $forum_id } );
    return -1 unless ($count);    # forum non-exists

    $name = substr( $name, 0, 24 );
    my $rs = $schema->resultset('Variables')->search(
        {   type => 'log',
            name => $name
        }
    )->first;
    return $rs ? $rs->value : 0;
}

sub update_last_scraped_msg_id {
    my ( $schema, $name, $value ) = @_;

    $name = substr( $name, 0, 24 );
    $schema->resultset('Variables')->search(
        {   type => 'log',
            name => $name,
        }
    )->delete;
    $schema->resultset('Variables')->create(
        {   type  => 'log',
            name  => $name,
            value => $value
        }
    );
}

sub get_topic_or_create {
    my ( $schema, $forum_id, $title, $user_id, $replies_no ) = @_;

    # trim 'Re:\s+'
    foreach my $tre (@Re_s) {
        $title =~ s/^$tre\s+//isg;
    }

    my $topic = $schema->resultset('Topic')->search(
        {   title    => { 'LIKE', $title },
            forum_id => $forum_id,
        },
        { columns => ['topic_id'], }
    )->first;
    if ($topic) {
        my $rs = $schema->resultset('Comment')->search(
            {   object_type => 'topic',
                object_id   => $topic->topic_id,
            },
            {   order_by => 'post_on',
                rows     => 1,
                page     => 1,
                columns  => ['comment_id'],
            }
        )->first;
        if ($rs) {
            my $reply_to = $rs->comment_id;
            return ( $topic->topic_id, $reply_to );
        }
    }

    # or else, create one
    my $topic_title = encodeHTML($title);
    my $new_topic   = $schema->resultset('Topic')->create(
        {   forum_id         => $forum_id,
            title            => $topic_title,
            author_id        => $user_id,
            last_updator_id  => $user_id,
            last_update_date => time(),
            hit              => 0,
            total_replies    => $replies_no
        }
    );
    return ( $new_topic->topic_id, 0 );
}

sub update_forum {
    my ( $schema, $cache, $forum_id, $last_post_id ) = @_;

    my $forum
        = $schema->resultset('Forum')->count( { forum_id => $forum_id } );
    return unless ($forum);

    # update forum
    $schema->resultset('Forum')->search( { forum_id => $forum_id, } )
        ->update( { last_post_id => $last_post_id || 0, } );

    $cache->remove("forum|forum_id=$forum_id");
}

1;
