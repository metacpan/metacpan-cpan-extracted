#!/usr/bin/perl -w

use constant RUNNING_ON_WINDOWS => ($^O =~ /^(?:mswin|dos|os2)/oi);

use Test; BEGIN { plan tests => (RUNNING_ON_WINDOWS ? 0 : 7); };
exit if RUNNING_ON_WINDOWS;

use lib '../lib'; if (-d 't') { chdir 't'; }
use IPC::DirQueue;

use lib '.'; use lib 't'; use Util;

find_perl_path();

mkdir ("log");
mkdir ("log/qdir");

open (OUT, ">log/test.dat"); print OUT "This is a test\n"; close OUT;

my $runpfx = "$perl_path -I../lib";

run ("$runpfx ../dq-submit --dir log/qdir log/test.dat");
ok ($? >> 8 == 0);
run ("$runpfx ../dq-submit --dir log/qdir log/test.dat");
ok ($? >> 8 == 0);
run ("$runpfx ../dq-submit --dir log/qdir log/test.dat");
ok ($? >> 8 == 0);
run ("$runpfx ../dq-submit --dir log/qdir log/test.dat");
ok ($? >> 8 == 0);

run ("$runpfx ../dq-list --dir log/qdir");
ok ($? >> 8 == 0);

run ("$runpfx ../dq-deque --dir log/qdir cat");
ok ($? >> 8 == 0);

run ("$runpfx ../dq-server --njobs 3 --dir log/qdir cat");
ok ($? >> 8 == 0);

exit;

sub run {
  print "[".join(' ',@_)."]\n";
  system @_;
}
