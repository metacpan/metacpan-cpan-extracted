#!/usr/bin/perl -w

use Test; BEGIN { plan tests => 2 };

use lib '../lib'; if (-d 't') { chdir 't'; }
use IPC::DirQueue;
use File::Path;

mkdir ("log");
rmtree ("log/qdir");

my $bq = IPC::DirQueue->new({ dir => 'log/qdir' });
ok ($bq);

$bq->visit_all_jobs(sub { });
ok 1;

