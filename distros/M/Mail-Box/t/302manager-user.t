#!/usr/bin/env perl
#
# Test the user manager, which extends the normal manager

use strict;
use warnings;

use Mail::Box::Test;
use Mail::Box::Manage::User;

use Test::More tests => 11;

my $id   = User::Identity->new('markov');
ok(defined $id,                              "Identity created");
isa_ok($id, 'User::Identity');

my $user = Mail::Box::Manage::User->new(identity => $id);

ok(defined $user,                            "User manager created");
isa_ok($user, "Mail::Box::Manager");
isa_ok($user, "Mail::Box::Manage::User");

my $i   = $user->identity;
ok(defined $i,                               "Identity defined");
isa_ok($i, 'User::Identity');
cmp_ok($id->name, 'eq', $i->name,            "Same id object");

my $f   = $user->topfolder;
ok(defined $f,                               "Folder structure created");
isa_ok($f, 'Mail::Box::Identity');
isa_ok($f, 'User::Identity::Item');
