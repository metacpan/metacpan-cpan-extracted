###
### $Release: 0.0100 $
### $Copyright: copyright(c) 2009-2011 kuwata-lab.com all rights reserved. $
### $License: MIT License $
###

use strict;
use warnings;


package Kook::Misc;
use Exporter 'import';
our @EXPORT_OK = ('_debug', '_trace', '_report_msg', '_report_cmd');
use Data::Dumper;

use Kook::Config;

sub _debug {
    my ($msg, $depth, $level) = @_;
    $level = 1 if ! $level;
    if ($Kook::Config::DEBUG_LEVEL >= $level) {
        print $Kook::Config::DEBUG_PROMPT;
        print '+' x $depth, ' ' if $depth;
        print $msg;
        print "\n" unless substr($msg, -1) eq "\n";
    }
}

sub _trace {
    my ($msg, $depth) = @_;
    _debug($msg, $depth, 2);
}

sub _report_msg {
    my ($msg, $level) = @_;
    if ($Kook::Config::VERBOSE) {
        print $Kook::Config::MESSAGE_PROMPT;
        print '*' x $level, ' ' if $level;
        print $msg;
        print "\n" unless substr($msg, -1) eq "\n";
    }
}

sub _report_cmd {
    my ($cmd) = @_;
    if ($Kook::Config::VERBOSE) {
        print $Kook::Config::COMMAND_PROMPT;
        print $cmd;
        print "\n" unless substr($cmd, -1) eq "\n";
    }
}


1;
