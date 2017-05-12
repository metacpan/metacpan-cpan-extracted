#!/usr/bin/env perl

use Test::More;
use strict;

use_ok('LWP::UserAgent::Cached');

my $ua = LWP::UserAgent::Cached->new();
ok(defined $ua, 'new ua');
isa_ok($ua, 'LWP::UserAgent::Cached');
isa_ok($ua, 'LWP::UserAgent');

$ua = LWP::UserAgent::Cached->new(cache_dir => '/tmp', nocache_if => sub{1}, recache_if => sub{1});
is($ua->cache_dir, '/tmp', 'cache_dir param');
is(ref($ua->nocache_if), 'CODE', 'nocache_if is code');
is(ref($ua->recache_if), 'CODE', 'recache_if is code');

$ua->cache_dir('/var/tmp');
is($ua->cache_dir, '/var/tmp', 'runtime change cache_dir param');

my $old_nocache_if = $ua->nocache_if;
$ua->nocache_if(sub{0});
isnt($old_nocache_if, $ua->nocache_if, 'runtime change nocache_if param');

my $old_recache_if = $ua->recache_if;
$ua->recache_if(sub{0});
isnt($old_recache_if, $ua->recache_if, 'runtime change recache_if param');

done_testing;
