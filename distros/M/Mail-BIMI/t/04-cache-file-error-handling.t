#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use lib 't';
use Mail::BIMI::Prelude;
use Test::More;
use Test::Exception;
use Mail::BIMI;
use Mail::BIMI::CacheBackend::File;
use Mail::BIMI::CacheBackend::FastMmap;
use File::Slurp qw{ read_file write_file };
use Net::DNS::Resolver::Mock 1.20200214;

my $resolver = Net::DNS::Resolver::Mock->new;
$resolver->zonefile_read('t/zonefile');
my $bimi = Mail::BIMI->new(domain=>'cachefileerrorhandling.com');
$bimi->resolver($resolver);

my $options = {cache_backend=>'File',cache_file_directory=>'t/tmp/cache/'},

my $hashes = {
  indicator => 't/tmp/cache/mail-bimi-cache-166cc1317749e82abc10e4068941f912fa774baf.cache',
  record => 't/tmp/cache/mail-bimi-cache-228d876fef73043dfb570ed9125a2425701b8d07.cache',
};

subtest 'Write garbage to file' => sub {
  save_cache();
  write_file($hashes->{record},'FooBarBaz');
  my $bimi = Mail::BIMI->new(domain=>'cachefileerrorhandling.com',time=>1010,options=>$options);
  $bimi->resolver($resolver);
  $bimi->record->is_valid; # Make the Fetch Happen
  my $backend = Mail::BIMI::CacheBackend::Null->new(parent=>$bimi->record);
  is($bimi->record->version,'bimi1','Version is NOT from cache');
};

subtest 'Cache is valid for wrong data' => sub {
  save_cache();
  my $data = scalar read_file($hashes->{indicator});
  write_file($hashes->{record},$data);
  my $bimi = Mail::BIMI->new(domain=>'cachefileerrorhandling.com',time=>1010,options=>$options);
  $bimi->resolver($resolver);
  $bimi->record->is_valid; # Make the Fetch Happen
  my $backend = Mail::BIMI::CacheBackend::Null->new(parent=>$bimi->record);
  is($bimi->record->version,'bimi1','Version is NOT from cache');
};

cleanup();

sub cleanup {
  mkdir 't/tmp' if ! -e 't/tmp';
  system('rm -rf t/tmp/cache') if -e 't/tmp/cache';
  mkdir 't/tmp/cache';
}

sub save_cache {
  cleanup();
  subtest 'Cache saved when finish called' => sub{
    {
      my $bimi = Mail::BIMI->new(domain=>'cachefileerrorhandling.com',time=>1000,options=>$options);
      $bimi->resolver($resolver);
      $bimi->record->is_valid; # Make the Fetch Happen
      my $backend = Mail::BIMI::CacheBackend::Null->new(parent=>$bimi->record);
      is($bimi->record->version,'bimi1','Version is ok');
      $bimi->record->version('foo');
      is($bimi->record->version,'foo','Version is set ok');
      $bimi->finish;
    };
    {
      my $bimi = Mail::BIMI->new(domain=>'cachefileerrorhandling.com',time=>1010,options=>$options);
      $bimi->resolver($resolver);
      $bimi->record->is_valid; # Make the Fetch Happen
      my $backend = Mail::BIMI::CacheBackend::Null->new(parent=>$bimi->record);
      is($bimi->record->version,'foo','Version is from cache');
    };
  };
};

done_testing;




