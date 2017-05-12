package Foorum::TheSchwartz::Worker::DailyReport;

use strict;
use warnings;
our $VERSION = '1.001000';
use base qw( TheSchwartz::Moosified::Worker );
use Foorum::SUtils qw/schema/;
use Foorum::Logger qw/error_log/;
use Foorum::XUtils qw/config/;

sub work {
    my $class = shift;
    my $job   = shift;

    my @args = $job->arg;

    my $config = config();
    my $schema = schema();

    my $time = time() - 86400;

    # check db
    my $new_added_user = $schema->resultset('User')
        ->count( { register_time => { '>', $time } } );
    my $new_added_visits
        = $schema->resultset('Visit')->count( { time => { '>', $time } } );
    my $left_email
        = $schema->resultset('ScheduledEmail')->count( { processed => 'N' } );
    my $sent_email = $schema->resultset('ScheduledEmail')->count(
        {   processed => 'Y',
            time      => { '>', $time },
        }
    );
    my $log_error_count = $schema->resultset('LogError')
        ->count( { time => { '>', $time }, } );
    my $log_path_count
        = $schema->resultset('LogPath')->count( { time => { '>', $time }, } );

    my $text_body = qq~
        NewAddedUser:   $new_added_user\n
        NewAddedVisit:  $new_added_visits\n
        ScheduledEmail: $left_email\n
        SentEmail:      $sent_email\n
        LogErrorCount:  $log_error_count\n
        LogPathCount:   $log_path_count\n~;

    # all fatal errors in path_error
    my $rs = $schema->resultset('LogError')->search(
        {   time  => { '>', $time },
            level => { '>', 3 },       # error and fatal, check Foorum::Logger
        },
        {   rows    => 10,
            page    => 1,
            columns => [ 'text', 'time' ]
        }
    );
    if ( my $total = $rs->pager->total_entries ) {
        $text_body .= qq~ATTENTION!!!!!!! $total FATAL ISSUE\n~;
        while ( my $error = $rs->next ) {
            my $text = $error->text;
            my $time = $error->time;
            $time = scalar( localtime($time) );
            $text_body .= qq~On $time\n$text\n\n~;
        }
    }

    # Send DailyReport Email
    $schema->resultset('ScheduledEmail')->create_email(
        {   template   => 'daily_report',
            to         => $config->{mail}->{daily_report_email},
            lang       => $config->{default_lang},
            subject    => '[Foorum] Daily Report @ ' . scalar( localtime() ),
            plain_body => $text_body,
        }
    );

    $job->completed();
}

1;
__END__

=pod

=head1 NAME

Foorum::TheSchwartz::Worker::DailyReport - send a daily report to Administrator

=head1 SYNOPSIS

  # check bin/cron/TheSchwartz_client.pl and bin/cron/TheSchwartz_worker.pl for usage

=head1 DESCRIPTION

Send a daily report incluing:

=over 4

=item How many users joined last 24 hours

=item How many visits last 24 hours

=item How many email scheduled to send now

=item How many email is sent last 24 hours

=item How many records in log_error last 24 hours.

=item How many records in log_path last 24 hours

=item All 'fatal' error in log_error

=back

=head1 SEE ALSO

L<TheSchwartz>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
