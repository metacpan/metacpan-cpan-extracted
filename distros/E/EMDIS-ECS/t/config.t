#!/usr/bin/perl -w
#
# Copyright (C) 2002-2016 National Marrow Donor Program. All rights reserved.

use strict;
use File::Copy qw(copy);
use File::Spec::Functions qw(catdir catfile);
use Test;
use vars qw($cfg $datadir $tmpcfg);
use FindBin;
use lib "$FindBin::Bin";
require 'setup';

# print test plan before loading modules
BEGIN { plan(tests => 164); }
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

# [23..78] Read minimal good config file
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
ok($cfg->INBOX_PROTOCOL eq 'POP3');
ok($cfg->INBOX_HOST eq 'mail');
ok($cfg->INBOX_TIMEOUT == 60);
ok($cfg->INBOX_DEBUG == 0);
ok($cfg->INBOX_USE_SSL eq 'NO');
ok($cfg->INBOX_MAX_MSG_SIZE == 1048576);
ok($cfg->OPENPGP_CMD_ENCRYPT eq '/usr/local/bin/gpg --armor --batch ' .
        '--charset ISO-8859-1 --force-mdc --logger-fd 1 --openpgp ' .
            '--output __OUTPUT__ --passphrase-fd 0 --quiet ' .
                '--recipient __RECIPIENT__ --recipient __SELF__ --yes ' .
                    '--sign --local-user __SELF__ --encrypt __INPUT__');
ok($cfg->OPENPGP_CMD_DECRYPT eq '/usr/local/bin/gpg --batch ' .
        '--charset ISO-8859-1 --logger-fd 1 --openpgp --output __OUTPUT__ ' .
            '--passphrase-fd 0 --quiet --yes --decrypt __INPUT__');
ok($cfg->PGP2_CMD_ENCRYPT eq '/usr/local/bin/pgp +batchmode +verbose=0 ' .
        '+force +CharSet=latin1 +ArmorLines=0 -o __OUTPUT__ ' .
            '-u __SELF__ -eats __INPUT__ __RECIPIENT__ __SELF__');
ok($cfg->PGP2_CMD_DECRYPT eq '/usr/local/bin/pgp +batchmode +verbose=0 ' .
        '+force +CharSet=latin1 -o __OUTPUT__ __INPUT__');
# derived values
ok($cfg->ECS_TMP_DIR =~ /tmp$/);
ok($cfg->ECS_DRP_DIR =~ /maildrop$/);
ok($cfg->ECS_MBX_DIR =~ /mboxes$/);
ok($cfg->ECS_MBX_IN_DIR =~ /in$/);
ok($cfg->ECS_MBX_IN_FML_DIR =~ /in_fml$/);
ok($cfg->ECS_MBX_OUT_DIR =~ /out$/);
ok($cfg->ECS_MBX_TRASH_DIR =~ /trash$/);
ok($cfg->ECS_MBX_STORE_DIR =~ /store$/);

# [80..82] Read config file with known errors
copy catfile($datadir, '03-ecs.cfg'), $tmpcfg
    or die 'copy failed';
$cfg = new EMDIS::ECS::Config($tmpcfg);
ok(not ref $cfg);
ok($cfg =~ /Unexpected input \'BOGUS\' at .+ecs.cfg line 17/);
ok($cfg =~ /Error\(s\) encountered while attempting to process .+ecs.cfg/);

# [83..93] Read config file with known errors
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
ok($cfg =~ /Error\(s\) detected in configuration file .+ecs.cfg/);
ok($cfg =~ /Fatal configuration error\(s\) encountered./);

# [94..97] Read config file with known errors
copy catfile($datadir, '05-ecs.cfg'), $tmpcfg
    or die 'copy failed';
$cfg = new EMDIS::ECS::Config($tmpcfg);
ok(not ref $cfg);
ok($cfg =~ /Unrecognized INBOX_PROTOCOL:  PIGEON/);
ok($cfg =~ /Error\(s\) detected in configuration file .+ecs.cfg/);
ok($cfg =~ /Fatal configuration error\(s\) encountered./);

# [98..156] Read error-free config file
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

exit 0;
