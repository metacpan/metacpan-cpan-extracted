use strict;
use warnings;
use Test::More;
use Log::Any qw($log), proxy_class => 'Test';
use Log::Any::Adapter ();

plan tests => 1;

Log::Any::Adapter->set('Test');
$log->info("for main");
$log->category_contains_ok(
    main => qr/for main/,
    'main log appeared in memory'
);
