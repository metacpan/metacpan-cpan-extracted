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
use Net::DNS::Resolver::Mock 1.20200214;
use lib 't/testlib';
use TestForData;
use Digest::MD5 qw{md5_hex};

my $data = TestForData->new(bimi_object=>Mail::BIMI->new);
lives_ok(sub{$data->get_pass},'File contents returned');
dies_ok(sub{$data->get_fail},'Non existsnt file dies on read');
my $payload = $data->get_pass;
my $md5 = '217cc3ae0e02b4c8d94ea235c8b6642e';
is(md5_hex($payload),$md5,'Content has correct hash');
done_testing;

