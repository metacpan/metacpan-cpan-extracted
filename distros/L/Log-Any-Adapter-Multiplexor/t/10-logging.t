#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Log::Any '$log';
use File::Temp 'tempfile';

use Test::More qw 'no_plan';                     


BEGIN {
    use_ok ('Log::Any::Adapter::Multiplexor');
}

my ($FH, $log_temp_file) = tempfile();
binmode($FH, ":utf8");

my $multiplexor = Log::Any::Adapter::Multiplexor->new(
                                                        $log,
                                                        'info'  => ['Log::Any::Adapter::Stdout'],
                                                        'error' => ['Log::Any::Adapter::File', $log_temp_file]
                                                    );
#Test output in file                                                    
my $message = 'Test file log message';
$log->error($message);
like(<$FH>, "/$message/", 'Output in file');
close $FH;

#Test output to STDOUT
my ($FS, $stdout_temp_file) = tempfile();
open (STDOUT, ">>", $stdout_temp_file);
$message = 'Test STDOUT log message';
$log->info($message);
like(<$FS>, "/$message/", 'Output in stdout');
close $FS;

#Create warning log level
my ($FW, $warn_temp_file) = tempfile();
$multiplexor->set_logger('warning', 'Log::Any::Adapter::File', $warn_temp_file);
$message = 'Test warning log message in file';
$log->warning($message);
like(<$FW>, "/$message/", 'Output warning message in file');
close $FW;

#Test combine
my ($FH1, $debug_temp_file1) = tempfile();
my ($FH2, $debug_temp_file2) = tempfile();
$message = 'Test combine log message in file';
$multiplexor->set_logger('debug', 'Log::Any::Adapter::File', $debug_temp_file1);
$multiplexor->set_logger('info', 'Log::Any::Adapter::File', $debug_temp_file2);
$multiplexor->combine('debug', 'info');
$log->info($message);
like(<$FH1>, "/$message/", 'Output via combine in file1');
like(<$FH2>, "/$message/", 'Output via combine in file2');

#Test uncombine
$message = 'Test uncombine log message in file';
$multiplexor->uncombine();
$log->debug($message);
#Message must be in $FH1, but not in $FH2
like(<$FH1>, "/$message/", 'Output via uncombine in file');
unlike(<$FH2>, "/$message/", 'No output uncombine in file');

