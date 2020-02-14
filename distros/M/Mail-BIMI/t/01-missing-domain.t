#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Mail::BIMI::Pragmas;
use Test::More;
use Test::Exception;
use Mail::BIMI;

my $bimi = Mail::BIMI->new;
dies_ok( sub{$bimi->record}, 'Missing domain dies for record' );
dies_ok( sub{$bimi->result}, 'Missing domain dies for result' );

done_testing;
