#!/usr/bin/perl -w
#
# Copyright (C) 2002-2025 National Marrow Donor Program. All rights reserved.

use strict;
use File::Copy qw(copy);
use File::Spec::Functions qw(catdir catfile);
use Test;
use vars qw($cfg $datadir $tmpcfg);
use FindBin;
use lib "$FindBin::Bin";
require 'setup';

# print test plan before loading modules
BEGIN { plan(tests => 200); }
use EMDIS::ECS::Config;

# [1] Was module successfully loaded?
ok(1);

# [2] Is module version consistent?
require EMDIS::ECS;
ok($EMDIS::ECS::VERSION == $EMDIS::ECS::Config::VERSION);

# use platform independent method to compute name of "t/data" directory
$datadir = catdir('t', 'data');

# [3..4] Read non-existent config file
$cfg = new EMDIS::ECS::Config(catfile($datadir, '00-ecs.cfg'));
ok(not ref $cfg);
ok($cfg =~ /Unable to open config file/);

# [5..22] Read empty config file
$cfg = new EMDIS::ECS::Config(catfile($datadir, '01-ecs.cfg'));
ok(not ref $cfg);
ok($cfg =~ /THIS_NODE not defined./);
ok($cfg =~ /ADM_ADDR not defined./);
ok($cfg =~ /SMTP_DOMAIN not defined./);
ok($cfg =~ /SMTP_FROM not defined./);
ok($cfg =~ /INBOX_USERNAME not defined./);
ok($cfg =~ /INBOX_PASSWORD not defined./);
ok($cfg =~ /No encryption method configured./);
ok($cfg =~ /ECS_TMP_DIR \([^\n]+tmp\) directory not found./);
ok($cfg =~ /ECS_DRP_DIR \([^\n]+maildrop\) directory not found./);
ok($cfg =~ /ECS_MBX_DIR \([^\n]+mboxes\) directory not found./);
ok($cfg =~ /ECS_MBX_IN_DIR \([^\n]+in\) directory not found./);
ok($cfg =~ /ECS_MBX_IN_FML_DIR \([^\n]+in_fml\) directory not found./);
ok($cfg =~ /ECS_MBX_OUT_DIR \([^\n]+out\) directory not found./);
ok($cfg =~ /ECS_MBX_TRASH_DIR \([^\n]+trash\) directory not found./);
ok($cfg =~ /ECS_MBX_STORE_DIR \([^\n]+store\) directory not found./);
ok($cfg =~ /Error\(s\) detected in configuration file .+01-ecs.cfg/);
ok($cfg =~ /Fatal configuration error\(s\) encountered./);

# [23..88] Read minimal good config file
copy catfile($datadir, '02-ecs.cfg'), $tmpcfg
    or die 'copy failed';
$cfg = new EMDIS::ECS::Config($tmpcfg);
die "new EMDIS::ECS::Config failed: $cfg"
    unless ref $cfg;
