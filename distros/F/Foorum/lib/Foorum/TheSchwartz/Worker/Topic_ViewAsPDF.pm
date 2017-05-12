package Foorum::TheSchwartz::Worker::Topic_ViewAsPDF;

use strict;
use warnings;
our $VERSION = '1.001000';
use base qw( TheSchwartz::Moosified::Worker );
use Foorum::SUtils qw/schema/;
use Foorum::Logger qw/error_log/;
use Foorum::XUtils qw/config base_path cache tt2/;
use Foorum::Formatter qw/filter_format/;
use PDF::FromHTML;
use File::Spec;

sub work {
    my $class = shift;
    my $job   = shift;

    my ($args) = $job->arg;
    my ( $forum_id, $topic_id, $random_word ) = @$args;

    my $schema     = schema();
    my $config     = config();
    my $cache      = cache();
    my $base_path  = base_path();
    my $tt2        = tt2();
    my $user_model = $schema->resultset('User');

    my $file = File::Spec->catfile( $base_path, 'root', 'upload', 'pdf',
        "$forum_id-$topic_id-$random_word.pdf" );
    my $var;    # tt2 vars.

    # get comments
    my $cache_key   = "comment|object_type=topic|object_id=$topic_id";
    my $cache_value = $cache->get($cache_key);
    my @comments;
    if ($cache_value) {
        @comments = @{ $cache_value->{comments} };
    } else {
        my $it = $schema->resultset('Comment')->search(
            {   object_type => 'topic',
                object_id   => $topic_id,
            },
            { order_by => 'post_on', }
        );

        while ( my $rec = $it->next ) {
            $rec = $rec->{_column_data};    # for cache using

            # filter format by Foorum::Filter
            $rec->{title} = $schema->resultset('FilterWord')
                ->convert_offensive_word( $rec->{title} );
            $rec->{text} = $schema->resultset('FilterWord')
                ->convert_offensive_word( $rec->{text} );
            $rec->{text} = filter_format( $rec->{text},
                { format => $rec->{formatter} } );

            push @comments, $rec;
        }
    }
    foreach (@comments) {
        $_->{author} = $user_model->get( { user_id => $_->{author_id} } );
    }
    $var->{comments} = \@comments;

    # get topic
    my $topic
        = $schema->resultset('Topic')->find( { topic_id => $topic_id } );
    $var->{topic} = $topic;

    my $pdf_body;
    $tt2->process( 'topic/topic.pdf.html', $var, \$pdf_body );

    my $pdf = PDF::FromHTML->new( encoding => 'utf-8' );
    $pdf->load_file( \$pdf_body );
    $pdf->convert();
    $pdf->write_file($file);

    $job->completed();
}

1;
