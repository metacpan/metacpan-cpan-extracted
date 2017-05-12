#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Log::Any::Test;    # should appear before 'use Log::Any'!
use Log::Any qw($log);

use lib 't';
use lib 'integ_t';
require 'iron_io_integ_tests_common.pl';

plan tests => 1;

require IO::Iron::IronCache::Client;
require IO::Iron::IronCache::Item;

#use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.
use Data::Dumper; $Data::Dumper::Maxdepth = 4;

diag('Testing IO::Iron::IronCache::Client '
   . ($IO::Iron::IronCache::Client::VERSION ? "($IO::Iron::IronCache::Client::VERSION)" : '(no version)')
   . " with policies, Perl $], $^X");

## Test case
my $project_id;
my $cache_client;

my $test_policy = {
    'definition' => {
        'character_set' => 'ascii', # The only supported character set!
        'character_groups' => {
            '[:mychars:]' => 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
            '[:mydigits:]' => '0123456789',
        },
    },
  'name' => [
              'cache_01_main',
              'cache_01_[:digit:]{3}'
            ],
  'item_key' => [
                  'item_01_[:digit:]{2}',
                  'item_01_[:digit:]{3}',
                  'item_01_[:digit:]{4}',
                  'item_01_[:alpha:]{1,4}'
                ]
};

subtest 'Check for valid cache and key names' => sub {
    plan tests => 11;

    my $cache_name;
    my $item_key;
    # Create an IronCache client.
    $cache_client = IO::Iron::IronCache::Client->new(
        #'config' => 'iron_cache.json'
        'project_id' => 'dummy_project_id',
    );
    # Below: internal assignment, suitable only when testing!
    $cache_client->{'policy'} = $test_policy;
    $project_id = $cache_client->{'connection'}->{'project_id'};
    # Use $project_id for log message comparisons.

    $cache_name = 'cache_01_main';
    is($cache_client->is_valid_cache_name('name' => $cache_name), 1, 'Cache name ' . $cache_name . ' is valid.');

    $cache_name = 'cache_01_123';
    is($cache_client->is_valid_cache_name('name' => $cache_name), 1, 'Cache name ' . $cache_name . ' is valid.');

    $cache_name = 'cache_01_12';
    is($cache_client->is_valid_cache_name('name' => $cache_name), 0, 'Cache name ' . $cache_name . ' is not valid.');

    $cache_name = 'cache_01_AAA';
    is($cache_client->is_valid_cache_name('name' => $cache_name), 0, 'Cache name ' . $cache_name . ' is not valid.');

    $item_key = 'item_01_12345';
    is($cache_client->is_valid_item_key('key' => $item_key), 0, 'Item name ' . $item_key . ' is not valid.');

    $item_key = 'item_01_AAA';
    is($cache_client->is_valid_item_key('key' => $item_key), 1, 'Item name ' . $item_key . ' is valid.');


    # Test with more action: exceptions from services.
    $cache_name = 'cache_02_main';
    throws_ok {
        my $created_cache = $cache_client->create_cache(
            'name' => $cache_name,
        );
    } 'IronPolicyException',
            'Throws IronPolicyException when cache name is not valid according to local policy.';
    like($@, "/IronPolicyException: policy=name candidate=$cache_name/", 'Exception string is ok.');
    #diag("Tried to create cache with name '" . $cache_name . "' which name is invalid. Threw ok.");

    # And now without throws.
    $cache_name = 'cache_01_main';
        my $created_cache = $cache_client->create_cache(
            'name' => $cache_name,
        );

    isa_ok($created_cache, "IO::Iron::IronCache::Cache", "create_cache returns an object of class IO::Iron::IronCache::Cache.");


    $item_key = 'item_02_001';
    my $cache_item = IO::Iron::IronCache::Item->new(
        'value' => 99,
        );
    #diag( Dumper($created_cache));
    throws_ok {
        my $item_put = $created_cache->put(
            'key' => $item_key,
            'item' => $cache_item,
        );
    } 'IronPolicyException',
            'Throws IronPolicyException when item key is not valid according to local policy.';
    like($@, "/IronPolicyException: policy=item_key candidate=$item_key/", 'Exception string is ok.');

    # And now without throws.
    # No, we're not gonna do that!
    # It would require a net connection, 
    # and that won't do in this test!
    #$item_key = 'item_01_001';
    #my $item_put = $created_cache->put(
    #    'key' => $item_key,
    #    'item' => $cache_item,
    #    );
    #is($item_put, 1, "put returns 1, it is successful.");
};

