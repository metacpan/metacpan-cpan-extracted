package AuthMilterTest;

use strict;
use warnings;
use Test::More;
use Test::File::Contents;

use Cwd qw{ cwd };
use IO::Socket::INET;
use IO::Socket::UNIX;
use Module::Load;

use Mail::Milter::Authentication::Tester;

use Mail::Milter::Authentication;
use Mail::Milter::Authentication::Client;
use Mail::Milter::Authentication::Config;
use Mail::Milter::Authentication::Protocol::Milter;
use Mail::Milter::Authentication::Protocol::SMTP;

my $base_dir = cwd();

our $MASTER_PROCESS_PID = $$;

sub run_milter_processing_smime {

    start_milter( 'config/smime' );

    milter_process({
        'desc'   => 'Smime pass',
        'prefix' => 'config/smime',
        'source' => 'smime.eml',
        'dest'   => 'smime.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    milter_process({
        'desc'   => 'Smime fail',
        'prefix' => 'config/smime',
        'source' => 'smime2.eml',
        'dest'   => 'smime2.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    milter_process({
        'desc'   => 'Smime forward',
        'prefix' => 'config/smime',
        'source' => 'smime3.eml',
        'dest'   => 'smime3.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    milter_process({
        'desc'   => 'Smime application/pkcs8-mime',
        'prefix' => 'config/smime',
        'source' => 'smime4.eml',
        'dest'   => 'smime4.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    stop_milter();

    return;
}

sub run_smtp_processing_smime {

    start_milter( 'config/smime.smtp' );

    smtp_process({
        'desc'   => 'Smime pass',
        'prefix' => 'config/smime.smtp',
        'source' => 'smime.eml',
        'dest'   => 'smime.smtp.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    smtp_process({
        'desc'   => 'Smime fail',
        'prefix' => 'config/smime.smtp',
        'source' => 'smime2.eml',
        'dest'   => 'smime2.smtp.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    smtp_process({
        'desc'   => 'Smime forward',
        'prefix' => 'config/smime.smtp',
        'source' => 'smime3.eml',
        'dest'   => 'smime3.smtp.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    smtp_process({
        'desc'   => 'Smime application/pkcs8-mime',
        'prefix' => 'config/smime.smtp',
        'source' => 'smime4.eml',
        'dest'   => 'smime4.smtp.eml',
        'ip'     => '74.125.82.171',
        'name'   => 'mail-we0-f171.google.com',
        'from'   => 'marc@marcbradshaw.net',
        'to'     => 'marc@fastmail.com',
    });

    stop_milter();

    return;
}

1;
