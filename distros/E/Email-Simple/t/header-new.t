use strict;

use Test::More tests => 7;

# This test could test all manner of Email::Simple::Header stuff, but is mostly
# just here specifically to test construction and sanity of result with both a
# string AND a reference to it. -- rjbs, 2006-11-29

BEGIN { use_ok('Email::Simple::Header'); }

my $header_string = <<'END_HEADER';
Foo: 1
Foo: 2
Foo: 3
Bar: 3
Baz: 1
END_HEADER

for my $header_param ($header_string, \$header_string) {
  my $head = Email::Simple::Header->new($header_param);

  isa_ok($head, 'Email::Simple::Header');

  for my $method (qw(header header_raw)) {
    subtest "checks via $method" => sub {
      is_deeply(
        [ $head->$method('foo') ],
        [ 1, 2, 3 ],
        "multi-value header",
      );

      is_deeply(
        scalar $head->$method('foo'),
        1,
        "single-value header",
      );

      is_deeply(
        scalar $head->$method('foo', 0),
        1,
        "first value",
      );

      is_deeply(
        scalar $head->$method('foo', 1),
        2,
        "second value",
      );

      is_deeply(
        scalar $head->$method('foo', 2),
        3,
        "third value",
      );

      is_deeply(
        scalar $head->$method('foo', 3),
        undef,
        "non existent fourth value",
      );

      is_deeply(
        scalar $head->$method('foo', -1),
        3,
        "last value",
      );

      is_deeply(
        scalar $head->$method('foo', -3),
        1,
        "third value from end",
      );

      is_deeply(
        scalar $head->$method('foo', -4),
        undef,
        "non existent fourth value from end",
      );
    }
  }
}
