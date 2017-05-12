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
use Const::Fast;
const my $DUMPER_DEPTH => 4;
use Data::Dumper; $Data::Dumper::Maxdepth = $DUMPER_DEPTH;

diag('Testing IO::Iron::IronCache::Client '
   . ($IO::Iron::IronCache::Client::VERSION ? "($IO::Iron::IronCache::Client::VERSION)" : '(no version)')
   . ", Perl $], $^X");

## Test case
my $project_id;
my $cache_client;

my $test_policy = {
  'definition' => {
      'character_set' => 'ascii', # The only supported character set!
      'character_group' => {
          '[:mychars:]' => 'abc',
          '[:mydigits:]' => '23',
      },
  },
  'name' => [
              '[:mychars:]{1,2}[:mydigits:]{1}',
            ],
  'item_key' => [
                  'item_01_[:digit:]{2}',
                  'item_01_[:digit:]{3}',
                  'item_01_[:digit:]{4}',
                  'item_01_[:alpha:]{1,4}'
                ]
};

subtest 'Check for valid cache and key names' => sub {
    plan tests => 3;

    # Create an IronCache client.
    $cache_client = IO::Iron::IronCache::Client->new(
        #'config' => 'iron_cache.json'
        'project_id' => 'dummy_project_id',
    );
    $project_id = $cache_client->{'connection'}->{'project_id'};
    # Use $project_id for log message comparisons.

    # Test
    # Below: internal assignment, suitable only when testing!
    $cache_client->{'policy'} = $test_policy;
    my $expecteds = [sort qw(
            a2 b2 c2 a3 b3 c3
            aa2 ab2 ac2 ba2 bb2 bc2 ca2 cb2 cc2
            aa3 ab3 ac3 ba3 bb3 bc3 ca3 cb3 cc3
             )];
    my $gots = [ sort $cache_client->cache_name_alternatives() ];
    is_deeply($gots, $expecteds, 'Got what expected.');

    # Test
    $cache_client->{'policy'}->{'definition'}->{'character_group'}->
            {'[:daydigit:]'} = '0123';
            # Possible dates 1.,2.,3.,10.,11.,12.,13.,20.,21, ...
    $cache_client->{'policy'}->{'definition'}->{'character_group'}->
            {'[:two_years:]'} = '45';
    $cache_client->{'policy'}->{'name'} = [
              '201[:two_years:]{1}-Jan-[:daydigit:]{2}.[:digit:]{1}',
            ];
    $expecteds = [sort qw(
            2014-Jan-00.0
            2014-Jan-00.1
            2014-Jan-00.2
            2014-Jan-00.3
            2014-Jan-00.4
            2014-Jan-00.5
            2014-Jan-00.6
            2014-Jan-00.7
            2014-Jan-00.8
            2014-Jan-00.9
            2014-Jan-01.0
            2014-Jan-01.1
            2014-Jan-01.2
            2014-Jan-01.3
            2014-Jan-01.4
            2014-Jan-01.5
            2014-Jan-01.6
            2014-Jan-01.7
            2014-Jan-01.8
            2014-Jan-01.9
            2014-Jan-02.0
            2014-Jan-02.1
            2014-Jan-02.2
            2014-Jan-02.3
            2014-Jan-02.4
            2014-Jan-02.5
            2014-Jan-02.6
            2014-Jan-02.7
            2014-Jan-02.8
            2014-Jan-02.9
            2014-Jan-03.0
            2014-Jan-03.1
            2014-Jan-03.2
            2014-Jan-03.3
            2014-Jan-03.4
            2014-Jan-03.5
            2014-Jan-03.6
            2014-Jan-03.7
            2014-Jan-03.8
            2014-Jan-03.9
            2014-Jan-10.0
            2014-Jan-10.1
            2014-Jan-10.2
            2014-Jan-10.3
            2014-Jan-10.4
            2014-Jan-10.5
            2014-Jan-10.6
            2014-Jan-10.7
            2014-Jan-10.8
            2014-Jan-10.9
            2014-Jan-11.0
            2014-Jan-11.1
            2014-Jan-11.2
            2014-Jan-11.3
            2014-Jan-11.4
            2014-Jan-11.5
            2014-Jan-11.6
            2014-Jan-11.7
            2014-Jan-11.8
            2014-Jan-11.9
            2014-Jan-12.0
            2014-Jan-12.1
            2014-Jan-12.2
            2014-Jan-12.3
            2014-Jan-12.4
            2014-Jan-12.5
            2014-Jan-12.6
            2014-Jan-12.7
            2014-Jan-12.8
            2014-Jan-12.9
            2014-Jan-13.0
            2014-Jan-13.1
            2014-Jan-13.2
            2014-Jan-13.3
            2014-Jan-13.4
            2014-Jan-13.5
            2014-Jan-13.6
            2014-Jan-13.7
            2014-Jan-13.8
            2014-Jan-13.9
            2014-Jan-20.0
            2014-Jan-20.1
            2014-Jan-20.2
            2014-Jan-20.3
            2014-Jan-20.4
            2014-Jan-20.5
            2014-Jan-20.6
            2014-Jan-20.7
            2014-Jan-20.8
            2014-Jan-20.9
            2014-Jan-21.0
            2014-Jan-21.1
            2014-Jan-21.2
            2014-Jan-21.3
            2014-Jan-21.4
            2014-Jan-21.5
            2014-Jan-21.6
            2014-Jan-21.7
            2014-Jan-21.8
            2014-Jan-21.9
            2014-Jan-22.0
            2014-Jan-22.1
            2014-Jan-22.2
            2014-Jan-22.3
            2014-Jan-22.4
            2014-Jan-22.5
            2014-Jan-22.6
            2014-Jan-22.7
            2014-Jan-22.8
            2014-Jan-22.9
            2014-Jan-23.0
            2014-Jan-23.1
            2014-Jan-23.2
            2014-Jan-23.3
            2014-Jan-23.4
            2014-Jan-23.5
            2014-Jan-23.6
            2014-Jan-23.7
            2014-Jan-23.8
            2014-Jan-23.9
            2014-Jan-30.0
            2014-Jan-30.1
            2014-Jan-30.2
            2014-Jan-30.3
            2014-Jan-30.4
            2014-Jan-30.5
            2014-Jan-30.6
            2014-Jan-30.7
            2014-Jan-30.8
            2014-Jan-30.9
            2014-Jan-31.0
            2014-Jan-31.1
            2014-Jan-31.2
            2014-Jan-31.3
            2014-Jan-31.4
            2014-Jan-31.5
            2014-Jan-31.6
            2014-Jan-31.7
            2014-Jan-31.8
            2014-Jan-31.9
            2014-Jan-32.0
            2014-Jan-32.1
            2014-Jan-32.2
            2014-Jan-32.3
            2014-Jan-32.4
            2014-Jan-32.5
            2014-Jan-32.6
            2014-Jan-32.7
            2014-Jan-32.8
            2014-Jan-32.9
            2014-Jan-33.0
            2014-Jan-33.1
            2014-Jan-33.2
            2014-Jan-33.3
            2014-Jan-33.4
            2014-Jan-33.5
            2014-Jan-33.6
            2014-Jan-33.7
            2014-Jan-33.8
            2014-Jan-33.9
            2015-Jan-00.0
            2015-Jan-00.1
            2015-Jan-00.2
            2015-Jan-00.3
            2015-Jan-00.4
            2015-Jan-00.5
            2015-Jan-00.6
            2015-Jan-00.7
            2015-Jan-00.8
            2015-Jan-00.9
            2015-Jan-01.0
            2015-Jan-01.1
            2015-Jan-01.2
            2015-Jan-01.3
            2015-Jan-01.4
            2015-Jan-01.5
            2015-Jan-01.6
            2015-Jan-01.7
            2015-Jan-01.8
            2015-Jan-01.9
            2015-Jan-02.0
            2015-Jan-02.1
            2015-Jan-02.2
            2015-Jan-02.3
            2015-Jan-02.4
            2015-Jan-02.5
            2015-Jan-02.6
            2015-Jan-02.7
            2015-Jan-02.8
            2015-Jan-02.9
            2015-Jan-03.0
            2015-Jan-03.1
            2015-Jan-03.2
            2015-Jan-03.3
            2015-Jan-03.4
            2015-Jan-03.5
            2015-Jan-03.6
            2015-Jan-03.7
            2015-Jan-03.8
            2015-Jan-03.9
            2015-Jan-10.0
            2015-Jan-10.1
            2015-Jan-10.2
            2015-Jan-10.3
            2015-Jan-10.4
            2015-Jan-10.5
            2015-Jan-10.6
            2015-Jan-10.7
            2015-Jan-10.8
            2015-Jan-10.9
            2015-Jan-11.0
            2015-Jan-11.1
            2015-Jan-11.2
            2015-Jan-11.3
            2015-Jan-11.4
            2015-Jan-11.5
            2015-Jan-11.6
            2015-Jan-11.7
            2015-Jan-11.8
            2015-Jan-11.9
            2015-Jan-12.0
            2015-Jan-12.1
            2015-Jan-12.2
            2015-Jan-12.3
            2015-Jan-12.4
            2015-Jan-12.5
            2015-Jan-12.6
            2015-Jan-12.7
            2015-Jan-12.8
            2015-Jan-12.9
            2015-Jan-13.0
            2015-Jan-13.1
            2015-Jan-13.2
            2015-Jan-13.3
            2015-Jan-13.4
            2015-Jan-13.5
            2015-Jan-13.6
            2015-Jan-13.7
            2015-Jan-13.8
            2015-Jan-13.9
            2015-Jan-20.0
            2015-Jan-20.1
            2015-Jan-20.2
            2015-Jan-20.3
            2015-Jan-20.4
            2015-Jan-20.5
            2015-Jan-20.6
            2015-Jan-20.7
            2015-Jan-20.8
            2015-Jan-20.9
            2015-Jan-21.0
            2015-Jan-21.1
            2015-Jan-21.2
            2015-Jan-21.3
            2015-Jan-21.4
            2015-Jan-21.5
            2015-Jan-21.6
            2015-Jan-21.7
            2015-Jan-21.8
            2015-Jan-21.9
            2015-Jan-22.0
            2015-Jan-22.1
            2015-Jan-22.2
            2015-Jan-22.3
            2015-Jan-22.4
            2015-Jan-22.5
            2015-Jan-22.6
            2015-Jan-22.7
            2015-Jan-22.8
            2015-Jan-22.9
            2015-Jan-23.0
            2015-Jan-23.1
            2015-Jan-23.2
            2015-Jan-23.3
            2015-Jan-23.4
            2015-Jan-23.5
            2015-Jan-23.6
            2015-Jan-23.7
            2015-Jan-23.8
            2015-Jan-23.9
            2015-Jan-30.0
            2015-Jan-30.1
            2015-Jan-30.2
            2015-Jan-30.3
            2015-Jan-30.4
            2015-Jan-30.5
            2015-Jan-30.6
            2015-Jan-30.7
            2015-Jan-30.8
            2015-Jan-30.9
            2015-Jan-31.0
            2015-Jan-31.1
            2015-Jan-31.2
            2015-Jan-31.3
            2015-Jan-31.4
            2015-Jan-31.5
            2015-Jan-31.6
            2015-Jan-31.7
            2015-Jan-31.8
            2015-Jan-31.9
            2015-Jan-32.0
            2015-Jan-32.1
            2015-Jan-32.2
            2015-Jan-32.3
            2015-Jan-32.4
            2015-Jan-32.5
            2015-Jan-32.6
            2015-Jan-32.7
            2015-Jan-32.8
            2015-Jan-32.9
            2015-Jan-33.0
            2015-Jan-33.1
            2015-Jan-33.2
            2015-Jan-33.3
            2015-Jan-33.4
            2015-Jan-33.5
            2015-Jan-33.6
            2015-Jan-33.7
            2015-Jan-33.8
            2015-Jan-33.9
                 )];
    $gots = [ sort $cache_client->cache_name_alternatives() ];
    is_deeply($gots, $expecteds, 'Got what expected.');

    # Test
    $cache_client->{'policy'}->{'name'} = [
              'Cache_[:mychars:]{1}[:mydigits:]{3}',
            ];
    $expecteds = [sort qw(
            Cache_a222
            Cache_a223
            Cache_a232
            Cache_a233
            Cache_a322
            Cache_a323
            Cache_a332
            Cache_a333

            Cache_b222
            Cache_b223
            Cache_b232
            Cache_b233
            Cache_b322
            Cache_b323
            Cache_b332
            Cache_b333

            Cache_c222
            Cache_c223
            Cache_c232
            Cache_c233
            Cache_c322
            Cache_c323
            Cache_c332
            Cache_c333
             )];
    $gots = [ sort $cache_client->cache_name_alternatives() ];
    is_deeply($gots, $expecteds, 'Got what expected.');
};

