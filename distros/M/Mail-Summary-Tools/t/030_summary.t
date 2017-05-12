#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "Mail::Summary::Tools::Summary";
use ok "Mail::Summary::Tools::Summary::List";
use ok "Mail::Summary::Tools::Summary::Thread";

my $s = Mail::Summary::Tools::Summary->new;

isa_ok( $s, "Mail::Summary::Tools::Summary" );

is_deeply( [ $s->lists ], [], "no lists yet" );

my $list = Mail::Summary::Tools::Summary::List->new( name => "awesome list" );

isa_ok( $list, "Mail::Summary::Tools::Summary::List" );

can_ok( $s, "add_lists" );

$s->add_lists( $list );

is_deeply( [ $s->lists ], [ $list ], "single list" );

can_ok( $list, "threads" );

is_deeply( [ $list->threads ], [ ], "no threads" );

my $thread = Mail::Summary::Tools::Summary::Thread->new(
	message_id => 'unique@example.com',
	subject    => "Green things in general",
);

isa_ok( $thread, "Mail::Summary::Tools::Summary::Thread" );

can_ok( $list, "add_threads" );

$list->add_threads( $thread );

is_deeply( [ $list->threads ], [ $thread ], "single thread" );

my $yaml = $s->save;

ok( !ref($yaml), "looks like a string" );

my $mid = $thread->message_id;
like( $yaml, qr/message_id\s*:\s*\Q$mid\E/, "YAML has data in it" );

