use strict;
use Test;
BEGIN { plan tests => 9 }

use HTTP::MHTTP;

ok(1);
#ok(test10());
ok(test2());
ok(test3());
ok(test4());
ok(test5());
ok(test6());
ok(test7());
ok(test8());
ok(test9());


sub test2 {
  http_init();
  switch_debug(1) if $ENV{'DEBUG'};
  return 1;
}

sub test3 {
  http_add_headers(
                   'User-Agent' => 'DVSGHTTP1/0',
                   'Host' => 'www.piersharding.com',
                   'Accept-Language' => 'en-gb',
                   'Connection' => 'Keep-Alive',
                 );
  return 1;
}

sub test4 {
  my $ret =  http_call('GET', 'http://www.piersharding.com/blog/');
  #warn "4: the return code is: $ret \n";
  return $ret > 0 ? 1 : 0;
}

sub test5 {
  #warn "5: status: ".http_status()."\n";
  return http_status() == 200 ? 1 : 0;
}

sub test6 {
  #warn "6: response: ".http_response()."\n";
  my @a = split(/\n/,http_response());
  return @a > 0 ? 1 : 0;
}

sub test7 {
  #warn "7: reason: ".http_reason()."\n";
  return length(http_reason()) > 0 ? 1 : 0;
}

sub test8 {
  #warn "8: headers: ".http_headers()."\n";
  my @a = split(/\n/,http_headers());
  return @a > 0 ? 1 : 0;
}

sub test9 {
  http_init();
  switch_debug(1) if $ENV{'DEBUG'};
  http_set_protocol(1);
  http_add_headers(
                    'User-Agent' => 'MHTTP1/0',
                    'Host' => 'www.piersharding.com',
                    'Accept-Language' => 'en-gb',
                    'Connection' => 'Keep-Alive',
                  );
  for (1..3){
    http_reset();
    my $rc = http_call('GET', 'http://www.piersharding.com/');
    return 0 unless $rc > 0;
    #warn "9: Status: ".http_status()."\n";
  }
  return 1;
}

sub test10 {
  http_init();
  switch_debug(1) if $ENV{'DEBUG'};
  http_set_protocol(1);
  http_add_headers(
                    'User-Agent' => 'MHTTP1/0',
                    'Host' => 'badger.local.net',
                    'Accept-Language' => 'en-gb',
                    'Connection' => 'Keep-Alive',
                  );
  http_reset();
  my $rc = http_call('GET', 'https://badger.local.net');
  return 0 unless $rc > 0;
  warn "9: Status: ".http_status()."\n";
  return 1;
}
