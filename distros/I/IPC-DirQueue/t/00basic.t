#!/usr/bin/perl -w

use Test; BEGIN { plan tests => 3 };

use lib '../lib'; if (-d 't') { chdir 't'; }
use IPC::DirQueue;
use File::Path;

rmtree ("log");
ok mkdir ("log");
ok mkdir ("log/qdir");
my $bq = IPC::DirQueue->new({ dir => 'log/qdir' });
ok ($bq);