ok(1);
ok($cfg->THIS_NODE eq 'YY');
ok($cfg->ADM_ADDR eq 'blackhole@emdis.aaaaa');
ok($cfg->ADAPTER_CMD =~ /\/adapter\/process_emdis.sh .+ \$1$/);
ok($cfg->SMTP_DOMAIN eq 'emdis.aaaaa');
ok($cfg->SMTP_FROM eq 'emdis@emdis.aaaaa');
ok($cfg->INBOX_USERNAME eq 'emdis');
ok($cfg->INBOX_PASSWORD eq 'aaaaa');
ok($cfg->GPG_HOMEDIR =~ /\/gnupg$/);
ok($cfg->GPG_KEYID eq '0xAAAAAAAA');
ok($cfg->GPG_PASSPHRASE eq 'aaaaa');
# default values:
ok($cfg->MSG_PROC =~ /ecs_proc_msg$/);
ok($cfg->MAIL_MRK eq 'EMDIS');
ok($cfg->T_CHK == 7200);
ok($cfg->T_SCN == 3600);
ok($cfg->ERR_FILE =~ /config.t.err$/);
ok($cfg->LOG_FILE =~ /config.t.log$/);
ok($cfg->M_MSG_PROC =~ /ecs_proc_meta$/);
ok($cfg->BCK_DIR eq 'NONE');
ok($cfg->ACK_THRES eq '100');
ok($cfg->ECS_BIN_DIR =~ /t$/);
ok($cfg->ECS_DAT_DIR =~ /tmp$/);
ok(not defined $cfg->ECS_TO_DIR);
ok(not defined $cfg->ECS_FROM_DIR);
ok($cfg->ECS_DEBUG eq '0');
ok($cfg->NODE_TBL =~ /node_tbl.dat$/);
ok($cfg->NODE_TBL_LCK =~ /node_tbl.lock$/);
ok($cfg->T_ADM_DELAY == 0);
ok($cfg->T_ADM_REMIND == 86400);
ok($cfg->T_MSG_PROC == 3600);
ok($cfg->ALWAYS_ACK eq 'NO');
ok($cfg->GNU_TAR eq '/usr/bin/tar');
ok($cfg->T_RESEND_DELAY == 14400);
ok($cfg->LOG_LEVEL == 1);
ok($cfg->MAIL_LEVEL == 2);
ok($cfg->MSG_PART_SIZE_DFLT == 1073741824);
ok($cfg->SMTP_HOST eq 'smtp');
ok($cfg->SMTP_TIMEOUT == 60);
ok($cfg->SMTP_DEBUG == 0);
ok($cfg->SMTP_USE_SSL eq 'NO');
ok($cfg->SMTP_PORT == 25);
ok($cfg->INBOX_PROTOCOL eq 'POP3');
ok($cfg->INBOX_HOST eq 'mail');
ok($cfg->INBOX_TIMEOUT == 60);
ok($cfg->INBOX_DEBUG == 0);
ok($cfg->INBOX_USE_SSL eq 'NO');
ok($cfg->INBOX_PORT == 110);
ok($cfg->INBOX_MAX_MSG_SIZE == 1048576);
ok($cfg->OPENPGP_CMD_ENCRYPT eq '/usr/local/bin/gpg --armor --batch ' .
    '--charset ISO-8859-1 --force-mdc --logger-fd 1 --openpgp ' .
    '--output __OUTPUT__ --pinentry-mode loopback --passphrase-fd 0 ' .
    '--quiet --recipient __RECIPIENT__ --recipient __SELF__ --yes ' .
    '--sign --local-user __SELF__ --encrypt __INPUT__');
ok($cfg->OPENPGP_CMD_DECRYPT eq '/usr/local/bin/gpg --batch ' .
    '--charset ISO-8859-1 --logger-fd 1 --openpgp --output __OUTPUT__ ' .
    '--pinentry-mode loopback --passphrase-fd 0 --quiet --yes ' .
    '--decrypt __INPUT__');
ok($cfg->PGP2_CMD_ENCRYPT eq '/usr/local/bin/pgp +batchmode +verbose=0 ' .
    '+force +CharSet=latin1 +ArmorLines=0 -o __OUTPUT__ ' .
    '-u __SELF__ -eats __INPUT__ __RECIPIENT__ __SELF__');
ok($cfg->PGP2_CMD_DECRYPT eq '/usr/local/bin/pgp +batchmode +verbose=0 ' .
    '+force +CharSet=latin1 -o __OUTPUT__ __INPUT__');
ok(not defined $cfg->INBOX_OAUTH_TOKEN_CMD);
ok($cfg->INBOX_OAUTH_TOKEN_CMD_TIMELIMIT == 60);
ok($cfg->INBOX_OAUTH_SASL_MECHANISM eq 'XOAUTH2 OAUTHBEARER');
ok(not defined $cfg->SMTP_OAUTH_TOKEN_CMD);
ok($cfg->SMTP_OAUTH_TOKEN_CMD_TIMELIMIT == 60);
ok($cfg->SMTP_OAUTH_SASL_MECHANISM eq 'XOAUTH2 OAUTHBEARER');
# derived values
ok($cfg->ECS_TMP_DIR =~ /tmp$/);
ok($cfg->ECS_DRP_DIR =~ /maildrop$/);
ok($cfg->ECS_MBX_DIR =~ /mboxes$/);
ok($cfg->ECS_MBX_IN_DIR =~ /in$/);
ok($cfg->ECS_MBX_IN_FML_DIR =~ /in_fml$/);
ok($cfg->ECS_MBX_OUT_DIR =~ /out$/);
ok($cfg->ECS_MBX_TRASH_DIR =~ /trash$/);
ok($cfg->ECS_MBX_STORE_DIR =~ /store$/);

