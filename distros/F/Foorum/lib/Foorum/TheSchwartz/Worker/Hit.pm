package Foorum::TheSchwartz::Worker::Hit;

use strict;
use warnings;
our $VERSION = '1.001000';
use base qw( TheSchwartz::Moosified::Worker );
use Data::Dump qw/dump/;
use Foorum::SUtils qw/schema/;
use Foorum::Logger qw/error_log/;

sub work {
    my $class = shift;
    my $job   = shift;

    my @args = $job->arg;

    my $schema = schema();

    # for /site/popular
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst )
        = localtime();

    my $sql = 'UPDATE hit SET ';
    if ( $hour == 1 and $min < 5 ) {    # the first hour of today
        $sql .= 'hit_yesterday = hit_today, hit_today = hit_new, ';
    } else {

        $sql .= 'hit_today = hit_today + hit_new, ';
    }
    if ( $wday == 1 and ( $hour == 1 and $min < 5 ) ) {    # Monday
        $sql .= 'hit_weekly = hit_new, ';
    } else {

        $sql .= 'hit_weekly = hit_weekly + hit_new, ';
    }
    if ( $mday == 1 and ( $hour == 1 and $min < 5 ) )
    {    # The first day of the month
        $sql .= 'hit_monthly = hit_new, ';
    } else {

        $sql .= 'hit_monthly = hit_monthly + hit_new, ';
    }

    $sql .= 'hit_new = 0';
    my $dbh = $schema->storage->dbh;
    $dbh->do($sql);

    # update the real data in table
    my $rs = $schema->resultset('Hit')
        ->search( { last_update_time => { '>', 0 } } );
    my $last_update_time = 0;
    my $updated_count    = 0;
    while ( my $r = $rs->next ) {

        # update into real table
        if ( $r->object_type eq 'topic' ) {
            $schema->resultset('Topic')
                ->search( { topic_id => $r->object_id } )
                ->update( { hit => $r->hit_all, } );
        } elsif ( $r->object_type eq 'poll' ) {
            $schema->resultset('Poll')
                ->search( { poll_id => $r->object_id, } )
                ->update( { hit => $r->hit_all, } );
        }
        $last_update_time = $r->last_update_time
            if ( $r->last_update_time > $last_update_time );
        $updated_count++;
    }

    # set flag as updated
    $schema->resultset('Hit')->search(
        {   -and => [
                last_update_time => { '<=', $last_update_time },
                last_update_time => { '>',  0 }
            ]
        }
    )->update( { last_update_time => 0 } );

    error_log( $schema, 'info',
        "update_hit ($updated_count) - $sql \@ " . localtime() );

    $job->completed();
}

1;
__END__

=pod

=head1 NAME

Foorum::TheSchwartz::Worker::Hit - Update hit for popular and into co-tables.

=head1 SYNOPSIS

  # check bin/cron/TheSchwartz_client.pl and bin/cron/TheSchwartz_worker.pl for usage

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

L<TheSchwartz>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
