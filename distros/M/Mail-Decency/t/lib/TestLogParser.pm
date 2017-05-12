package TestLogParser;

use strict;
use TestMisc;
use Mail::Decency::LogParser;
use FindBin qw/ $Bin /;
use Test::More;
use base qw/ Exporter /;

sub create {
    return TestMisc::create_server( 'Mail::Decency::LogParser', 'log-parser', {
        syslog => {
            style => "Postfix",
            file => "$Bin/data/test.log"
        }
    } );
}


sub init_log_file {
    open my $fh, ">", "$Bin/data/test.log";
    close $fh;
}

1;
