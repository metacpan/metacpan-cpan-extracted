#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use lib 't';
use Mail::BIMI::Prelude;
use Capture::Tiny qw{ capture };
use Test::More;
use Mail::BIMI;
use Net::DNS::Resolver::Mock 1.20200214;

my $resolver = Net::DNS::Resolver::Mock->new;
$resolver->zonefile_read('t/zonefile');

subtest 'Non Verbose' => sub{
  my $bimi = Mail::BIMI->new(domain=>'test.com',options=>{verbose=>0});
  $bimi->resolver($resolver);
  my($out,$err,$exit)=capture{
    $bimi->log_verbose('This is verbose output');
  };
  is($out,'','No STDOUT Output');
  is($err,'','No STDERR Output');
};

subtest 'Verbose' => sub{
  my $bimi = Mail::BIMI->new(domain=>'test.com',options=>{verbose=>1});
  $bimi->resolver($resolver);
  my($out,$err,$exit)=capture{
    $bimi->log_verbose('This is verbose output');
  };
  is($out,'','No STDOUT Output');
  is($err,"This is verbose output\n",'STDERR Output');
};

done_testing;

