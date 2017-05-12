#!perl -T

use strict;
use warnings;
use Test::More tests => 3;
use File::Temp qw(tempdir);

use Log::Dispatch::Dir;

#use lib './t';
#require 'testlib.pm';

my $dir = tempdir(CLEANUP=>0);
my $log;

# max_size
$log = new Log::Dispatch::Dir(name=>'dir1', min_level=>'info', dirname=>"$dir/dir1", max_size=>13, rotate_probability=>1);
$log->log_message(message=>101);
$log->log_message(message=>102);
$log->log_message(message=>103);
$log->log_message(message=>104);
$log->log_message(message=>105);
my @f = glob "$dir/dir1/*";
is(scalar(@f), 4, "rotate (max_size)");

# max_files
$log = new Log::Dispatch::Dir(name=>'dir2', min_level=>'info', dirname=>"$dir/dir2", max_files=>3, rotate_probability=>1);
$log->log_message(message=>101);
$log->log_message(message=>102);
$log->log_message(message=>103);
$log->log_message(message=>104);
@f = glob "$dir/dir2/*";
is(scalar(@f), 3, "rotate (max_files)");

# max_age
$log = new Log::Dispatch::Dir(name=>'dir3', min_level=>'info', dirname=>"$dir/dir3", max_age=>1, rotate_probability=>1);
$log->log_message(message=>101);
$log->log_message(message=>102);
$log->log_message(message=>103);
$log->log_message(message=>104);
sleep 2;
$log->log_message(message=>105);
@f = glob "$dir/dir3/*";
is(scalar(@f), 1, "rotate (max_age)");
