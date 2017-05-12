#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw(. lib);
use Linux::Ext2::FileAttributes;
use Test::More qw(no_plan);

my $set_immutable = 'foo';

`touch $set_immutable`;

ok( set_immutable(   $set_immutable ), "Set immutable flag" );
ok( is_immutable(    $set_immutable ), "Check immutable was set" );
ok( clear_immutable( $set_immutable ), "Clear immutable flag" );
ok( ! is_immutable(  $set_immutable ), "Check immutable is cleared" );

unlink $set_immutable
  || die "Failed to delete [$set_immutable]: $!\n";
