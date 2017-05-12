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
use Foorum::TheSchwartz::Worker::ResendActivation;
use lib 'E:\Fayland\projects\moosex-theschwartz\lib';
use TheSchwartz::Moosified;
use Foorum::SUtils qw/schema/;
use Foorum::TestUtils qw/rollback_db/;

plan tests => 4;

run_test(
    sub {
        my $dbh    = shift;
        my $client = TheSchwartz::Moosified->new();
        $client->databases( [$dbh] );

        my $schema = schema();

        {

            # fake some data first
            $schema->resultset('User')->create(
                {   user_id       => 6,
                    username      => 'fayland',
                    email         => 'fayland@gmail.com',
                    status        => 'unverified',
                    register_time => time() - 31 * 86400,
                    nickname      => 'nick',
                    password      => 'xxxxxxxxxxx',
                    register_ip   => '127.0.0.1',
                    lang          => 'en',
                }
            );
            $schema->resultset('User')->create(
                {   user_id       => 7,
                    username      => 'fayland7',
                    email         => 'fayland7@gmail.com',
                    status        => 'unverified',
                    register_time => time() - 15 * 86400,
                    nickname      => 'nick',
                    password      => 'xxxxxxxxxxx',
                    register_ip   => '127.0.0.1',
                    lang          => 'en',
                }
            );
        }

        {
            my $handle = $client->insert(
                'Foorum::TheSchwartz::Worker::ResendActivation');

            $client->can_do('Foorum::TheSchwartz::Worker::ResendActivation');
            $client->work_until_done;

            # test if OK
            my $mail_count = $schema->resultset('ScheduledEmail')
                ->count( { email_type => 'activation' } );
            is( $mail_count, 1, 'has 1 , mail' );
            my $mail_rs = $schema->resultset('ScheduledEmail')
                ->search( { email_type => 'activation' } )->first;
            ok($mail_rs);
            like(
                $mail_rs->subject,
                qr/Your Activation Code In/,
                'subject has Your Activation Code In'
            );
            is( $mail_rs->to_email, 'fayland@gmail.com', 'to_email OK' );
        }
    }
);

END {

    # Keep Database the same from original
    rollback_db();
}

1;
