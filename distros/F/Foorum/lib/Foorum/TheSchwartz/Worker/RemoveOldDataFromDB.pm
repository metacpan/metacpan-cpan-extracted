package Foorum::TheSchwartz::Worker::RemoveOldDataFromDB;

use strict;
use warnings;
our $VERSION = '1.001000';
use base qw( TheSchwartz::Moosified::Worker );
use Foorum::SUtils qw/schema/;
use Foorum::Logger qw/error_log/;
use Foorum::XUtils qw/base_path/;
use Foorum::CronUtils qw/cron_config/;

sub work {
    my $class = shift;
    my $job   = shift;

    my @args = $job->arg;

    my $schema      = schema();
    my $cron_config = cron_config();

    # for table 'visit'
    # 2592000 = 30 * 24 * 60 * 60
    my $old_time = $cron_config->{remove_db_old_data}->{visit} || 2592000;
    my $visit_status = $schema->resultset('Visit')
        ->search( { time => { '<', time() - $old_time } } )->delete;

    # for table 'log_path'
    my $days_ago = $cron_config->{remove_db_old_data}->{log_path} || 30;
    my $log_path_status = $schema->resultset('LogPath')
        ->search( { time => { '<', $days_ago * 86400 }, } )->delete;

    # for table 'log_error'
    $days_ago = $cron_config->{remove_db_old_data}->{log_error} || 30;
    my $log_error_status = $schema->resultset('LogError')
        ->search( { time => { '<', $days_ago * 86400 }, } )->delete;

    # for table 'banned_ip'
    $days_ago = $cron_config->{remove_db_old_data}->{banned_ip} || 604800;
    my $banned_ip_status = $schema->resultset('BannedIp')
        ->search( { time => { '<', time() - $days_ago }, } )->delete;

    # for table 'session'
    # 2592000 = 30 * 24 * 60 * 60
    my $session_status = $schema->resultset('Session')
        ->search( { expires => { '<', time() }, } )->delete;

    error_log( $schema, 'info', <<LOG);
remove_db_old_data - status:
    visit - $visit_status
    log_path - $log_path_status
    log_error - $log_error_status
    banned_ip - $banned_ip_status
    session   - $session_status
LOG

    $job->completed();
}

1;
__END__

=pod

=head1 NAME

Foorum::TheSchwartz::Worker::RemoveOldDataFromDB - remove data from database to keep it small

=head1 SYNOPSIS

  # check bin/cron/TheSchwartz_client.pl and bin/cron/TheSchwartz_worker.pl for usage

=head1 DESCRIPTION

Remove old/useless data to keep database as small as possible. Things removed are:

=over 4

=item records in visit table more than 30 days

=item log_path and log_error more than 30 days

=item banned_ip more than 1 week

=item session more than 30 days

=back

=head1 SEE ALSO

L<TheSchwartz>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
