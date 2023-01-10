use v5.12;
use warnings;

use Test::More;

use Email::Address;

my @tests = (
  [
    [
      undef,
      'simple@example.com',
      undef
    ],
    'simple@example.com',
  ],
  [
    [
      'John Doe',
      'johndoe@example.com',
      undef
    ],
    q{"John Doe" <johndoe@example.com>},
  ],
  [
    [
      q{Name With " Quote},
      'nwq@example.com',
      undef
    ],
    q{"Name With \\" Quote" <nwq@example.com>},
  ],
  [
    [
      q{"Name Surrounded With Quotes"},
      'foobar@example.com',
      undef
    ],
    q{"Name Surrounded With Quotes" <foobar@example.com>},
  ],
  [
    [
      "",
      undef,
      undef,
    ],
    '',
  ],
);

for (@tests) {
  my $addr = Email::Address->new( @{ $_->[0] } );
  is( $addr->format, $_->[1], "format: $_->[1]" );
}

done_testing;
