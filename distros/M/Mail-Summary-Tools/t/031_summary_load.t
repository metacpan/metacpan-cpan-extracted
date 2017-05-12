#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use FindBin qw/$Bin/;
use File::Spec;

use ok "Mail::Summary::Tools::Summary";

my $file = File::Spec->catfile( $Bin, "data", "summary.yaml" );

my $summary = Mail::Summary::Tools::Summary->load( $file, thread => { default_archive => "moose" } );

isa_ok( $summary, "Mail::Summary::Tools::Summary" );

my @lists = $summary->lists;
is( scalar(@lists), 1, "one list" );

my @threads = $lists[0]->threads;
is( scalar(@threads), 1, "one thread" );

my $thread = $threads[0];

is( $thread->subject, "The Message Subject", "thread subject" );
like( $thread->summary, qr/cheese/, "the summary is correct" );
like( $thread->message_id, qr/.+\@[\w\.]+/, "message id looks ok" );

ok( $thread->extra, "extra keys were found" );
is_deeply( [ keys %{ $thread->extra } ], [ "posters" ], "posters in extra" );
is( ref( $thread->extra->{posters} ), "ARRAY", "posters is an array" );

is( $thread->default_archive, "moose", "default options provided to constructors" );

ok( $summary->extra, "summary contains extra data" );
