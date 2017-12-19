package AuthMilterTest;

use strict;
use warnings;
use Net::DNS::Resolver::Mock;
use Test::More;
use Test::File::Contents;

use Cwd qw{ cwd };
use IO::Socket::INET;
use IO::Socket::UNIX;
use JSON;
use Module::Load;

use Mail::Milter::Authentication::Tester;

use Mail::Milter::Authentication;
use Mail::Milter::Authentication::Client;
use Mail::Milter::Authentication::Config;
use Mail::Milter::Authentication::Protocol::Milter;
use Mail::Milter::Authentication::Protocol::SMTP;

my $base_dir = cwd();

our $MASTER_PROCESS_PID = $$;

sub run_milter_processing_spam {

    if ( -e '/usr/sbin/postmap' ) {
        system( '/usr/sbin/postmap', 'config/spam/virtusertable' );
    }

    start_milter( 'config/spam' );

    milter_process({
        'desc'   => 'Gtube',
        'prefix' => 'config/spam',
        'source' => 'gtube.eml',
        'dest'   => 'gtube.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    milter_process({
        'desc'   => 'Gtube local',
        'prefix' => 'config/spam',
        'source' => 'gtube2.eml',
        'dest'   => 'gtube2.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'recipient2@example.net',
    });

    test_metrics( 'data/metrics/milter_spam.json' );
    stop_milter();

    return;
}

sub run_smtp_processing_spam {

    if ( -e '/usr/sbin/postmap' ) {
        system( '/usr/sbin/postmap', 'config/spam.smtp/virtusertable' );
    }

    start_milter( 'config/spam.smtp' );

    smtp_process({
        'desc'   => 'Gtube',
        'prefix' => 'config/spam.smtp',
        'source' => 'gtube.eml',
        'dest'   => 'gtube.smtp.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    smtp_process({
        'desc'   => 'Gtube local',
        'prefix' => 'config/spam.smtp',
        'source' => 'gtube2.eml',
        'dest'   => 'gtube2.smtp.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'recipient2@example.net',
    });

    test_metrics( 'data/metrics/smap_spam.json' );
    stop_milter();

    return;
}

sub run_milter_processing_clamav {

    if ( -e '/usr/sbin/postmap' ) {
        system( '/usr/sbin/postmap', 'config/clamav/virtusertable' );
    }

    start_milter( 'config/clamav' );

    milter_process({
        'desc'   => 'Virus',
        'prefix' => 'config/clamav',
        'source' => 'virus.eml',
        'dest'   => 'virus.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    milter_process({
        'desc'   => 'No Virus',
        'prefix' => 'config/clamav',
        'source' => 'gtube2.eml',
        'dest'   => 'novirus.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'recipient2@example.net',
    });

    test_metrics( 'data/metrics/milter_clam.json' );
    stop_milter();

    return;
}

sub run_smtp_processing_clamav {

    if ( -e '/usr/sbin/postmap' ) {
        system( '/usr/sbin/postmap', 'config/clamav.smtp/virtusertable' );
    }

    start_milter( 'config/clamav.smtp' );

    smtp_process({
        'desc'   => 'Virus',
        'prefix' => 'config/clamav.smtp',
        'source' => 'virus.eml',
        'dest'   => 'virus.smtp.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    smtp_process({
        'desc'   => 'No Virus',
        'prefix' => 'config/clamav.smtp',
        'source' => 'gtube2.eml',
        'dest'   => 'novirus.smtp.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'recipient2@example.net',
    });

    test_metrics( 'data/metrics/smtp_clam.json' );
    stop_milter();

    return;
}

sub run_milter_processing_rspamd {

    if ( -e '/usr/sbin/postmap' ) {
        system( '/usr/sbin/postmap', 'config/rspamd/virtusertable' );
    }

    start_milter( 'config/rspamd' );

    milter_process({
        'desc'   => 'Gtube',
        'prefix' => 'config/rspamd',
        'source' => 'gtube.eml',
        'dest'   => 'rspamd-gtube.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    milter_process({
        'desc'   => 'Gtube local',
        'prefix' => 'config/rspamd',
        'source' => 'gtube2.eml',
        'dest'   => 'rspamd-gtube2.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'recipient2@example.net',
    });

    test_metrics( 'data/metrics/milter_rspamd.json' );
    stop_milter();

    return;
}

sub run_smtp_processing_rspamd {

    if ( -e '/usr/sbin/postmap' ) {
        system( '/usr/sbin/postmap', 'config/rspamd.smtp/virtusertable' );
    }

    start_milter( 'config/rspamd.smtp' );

    smtp_process({
        'desc'   => 'Gtube',
        'prefix' => 'config/rspamd.smtp',
        'source' => 'gtube.eml',
        'dest'   => 'rspamd-gtube.smtp.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    smtp_process({
        'desc'   => 'Gtube local',
        'prefix' => 'config/rspamd.smtp',
        'source' => 'gtube2.eml',
        'dest'   => 'rspamd-gtube2.smtp.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'recipient2@example.net',
    });

    test_metrics( 'data/metrics/smtp_rspamd.json' );
    stop_milter();

    return;
}

1;
