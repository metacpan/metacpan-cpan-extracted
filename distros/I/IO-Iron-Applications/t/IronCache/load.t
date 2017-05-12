#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

require IO::Iron::Applications::IronCache::Functionality;

#use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.

plan tests => 10;

BEGIN {
	use_ok('IO::Iron::Applications::IronCache::Functionality') || print "Bail out!\n";
	can_ok('IO::Iron::Applications::IronCache::Functionality', 'clear_cache') || print "Bail out!\n";
	can_ok('IO::Iron::Applications::IronCache::Functionality', 'delete_cache') || print "Bail out!\n";
	can_ok('IO::Iron::Applications::IronCache::Functionality', 'delete_item') || print "Bail out!\n";
	can_ok('IO::Iron::Applications::IronCache::Functionality', 'get_item') || print "Bail out!\n";
	can_ok('IO::Iron::Applications::IronCache::Functionality', 'put_item') || print "Bail out!\n";
	can_ok('IO::Iron::Applications::IronCache::Functionality', 'increment_item') || print "Bail out!\n";
	can_ok('IO::Iron::Applications::IronCache::Functionality', 'list_caches') || print "Bail out!\n";
	can_ok('IO::Iron::Applications::IronCache::Functionality', 'show_cache') || print "Bail out!\n";
	can_ok('IO::Iron::Applications::IronCache::Functionality', 'list_items') || print "Bail out!\n";
}

diag("Testing IO::Iron::Applications::IronCache::Functionality, Perl $], $^X");

