#!/usr/bin/perl -w
use strict;

use File::Path;
use File::Slurp;
use Test::More tests => 24;

use Labyrinth::Audit;

my @levels = ($LOG_LEVEL_DEBUG, $LOG_LEVEL_INFO, $LOG_LEVEL_WARN, $LOG_LEVEL_ERROR);
my $dir = 't/logs';

mkpath($dir);

for my $level (@levels) {
    my $file = "t/logs/test-$level.log";
    SetLogFile(	FILE   => $file, 
				USER   => 'labyrinth', 
				LEVEL  => $level,
				CLEAR  => 1,
				CALLER => 1);

    LogRecord(undef, 'A test at the default level');
    LogRecord($level, 'A test at the right level');
    LogError('An Error test');
    LogWarning('A Warn test');
    LogInfo('An Info test');
    LogDebug('A Debug test');

    my $text = read_file($file);

    like($text,qr/\[$level\] A test at the right level/);

    if($level >= $LOG_LEVEL_ERROR)  {   like($text,qr/\[1\] An Error test/) }
    else                            { unlike($text,qr/\[1\] An Error test/) }
    if($level >= $LOG_LEVEL_WARN)   {   like($text,qr/\[2\] A Warn test/)   }
    else                            { unlike($text,qr/\[2\] A Warn test/)   }
    if($level >= $LOG_LEVEL_INFO)   {   like($text,qr/\[3\] An Info test/)  }
    else                            { unlike($text,qr/\[3\] An Info test/)  }
    if($level >= $LOG_LEVEL_DEBUG)  {   like($text,qr/\[4\] A Debug test/)  }
    else                            { unlike($text,qr/\[4\] A Debug test/)  }
    if($level >= $LOG_LEVEL_DEBUG)  {   like($text,qr/\[4\] A test at the default level/)  }
    else                            { unlike($text,qr/\[4\] A test at the default level/)  }
}

rmtree($dir);
