#!/usr/bin/perl -w
use strict;
use FindBin;
use WWW::Mechanize;

use Test::More tests => 3;

BEGIN { use_ok("Finance::Bank::Postbank_de"); };

SKIP: {
  skip "We currently don't know what maintenance mode looks like", 2;
  my $account = Finance::Bank::Postbank_de->new(
                  login => 'Petra.Pfiffig',
                  password => 'xxxxx',
                  status => sub {
                              shift;
                              diag join " ",@_
                                if ($_[0] eq "HTTP Code") and ($_[1] != 200);
                            },
                );
  $account->agent( WWW::Mechanize->new());
  $account->agent->get( 'file:t/02-maintenance.html' );
  ok( $account->error_page, 'Error page gets detected');
  ok( $account->maintenance, 'Maintenance mode gets detected')
    or diag $account->agent->content;
};
