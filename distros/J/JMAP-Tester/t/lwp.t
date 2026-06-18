use v5.26.0;
use warnings;

use JMAP::Tester::UA::LWP;

use Test::Fatal;
use Test::More;
use Test::Abortable 'subtest';

subtest "UA::LWP helpers" => sub {
  my $ua = JMAP::Tester::UA::LWP->new;

  $ua->set_default_header('X-Test', 'xyzzy');
  is($ua->get_default_header('X-Test'), 'xyzzy', "get/set default header");

  $ua->set_cookie({
    api_uri => 'https://example.com/api/',
    name    => 'session',
    value   => 'abc123',
  });

  my @cookies;
  $ua->scan_cookies(sub { push @cookies, $_[1] });
  ok((grep { $_ eq 'session' } @cookies), "set_cookie + scan_cookies");

  for my $field (qw(api_uri name value)) {
    my %args = (api_uri => 'https://x.com/', name => 'n', value => 'v');
    delete $args{$field};
    my $err = exception { $ua->set_cookie(\%args) };
    like($err, qr/can't set_cookie without $field/, "set_cookie needs $field");
  }
};

done_testing;
