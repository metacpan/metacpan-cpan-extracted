#!/usr/bin/perl -w
#
# Copyright (C) 2002-2018 National Marrow Donor Program. All rights reserved.

use strict;
use Test;
use File::Spec::Functions qw(catdir catfile);
use vars qw(@arr $datadir @lt $msg $time);
use FindBin;
use lib "$FindBin::Bin";
require 'setup';

# print test plan before loading modules
BEGIN { plan(tests => 75); }
use EMDIS::ECS qw(:ALL);

# [1] Was module successfully loaded?
ok(1);

# use platform independent method to compute name of "t/data" directory
$datadir = catdir('t', 'data');

# redirect STDERR to STDOUT (suppress STDERR output during "make test")
open STDERR, ">&STDOUT" or die "Unable to dup STDOUT: $!\n";
select STDERR; $| = 1;   # make unbuffered
select STDOUT; $| = 1;   # make unbuffered

# [2..27] some easy ones
ok('"aaa' eq dequote('"aaa'));
ok('aaa"' eq dequote('aaa"'));
ok('aaa' eq dequote('"aaa"'));
ok("'aaa" eq dequote("'aaa"));
ok("aaa'" eq dequote("aaa'"));
ok("aaa" eq dequote("'aaa'"));
ok(not ecs_is_configured());
$time = time();
@lt = localtime($time);
$lt[5] += 1900;
$lt[4] += 1;
ok(format_datetime($time) eq
   sprintf("%04d-%02d-%02d %02d:%02d:%02d", @lt[5,4,3,2,1,0]));
ok(format_datetime($time, "%04d.%02d.%02d-%02d.%02d.%02d") eq
   sprintf("%04d.%02d.%02d-%02d.%02d.%02d", @lt[5,4,3,2,1,0]));
ok('' eq trim(''));
ok('a' eq trim(' a'));
ok('a' eq trim('a '));
ok('a' eq trim(' a '));
ok('aaaaa' eq trim('      aaaaa       '));
ok(valid_encr_typ('PGP2'));
ok(valid_encr_typ('PGP2-verify'));
ok(valid_encr_typ('OpenPGP'));
ok(valid_encr_typ('OpenPGP-verify'));
ok(is_yes('yEs'));
ok(is_yes('tRue'));
ok(not is_yes('nO'));
ok(not is_yes('faLse'));
ok(is_no('nO'));
ok(is_no('faLse'));
ok(not is_no('yEs'));
ok(not is_no('tRue'));

# [28..43] "ECS has not been configured"
$msg = "ECS has not been configured";
ok(log(0, "error text") =~ /$msg/);
ok(log_debug("error text") =~ /$msg/);
ok(log_info("error text") =~ /$msg/);
ok(log_warn("error text") =~ /$msg/);
ok(log_error("error text") =~ /$msg/);
ok(log_fatal("error text") =~ /$msg/);
ok(read_ecs_message_id("filename") =~ /$msg/);
ok(send_admin_email("error description") =~ /$msg/);
ok(send_ecsmsg_email("node_id", "seq_num", "message_body") =~ /$msg/);
ok(send_email("recipient", "subject", "body") =~ /$msg/);
ok(send_encrypted_email("encr_typ", "encr_recip", "recipient", "subject",
                        "body") =~ /$msg/);
ok(format_msg_filename("node_id", "seq_num") =~ /$msg/);
ok(openpgp_decrypt("infile", "outfile", "reqdsig") =~ /$msg/);
ok(openpgp_encrypt("infile", "outfile", "recipient") =~ /$msg/);
ok(pgp2_decrypt("infile", "outfile", "reqdsig") =~ /$msg/);
ok(pgp2_encrypt("infile", "outfile", "recipient") =~ /$msg/);
#ok(check_pid() =~ /$msg/);
#ok(save_pid() =~ /$msg/);

# [] aaaaa
#ok('AA_BB_0000012345.msg' eq format_msg_filename('AA', 'BB', 12345));

# [44..75] read_ecs_message_id
require EMDIS::ECS::Config;
$ECS_CFG = { MAIL_MRK => 'EMDIS' };
bless $ECS_CFG, 'EMDIS::ECS::Config';
$EMDIS::ECS::configured = 1;
@arr = read_ecs_message_id(catfile($datadir, 'AA_meta.msg'));
ok(scalar(@arr) == 4);
ok($arr[0] eq 'AA');
ok(not defined $arr[1]);
ok(not defined $arr[2]);
ok(not defined $arr[3]);
@arr = read_ecs_message_id(catfile($datadir, 'AA_01.msg'));
ok(scalar(@arr) == 4);
ok($arr[0] eq 'AA');
ok($arr[1] eq '01');
ok($arr[2] == 1);
ok($arr[3] == 1);
@arr = read_ecs_message_id(catfile($datadir, 'AA_02.msg'));
ok(scalar(@arr) == 4);
ok($arr[0] eq 'AA');
ok($arr[1] eq '02');
ok($arr[2] == 1);
ok($arr[3] == 1);
@arr = read_ecs_message_id(catfile($datadir, 'A1_01.msg'));
ok(scalar(@arr) == 4);
ok($arr[0] eq 'A1');
ok($arr[1] eq '01');
ok($arr[2] == 1);
ok($arr[3] == 1);
@arr = read_ecs_message_id(catfile($datadir, 'AAA_01.msg'));
ok(scalar(@arr) == 4);
ok($arr[0] eq 'AAA');
ok($arr[1] eq '01');
ok($arr[2] == 1);
ok($arr[3] == 1);
@arr = read_ecs_message_id(catfile($datadir, 'AA_01_32_47.msg'));
ok(scalar(@arr) == 4);
ok($arr[0] eq 'AA');
ok($arr[1] eq '01');
ok($arr[2] == 32);
ok($arr[3] == 47);
@arr = read_ecs_message_id(catfile($datadir, 'non_ecs.msg'));
ok(scalar(@arr) == 0);
@arr = read_ecs_message_id(catfile($datadir, 'non_ecs_2.msg'));
ok(scalar(@arr) == 0);
