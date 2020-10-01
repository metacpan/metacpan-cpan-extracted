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
use Mail::BIMI::CacheBackend::Null;
use Net::DNS::Resolver::Mock 1.20200214;

my $resolver = Net::DNS::Resolver::Mock->new;
$resolver->zonefile_read('t/zonefile');
my $bimi = Mail::BIMI->new(domain=>'gallifreyburning.com');
$bimi->resolver($resolver);

subtest 'Null Cache Is Null' => sub{
  my $bimi = Mail::BIMI->new(domain=>'gallifreyburning.com',options=>{cache_backend=>'Null'});
  $bimi->resolver($resolver);
  $bimi->record->is_valid; # Make the Fetch Happen
  my $backend = Mail::BIMI::CacheBackend::Null->new(parent=>$bimi->record);
  is($bimi->record->version,'bimi1','Version is ok');
  $bimi->record->version('foo');
  is($bimi->record->version,'foo','Version is set ok');
  $bimi->finish();
  lives_ok(sub{$backend->delete_cache},'NOP delete_cache lives');
};

subtest 'Null Cache Is Still Null' => sub{
  my $bimi = Mail::BIMI->new(domain=>'gallifreyburning.com',options=>{cache_backend=>'Null'});
  $bimi->resolver($resolver);
  $bimi->record->is_valid; # Make the Fetch Happen
  my $backend = Mail::BIMI::CacheBackend::Null->new(parent=>$bimi->record);
  is($bimi->record->version,'bimi1','Version is still ok');
};

done_testing;


