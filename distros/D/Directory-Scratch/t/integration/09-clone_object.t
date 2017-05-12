#!/usr/bin/perl
# 09-clone_object.t 
# Copyright (c) 2006 Al Tobey           <tobeya@cpan.org>
#                and Jonathan Rockway <jrockway@cpan.org>

use Directory::Scratch;
use Test::More tests=>12;
use strict;
use warnings;

my $t = Directory::Scratch->new;
isa_ok($t, 'Directory::Scratch'); 
can_ok( $t, 'child' );

ok( my $sub_t = $t->child, 
    "Call child on a parent Directory::Scratch object." );

my @parent = $t->base->dir_list;
my @child  = $sub_t->base->dir_list;

ok( @child > @parent, "Child should have more nodes than the parent." );
my $subdir = pop @child;

is_deeply( \@child, \@parent, "Child with last element popped should == parent." );

#diag( "chdir into the parent directory" );
chdir($t->base);

ok( -d $subdir, "child subdirectory basename exists under parent" );

ok( my $sub_sub_t = $sub_t->child, "create a grandchild" );

my $subsub_dir = $sub_sub_t->base;
ok( -d $subsub_dir, "grandchild directory exists" );

ok( $sub_t->cleanup, "call cleanup() on the child" );

ok( !-d $subsub_dir, "grandchild no longer exists after cleanup()" );
ok( !-d $subdir, "child no longer exists after cleanup()" );
ok( -d $t->base, "parent still exists after cleanup()" );

