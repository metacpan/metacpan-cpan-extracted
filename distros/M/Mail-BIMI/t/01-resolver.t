#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use lib 't';
use Mail::BIMI::Prelude;
use Test::Class;
use Test::More;
use Mail::BIMI;
use Mail::BIMI::Record;
use Mail::DMARC::PurePerl;

my $bimi = Mail::BIMI->new;
my $resolver = $bimi->resolver;

is( ref $resolver, 'Net::DNS::Resolver', 'Returns a resolver object' );

done_testing;
