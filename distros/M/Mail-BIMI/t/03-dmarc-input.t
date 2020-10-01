#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use lib 't';
use Mail::BIMI::Prelude;
use Test::More;
use Mail::BIMI;
use Net::DNS::Resolver::Mock 1.20200214;


my $resolver = Net::DNS::Resolver::Mock->new;
$resolver->zonefile_read('t/zonefile');

my $dmarc = Mail::DMARC::PurePerl->new;
$dmarc->result->result( 'pass' );
$dmarc->result->disposition( 'reject' );

subtest 'Mail::DMARC::Result Passed in' => sub{
  my $bimi = Mail::BIMI->new(domain=>'example.com');
  $bimi->resolver($resolver);
  $bimi->dmarc_object( $dmarc->result );
  is(ref $bimi->dmarc_result_object,'Mail::DMARC::Result','Correct result object type retuened');
  is($bimi->dmarc_result_object,$dmarc->result,'Correct result object returned');
  is(ref $bimi->dmarc_pp_object,'Mail::DMARC::PurePerl','Correct pp object type retuened');
  is($bimi->dmarc_pp_object->header_from,'example.com','PP object has correct domain');
};

subtest 'Mail::DMARC Passed in' => sub{
  my $bimi = Mail::BIMI->new(domain=>'example.com');
  $bimi->resolver($resolver);
  $bimi->dmarc_object( $dmarc );
  is(ref $bimi->dmarc_result_object,'Mail::DMARC::Result','Correct result object type retuened');
  is($bimi->dmarc_result_object,$dmarc->result,'Correct result object returned');
  is(ref $bimi->dmarc_pp_object,'Mail::DMARC::PurePerl','Correct pp object type retuened');
  is($bimi->dmarc_pp_object,$dmarc,'Correct pp object returned');
};

done_testing;
