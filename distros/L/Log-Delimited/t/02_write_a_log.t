#!/usr/bin/perl -w

use strict;
use Test;

BEGIN { plan tests => 3}
use Log::Delimited;

my $tmp_dir = "/tmp/logs";
my $wipe_dir = !-e $tmp_dir;

my $log = Log::Delimited->new({
  log_cols => ['url', 'step', 'elapsed'],
  log_info =>  ['http://slap.com/cgi-bin/slow_script', 'step 1', '99993.0923'], 
  log_node => 'tmp_dir_for_log_delimited_dont_use.' . time,
  log_name => 'log_delimited_test',
});

$log->log;
my $size = -s $log->{log_filename};
ok($size);

$log->{log_info} =  ['http://slap.com/cgi-bin/slow_script', 'step 2', '8.3240']; 
$log->log;

my $size2 = -s $log->{log_filename};
ok($size2 > $size);

$log->wipe;

ok(!-e $log->{log_filename});

rmdir $log->{log_dir};
if($wipe_dir) {
  rmdir $tmp_dir
}
