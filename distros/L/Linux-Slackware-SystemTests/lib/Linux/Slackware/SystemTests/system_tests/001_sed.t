#!/usr/bin/perl

use strict;
use warnings;
use Test::Most 'die';
use File::Valet;

use lib "./lib";
use Linux::Slackware::SystemTests;

my $st = Linux::Slackware::SystemTests->new();

ok -x '/bin/sed',     'got /bin/sed';
ok -l '/usr/bin/sed', 'got symlink /usr/bin/sed';

# Copy the test file to the temp directory so we can modify it in place.
my ($ok, $target_file) = $st->init_work_file("001_sed.1.txt");
BAIL_OUT("init_work_file failed: $target_file") unless ($ok eq 'OK');

unlink("$target_file.out");
ok !-e "$target_file.out", "making sure output file does not exist" or BAIL_OUT("cannot continue with turd file $target_file.out in the way");

is system("/bin/sed '/i/d' $target_file > $target_file.out"), 0, "stripping i from $target_file";
ok rd_f("$target_file.out") eq "san\n", "target file content check";

unlink($target_file);
unlink("$target_file.out");

# zzapp -- should probably put more tests here

done_testing();
exit 0;