# [87..91] Read config file with known errors
copy catfile($datadir, '03-ecs.cfg'), $tmpcfg
    or die 'copy failed';
$cfg = new EMDIS::ECS::Config($tmpcfg);
ok(not ref $cfg);
ok($cfg =~ /Unexpected input \'BOGUS\' at .+ecs.cfg line 17/);
ok($cfg =~ /Error\(s\) encountered while attempting to process .+ecs.cfg/);

# [92..105] Read config file with known errors
copy catfile($datadir, '04-ecs.cfg'), $tmpcfg
    or die 'copy failed';
$cfg = new EMDIS::ECS::Config($tmpcfg);
ok(not ref $cfg);
ok($cfg =~ /GPG_KEYID not defined, but is required for OpenPGP/);
ok($cfg =~ /GPG_PASSPHRASE not defined, but is required for OpenPGP/);
ok($cfg =~ /PGP_KEYID not defined, but is required for PGP2/);
ok($cfg =~ /PGP_PASSPHRASE not defined, but is required for PGP2/);
ok($cfg =~ /T_CHK \(0\) is required to be greater than zero./);
ok($cfg =~ /T_SCN \(0\) is required to be greater than zero./);
ok($cfg =~ /T_ADM_REMIND \(0\) is required to be greater than zero./);
ok($cfg =~ /T_MSG_PROC \(0\) is required to be greater than zero./);
ok($cfg =~ /Unrecognized ALWAYS_ACK \(YES\/NO\) value:  OK/);
ok($cfg =~ /INBOX_USE_SSL and INBOX_USE_STARTTLS are both selected, but they are mutually exclusive./);
ok($cfg =~ /SMTP_USE_SSL and SMTP_USE_STARTTLS are both selected, but they are mutually exclusive./);
ok($cfg =~ /Error\(s\) detected in configuration file .+ecs.cfg/);
ok($cfg =~ /Fatal configuration error\(s\) encountered./);

# [106..113] Read config file with known errors
copy catfile($datadir, '05-ecs.cfg'), $tmpcfg
    or die 'copy failed';
$cfg = new EMDIS::ECS::Config($tmpcfg);
ok(not ref $cfg);
ok($cfg =~ /Unrecognized INBOX_USE_SSL \(YES\/NO\) value:  YESS/);
ok($cfg =~ /Unrecognized INBOX_USE_STARTTLS \(YES\/NO\) value:  NOO/);
ok($cfg =~ /Unrecognized SMTP_USE_SSL \(YES\/NO\) value:  YEA/);
ok($cfg =~ /Unrecognized SMTP_USE_STARTTLS \(YES\/NO\) value:  NAY/);
ok($cfg =~ /Unrecognized INBOX_PROTOCOL:  PIGEON/);
ok($cfg =~ /Error\(s\) detected in configuration file .+ecs.cfg/);
ok($cfg =~ /Fatal configuration error\(s\) encountered./);

# [114..179] Read error-free config file
copy catfile($datadir, '06-ecs.cfg'), $tmpcfg
    or die 'copy failed';
$cfg = new EMDIS::ECS::Config($tmpcfg);
die "new EMDIS::ECS::Config failed: $cfg"
    unless ref $cfg;
ok(1);
ok($cfg->THIS_NODE eq 'YY');
ok($cfg->ADM_ADDR eq 'blackhole@emdis.aaaaa');
ok($cfg->ADAPTER_CMD eq 'foobar');
ok($cfg->SMTP_DOMAIN eq 'emdis.aaaaaa');
ok($cfg->SMTP_FROM eq 'emdis@emdis.aaaaaa');
ok($cfg->INBOX_USERNAME eq 'emdis');
ok($cfg->INBOX_PASSWORD eq 'aaaaaaaa');
ok($cfg->GPG_HOMEDIR =~ /\/gnupg$/);
ok($cfg->GPG_KEYID eq '0xAAAAAAAAAA');
ok($cfg->GPG_PASSPHRASE eq 'aaaaaaaaa');
ok($cfg->PGP_HOMEDIR =~ /\/pgp$/);
ok($cfg->PGP_KEYID eq '0xAAAAAAAAAAA');
ok($cfg->PGP_PASSPHRASE eq 'aaaaaaaaaaa');
ok($cfg->ECS_TO_DIR =~ /to_dir$/);
ok($cfg->ECS_FROM_DIR =~ /from_dir$/);
ok($cfg->LOG_LEVEL == 0);
ok($cfg->MAIL_LEVEL == 1);
# default values:
ok($cfg->MSG_PROC =~ /ecs_proc_msg$/);
ok($cfg->MAIL_MRK eq 'EMDIS');
ok($cfg->T_CHK == 7201);
ok($cfg->T_SCN == 3601);
ok($cfg->ERR_FILE =~ /config.t.err$/);
ok($cfg->LOG_FILE =~ /config.t.log$/);
ok($cfg->M_MSG_PROC =~ /ecs_proc_meta$/);
ok($cfg->BCK_DIR eq 'NONE');
ok($cfg->ACK_THRES == 101);
ok($cfg->ECS_BIN_DIR =~ /t$/);
ok($cfg->ECS_DAT_DIR =~ /tmp$/);
ok($cfg->ECS_DEBUG == 11);
ok($cfg->NODE_TBL =~ /node_tbl.dat$/);
ok($cfg->NODE_TBL_LCK =~ /node_tbl.lck$/);
ok($cfg->T_ADM_DELAY == 372801);
ok($cfg->T_ADM_REMIND == 186401);
ok($cfg->T_MSG_PROC == 13601);
ok($cfg->ALWAYS_ACK eq 'YES');
ok($cfg->GNU_TAR eq '/usr/local/bin/tar');
ok($cfg->T_RESEND_DELAY == 14401);
ok($cfg->MSG_PART_SIZE_DFLT == 1048568);
ok($cfg->SMTP_HOST eq 'cygnus');
ok($cfg->SMTP_PORT == 465);
ok($cfg->SMTP_TIMEOUT == 161);
ok($cfg->SMTP_DEBUG == 12);
ok($cfg->SMTP_USE_SSL eq 'YES');
ok($cfg->SMTP_USERNAME eq 'eemdis');
ok($cfg->SMTP_PASSWORD eq 'zzzz');
ok($cfg->INBOX_PROTOCOL eq 'IMAP');
ok($cfg->INBOX_HOST eq 'imap');
ok($cfg->INBOX_PORT == 993);
ok($cfg->INBOX_TIMEOUT == 162);
ok($cfg->INBOX_DEBUG == 13);
ok($cfg->INBOX_FOLDER eq 'IINBOXX');
ok($cfg->INBOX_USE_SSL eq 'YES');
ok($cfg->INBOX_MAX_MSG_SIZE == 11048577);
ok($cfg->OPENPGP_CMD_ENCRYPT eq '/usr/local/bin/gpg --armor ' .
   '--logger-fd 1 --output __OUTPUT__ --passphrase-fd 0 ' .
   '--recipient __RECIPIENT__ --recipient __SELF__ --yes ' .
   '--sign --encrypt __INPUT__');
ok($cfg->OPENPGP_CMD_DECRYPT eq '/usr/local/bin/gpg ' .
   '--logger-fd 1 --output __OUTPUT__ --passphrase-fd 0 --decrypt __INPUT__');
ok($cfg->PGP2_CMD_ENCRYPT eq '/usr/local/bin/pgp ' .
        '-o __OUTPUT__ -eats __INPUT__ __RECIPIENT__ __SELF__');
ok($cfg->PGP2_CMD_DECRYPT eq '/usr/local/bin/pgp ' .
        '-o __OUTPUT__ __INPUT__');
# derived values
ok($cfg->ECS_TMP_DIR =~ /tmp$/);
ok($cfg->ECS_DRP_DIR =~ /tmp$/);
ok($cfg->ECS_MBX_DIR =~ /mboxes$/);
ok($cfg->ECS_MBX_IN_DIR =~ /in$/);
ok($cfg->ECS_MBX_IN_FML_DIR =~ /in_fml$/);
ok($cfg->ECS_MBX_OUT_DIR =~ /out$/);
ok($cfg->ECS_MBX_TRASH_DIR =~ /trash$/);
ok($cfg->ECS_MBX_STORE_DIR =~ /store$/);

# [180..194] Read minimal config file with AMQP settings added
copy catfile($datadir, '07-ecs.cfg'), $tmpcfg
    or die 'copy failed';
$cfg = new EMDIS::ECS::Config($tmpcfg, 1);  # using skip_val = 1
die "new EMDIS::ECS::Config failed: $cfg"
    unless ref $cfg;
ok(1);
ok($cfg->ENABLE_AMQP eq 'YES');
ok($cfg->AMQP_DEBUG_LEVEL eq '1');
ok($cfg->AMQP_RECV_TIMEOUT eq '1');
ok($cfg->AMQP_BROKER_URL eq 'amqps://amqp-broker:5671');
ok($cfg->AMQP_VHOST eq 'default');
ok($cfg->AMQP_ADDR_META eq 'emdis.aa.meta');
ok($cfg->AMQP_ADDR_MSG eq 'emdis.aa.msg');
ok($cfg->AMQP_ADDR_DOC eq 'emdis.aa.doc');
ok($cfg->AMQP_TRUSTSTORE eq 'test-ca.pem');
ok($cfg->AMQP_SSLCERT eq 'test-client.pem');
ok($cfg->AMQP_SSLKEY eq 'test-client-key.pem');
ok($cfg->AMQP_SSLPASS eq 'sslpass');
ok($cfg->AMQP_USERNAME eq 'emdis-aa');
ok($cfg->AMQP_PASSWORD eq 'saslpass');

# [195..197] Read minimal config file, using $ENV{envvar} pattern for INBOX_PASSWORD and GPG_PASSPHRASE
copy catfile($datadir, '08-ecs.cfg'), $tmpcfg
    or die 'copy failed';
# set values of environment variables referenced by config
my $prev_EMDIS_ECS_TEST_PWD_MBX = $ENV{EMDIS_ECS_TEST_PWD_MBX};
$ENV{EMDIS_ECS_TEST_PWD_MBX} = 'mbxpass';
my $prev_EMDIS_ECS_TEST_PWD_GPG = $ENV{EMDIS_ECS_TEST_PWD_GPG};
$ENV{EMDIS_ECS_TEST_PWD_GPG} = 'gpgpass';
# read config
$cfg = new EMDIS::ECS::Config($tmpcfg);
# restore previous values (if any) of environment variables
if(defined $prev_EMDIS_ECS_TEST_PWD_MBX) { $ENV{EMDIS_ECS_TEST_PWD_MBX} = $prev_EMDIS_ECS_TEST_PWD_MBX; }
else { delete($ENV{EMDIS_ECS_TEST_PWD_MBX}); }
if(defined $prev_EMDIS_ECS_TEST_PWD_GPG) { $ENV{EMDIS_ECS_TEST_PWD_GPG} = $prev_EMDIS_ECS_TEST_PWD_GPG; }
else { delete($ENV{EMDIS_ECS_TEST_PWD_GPG}); }
die "new EMDIS::ECS::Config failed: $cfg"
    unless ref $cfg;
ok(1);
ok($cfg->INBOX_PASSWORD eq 'mbxpass');
ok($cfg->GPG_PASSPHRASE eq 'gpgpass');

# [198..200] Read minimal config file, using $ENV{envvar} pattern for INBOX_PASSWORD and GPG_PASSPHRASE, but ENABLE_ENV_CONFIG = NO
copy catfile($datadir, '09-ecs.cfg'), $tmpcfg
    or die 'copy failed';
$cfg = new EMDIS::ECS::Config($tmpcfg);
ok(1);
ok($cfg->INBOX_PASSWORD eq '$ENV{EMDIS_ECS_TEST_PWD_MBX}');
ok($cfg->GPG_PASSPHRASE eq '$ENV{EMDIS_ECS_TEST_PWD_GPG}');

exit 0;
