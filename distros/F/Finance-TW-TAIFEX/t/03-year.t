#!/usr/bin/perl -w
use strict;
use Test::Exception;
use Test::More tests => 4;
use ok 'Finance::TW::TAIFEX';
use ok 'Finance::TW::TAIFEX::Contract';

my $t = Finance::TW::TAIFEX->new({ year => 2012, month => 1, day => 2});

is( $t->previous_trading_day, '2011-12-30' );

$t = Finance::TW::TAIFEX->new({ year => 2011, month => 12, day => 30});

is( $t->next_trading_day, '2012-01-02' );
