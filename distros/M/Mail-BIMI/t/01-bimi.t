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
use Mail::DMARC::PurePerl;

my $bimi = Mail::BIMI->new;

is ( $bimi->selector, 'default', 'default bimi selector' );
$bimi->selector( 'foobar' );
is ( $bimi->selector, 'foobar', 'set bimi selector' );

is ( $bimi->domain, undef, 'no default domain' );
$bimi->domain( 'foo.bar.com' );
is ( $bimi->domain, 'foo.bar.com', 'set bimi domain' );

done_testing;
