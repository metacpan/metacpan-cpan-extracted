#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use lib 't';
use Mail::BIMI::Prelude;
use Test::More;
use Mail::BIMI;
use Mail::BIMI::Record;
use Mail::BIMI::Record::Authority;

my $bimi = Mail::BIMI->new;
my $record = Mail::BIMI::Record->new(bimi_object=>$bimi,domain=>'example.com');
$bimi->record($record);
my $authority = Mail::BIMI::Record::Authority->new(bimi_object=>$bimi,uri=>'');
$record->authority($authority);

subtest 'on record' => sub {
  is(ref $record->bimi_object,'Mail::BIMI','BIMI object returned');
  is(ref $record->record_object,'Mail::BIMI::Record','Record object returned');
  is(ref $record->authority_object,'Mail::BIMI::Record::Authority','Authority object returned');
};

subtest 'on authority' => sub {
  is(ref $authority->bimi_object,'Mail::BIMI','BIMI object returned');
  is(ref $authority->record_object,'Mail::BIMI::Record','Record object returned');
  is(ref $authority->authority_object,'Mail::BIMI::Record::Authority','Authority object returned');
};

done_testing;

