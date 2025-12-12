#!/usr/bin/env perl
#
# Test the folder manager
#

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Manager;

use Test::More tests => 14;
use File::Spec;

use Log::Report;

my $new  = File::Spec->catfile($folderdir, 'create');
unlink $new;

my $manager = Mail::Box::Manager->new
 ( log      => 'NOTICES'
 , trace    => 'NONE'
 );

my $folder  = $manager->open(folder => $src, lock_type => 'NONE', extract => 'LAZY');

ok(defined $folder,                              'open folder');
isa_ok($folder, 'Mail::Box::Mbox');

my $second = try { $manager->open(folder => $src, lock_type => 'NONE') };
ok(!defined $second,                             'open same folder fails');

my @e1 = $@->exceptions;
cmp_ok(@e1, "==", 1,                             'mgr noticed double');

my $error = $e1[-1]->message;
$error =~ s#mbox\.win#mbox.src#g;  # Windows mutulated path
$error =~ s#\\#/#g;

is($error, "folder t/folders/mbox.src is already open.");
cmp_ok($manager->openFolders, "==", 1,           'only one folder open');

undef $second;
cmp_ok($manager->openFolders, "==", 1,           'second closed, still one open');

my $n = try { $manager->open(
	folder       => $new,
	folderdir    => 't',
	type         => 'mbox',
	lock_type    => 'NONE',
	) };
ok(! -f $new,                                   'folder file does not exist');
ok(! defined $n,                                'open non-ex does not succeed');

my @e2 = $@->exceptions;
cmp_ok(@e2, "==", 1,                           'new warning');
$e2[-1] =~ s#\\#/#g;  # Windows
is($e2[-1], "error: folder file t/folders/create does not exist.\n");

my $p = $manager->open(
	folder       => $new,
	lock_type    => 'NONE',
	type         => 'mbox',
	create       => 1,
	access       => 'w',
);

ok(defined $p,                                   'open non-existing with create');
ok(-f $new,                                      'new folder created');
ok(-z $new,                                      'new folder is empty');

unlink $new;
exit 0;
