#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    $ENV{TEST_FOORUM} = 1;
}

use FindBin qw/$Bin/;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );
use Foorum::TestTheSchwartz;
use Foorum::TheSchwartz::Worker::DailyReport;
use TheSchwartz::Moosified;
use Foorum::SUtils qw/schema/;
use Foorum::TestUtils qw/rollback_db/;

plan tests => 4;

run_test(
    sub {
        my $dbh    = shift;
        my $client = TheSchwartz::Moosified->new();
        $client->databases( [$dbh] );

        {
            my $handle
                = $client->insert('Foorum::TheSchwartz::Worker::DailyReport');

            $client->can_do('Foorum::TheSchwartz::Worker::DailyReport');
            $client->work_until_done;

            # test if OK
            my $schema     = schema();
            my $mail_count = $schema->resultset('ScheduledEmail')
                ->count( { email_type => 'daily_report', } );
            is( $mail_count, 1, 'has 1 daily_report mail' );
            my $mail_rs = $schema->resultset('ScheduledEmail')
                ->search( { email_type => 'daily_report', } )->first;
            ok($mail_rs);
            like(
                $mail_rs->subject,
                qr/\[Foorum\] Daily Report/,
                'subject has [Foorum] Daily Report'
            );
            like( $mail_rs->plain_body, qr/NewAddedUser/,
                'plain_body has NewAddedUser' );
        }
    }
);

END {

    # Keep Database the same from original
    rollback_db();
}

1;
