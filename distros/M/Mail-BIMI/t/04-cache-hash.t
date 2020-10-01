#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use lib 't';
use Mail::BIMI::Prelude;
use Capture::Tiny qw{ capture };
use Test::More;
use Test::Exception;
use Mail::BIMI;
use Mail::BIMI::CacheBackend::Null;
use Net::DNS::Resolver::Mock 1.20200214;

my $bimi = Mail::BIMI->new(domain=>'example.com');
my $resolver = Net::DNS::Resolver::Mock->new;
$resolver->zonefile_read('t/zonefile');
$bimi->resolver($resolver);

subtest 'Not Cacheable' => sub{
  my $backend = Mail::BIMI::CacheBackend::Null->new(parent=>$bimi);
  dies_ok(sub{$backend->_cache_hash},'Dies when called on a non cachcable object');
};


subtest 'Cacheable' => sub{
  my $backend = Mail::BIMI::CacheBackend::Null->new(parent=>$bimi->record);
  my $expected = 'aa6d7e4b5079194df60db2742dbdf8b1eb1a0514';
  is($backend->_cache_hash,$expected,'Cache hash is returned');
};

done_testing;

