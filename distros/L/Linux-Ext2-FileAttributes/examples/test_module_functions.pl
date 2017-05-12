#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw(. lib);
use Linux::Ext2::FileAttributes;
use Test::More qw(no_plan);

# These tests must run with root powers

my $immutable      = 'files/immutable';
my $appendable     = 'files/appendable';
my $not_appendable = 'files/no_appendable';
my $not_immutable  = 'files/not_immutable';

my $set_immutable  = 'files/set_immutable';
my $set_appendable = 'files/set_appendable';

`chattr +i $immutable`;  # set immutable  flag via shell
`chattr +a $appendable`; # set appendable flag via shell

# basic detection checks
ok(is_immutable($immutable),          "immutable flag is set");
ok(! is_immutable($not_immutable),    "immutable flag isn't set");

ok(is_append_only($appendable),       "appendable flag is set");
ok(! is_append_only($not_appendable), "appendable isn't set");

###################################################
# try to set and clear the flags
###################################################

# set up and check we know they're clean
unlink $set_immutable, $set_appendable;
`touch $set_immutable $set_appendable`;

ok(! is_immutable(   $set_immutable  ), "immutable flag isn't set" );
ok(! is_append_only( $set_appendable ), "appendable isn't set" );

# # go through a set, check clear for each attribute

# Immutable
ok( set_immutable(   $set_immutable ), "Set immutable flag");
ok( is_immutable(    $set_immutable ), "Check immutable was set");
ok( clear_immutable( $set_immutable ), "Clear immutable flag");
ok( ! is_immutable(  $set_immutable ), "Check immutable is cleared");

# Appendable
ok( set_append_only(   $set_immutable ), "Set append only flag");
ok( is_append_only(    $set_immutable ), "Check append only was set");
ok( clear_append_only( $set_immutable ), "Clear append only flag");
ok( ! is_append_only(  $set_immutable ), "Check append only is cleared");
