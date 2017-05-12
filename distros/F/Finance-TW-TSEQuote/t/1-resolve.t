#!/usr/bin/perl

use Test::More tests => 3;
BEGIN { use_ok('Finance::TW::TSEQuote') };

my $quote = Finance::TW::TSEQuote->new('中鋼');

is ($quote->{id}, '2002', 'symbol resolving');

is (Finance::TW::TSEQuote->resolve('中鋼'), '2002', 'direct invokation');
