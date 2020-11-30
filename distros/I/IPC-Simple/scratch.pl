#!/ursr/bin/env perl

use strict;
use warnings;

my $pid = fork;

unless ($pid) {
  exec 'perl', '-E', '$SIG{TERM} = sub{ print "TERM\n"; exit 0 }; sleep 1 while 1';
}

waitpid $pid, 0;
