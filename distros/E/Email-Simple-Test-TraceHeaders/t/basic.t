use strict;
use warnings;
use Email::Simple::Test::TraceHeaders -helpers;
use Test::More 0.88;

my $email = Email::Simple::Test::TraceHeaders->create_email({
  hops => [
    {
      from_helo => 'lab.pobox.com',
      from_rdns => 'lab.pobox.com',
      from_ip   => '208.72.237.24',
      by_name   => 'a-lb-mx-quonix.listbox.com',
      queue_id  => 'B3533317DE',
      env_to    => [ 'example-staff@example.com' ],
      time      => (time - 1800),
    },
    {
      from_helo => prev('by_name'),
      from_rdns => prev('by_name'),
      from_ip   => '208.72.237.49',
      by_name   => 'emerald.pobox.com',
      queue_id  => 'DFF5B134875',
      time      => (time - 900),
    },
    {
      from_helo => 'localhost.localdomain',
      from_rdns => 'localhost.localdomain',
      from_ip   => '127.0.0.1',
      by_name   => prev('by_name'),
      queue_id  => 'EA0A6317DF',
      env_to    => 'the-final-destination@example.com',
      time      => (time - 300),
    },
  ],
});

my @rcvd = $email->header('Received');
like($rcvd[0], qr{localhost}, "localhost in topmost header");
like($rcvd[1], qr{DFF5B134875}, "middle header in middle");
like($rcvd[2], qr{B3533317DE}, "first hop at the bottom");

like($rcvd[0], qr/for <the-final-destination\@example\.com>/, "env-to");
unlike($rcvd[1], qr/for </, "no env-to");
like($rcvd[2], qr/for <example-staff\@example\.com>/, "env-to");

done_testing;

1;
