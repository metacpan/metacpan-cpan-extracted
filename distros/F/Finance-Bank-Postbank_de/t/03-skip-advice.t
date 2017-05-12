#!/usr/bin/perl -w
use strict;
use FindBin;
use WWW::Mechanize;

use Test::More tests => 2;

BEGIN { use_ok("Finance::Bank::Postbank_de"); };

# Check that we have SSL installed :
SKIP: {
  my $account = Finance::Bank::Postbank_de->new(
                  login => '9999999999',
                  password => 'xxxxx',
                  status => sub {
                              shift;
                              diag join " ",@_
                                if ($_[0] eq "HTTP Code") and ($_[1] != 200);
                            },
                );
  $account->agent( WWW::Mechanize->new());
  $account->agent->get( 'file:t/03-skip-advice.html' );
  ok( $account->is_security_advice, 'Security advice page gets detected');
};
