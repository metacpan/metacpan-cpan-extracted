#!/usr/bin/env perl
#
# Collecting folders, without opening them

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Manage::User;
use Mail::Box::MH;

use Test::More tests => 72;


my @boxes =
 qw( a1
     a1/b1
     a1/b2
     a1/b2/c1
     a1/b2/c2
     a1/b2/c3
     a1/b2/c3/d1
     a1/b2/c3/d2
     a1/b3
     a2
     a3
   );

# Create the directory hierarchy

my $top = 'collect-test.tmp';
clean_dir($top);
mkdir $top or die "$top: $!";

foreach my $box (@boxes)
{   my $dir = "$top/$box";
    mkdir $dir or die "$dir: $!";
}

# Now create the user

my $id   = User::Identity->new('markov');
ok(defined $id,                              "Identity created");
isa_ok($id, 'User::Identity');

my $user = Mail::Box::Manage::User->new
 ( folderdir           => $top
 , identity            => $id
 , default_folder_type => 'mh'
 );

ok(defined $user,                            "User manager created");
isa_ok($user, "Mail::Box::Manager");
isa_ok($user, "Mail::Box::Manage::User");

is($user->defaultFolderType, 'Mail::Box::MH');

# Let's check the list of folders
my $f = $user->topfolder;
isa_ok($f, 'Mail::Box::Identity');

is($f->folderType, 'Mail::Box::MH');
is($f->location, $top);
is($f->manager, $user);
ok(! $f->onlySubfolders,                     "MH toplevel");

ok(!defined $f->collection('subfolders'),    "Laziness");

my @subnames = sort $f->subfolderNames;
ok(defined $f->collection('subfolders'),     "loaded");

cmp_ok(scalar(@subnames), '==', 3,           "Subfolder names found");
is($subnames[0], 'a1');
is($subnames[1], 'a2');
is($subnames[2], 'a3');

my @subs = sort {$a->name cmp $b->name} $f->subfolders;
cmp_ok(scalar(@subs), '==', 3,               "Subfolders found");

my $a1 = $subs[0];
isa_ok($a1, 'Mail::Box::Identity');
is($a1->name, 'a1');
is($a1->fullname, '=/a1');
is($a1->location, "$top/a1");

is($subs[1]->name, 'a2');
is($subs[1]->fullname, '=/a2');

is($subs[2]->name, 'a3');
is($subs[2]->fullname, '=/a3');

isa_ok($f, 'User::Identity::Item');

# One nested

ok(!defined $a1->collection('subfolders'),    "Laziness of a1");
my @a1names = sort $a1->subfolderNames;

ok(defined $a1->collection('subfolders'),     "loaded");
cmp_ok(scalar(@a1names), '==', 3,             "Subfolders a1 found");
is($a1names[0], 'b1');
is($a1names[1], 'b2');
is($a1names[2], 'b3');

my @a1subs = sort {$a->name cmp $b->name} $a1->subfolders;
cmp_ok(scalar(@a1subs), '==', 3,               "Subfolders found");
is($a1subs[1]->fullname, '=/a1/b2');

my @a1subs2 = $a1->subfolders->sorted;
ok(eq_array(\@a1subs, \@a1subs2),              "Auto-sort");

# get a subfolder at once

my $l0 = $f->folder();
ok(defined $l0,                                "Subfolder top");
isa_ok($l0, 'Mail::Box::Identity');
is($l0->fullname, "=");
is($l0->topfolder->name, '=');

my $l1 = $f->folder('a2');
ok(defined $l1,                                "Subfolder level 1");
isa_ok($l1, 'Mail::Box::Identity');
is($l1->fullname, "=/a2");
is($l1->topfolder->name, '=');

ok(!defined $f->folder('xx'),               "Subfolder level 1 fail");

my $l2 = $f->folder('a1', 'b3');
ok(defined $l2,                                "Subfolder level 2");
is($l2->fullname, "=/a1/b3");
is($l2->topfolder->name, '=');

my $l4 = $f->folder('a1', 'b2', 'c3', 'd1');
ok(defined $l4,                                "Subfolder level 4");
isa_ok($l4, 'Mail::Box::Identity');
is($l4->fullname, "=/a1/b2/c3/d1");
is($l4->topfolder->name, '=');

ok(! defined$f->folder('a1', 'b3', 'xx', 'yy'), "Subfolder level 3 fail");

# Walk the tree

my $count = 0;
$f->foreach( sub {$count++} );
cmp_ok($count, '==', @boxes+1,                 "Walk the tree");
                    # +1 for top folder

my @all;
sub catch_fn($)
{   my $fn = $_[0]->fullname;
    return if $fn eq '=';
    $fn =~ s!^\=/!!;
    push @all, $fn;
}
$f->foreach(\&catch_fn);
ok(eq_array(\@all, \@boxes),                   "Walk alphabetically");

#
# Test remove
#

my $c3 = $f->folder('a1', 'b2')->remove('c3');
ok(defined $c3,                                "Remove c3, found");
isa_ok($c3, 'Mail::Box::Identity');
is($c3->name, "c3");

my $c3d = $f->folder('a1', 'b2', 'c3');
ok(!defined $c3d);

my @a1b2names = sort $f->folder('a1', 'b2')->subfolderNames;
cmp_ok(scalar(@a1b2names), '==', 2,            "parent still exists");
is($a1b2names[0], 'c1');
is($a1b2names[1], 'c2');

#
# Test rename
#

my $x = $f->folder('a1', 'b2', 'c1');
ok(defined $x,                                "a1/b2/c1 exists");
my $dest = $f->folder('a3');
ok(defined $dest,                             "a3 exists");
my $y = $x->rename($dest, 'b8');
ok(defined $y,                                "rename successful");
isa_ok($y, 'Mail::Box::Identity');
is($y->name, 'b8');
is($x->name, 'b8');
is($y->parent->parent->name, 'a3');
is($y->fullname, '=/a3/b8');
is($y->fullname('#'), '=#a3#b8');
is($y->location, "$top/a3/b8");


clean_dir($top);
