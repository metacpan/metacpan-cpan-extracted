#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use lib 't/lib';
use Test::HT;

ht_test(
    { status_code => 500, reason => 'Internal Server Error' },
    {
        code   => 500,
        reason => 'Internal Server Error',
        assert => sub {
          my $e = shift;

          is(
              "$e",
              '500 Internal Server Error',
              '... got the right string overload',
          );

          if ($e->does('HTTP::Throwable::Role::TextBody')) {
              is_deeply(
                  $e->(),
                  [
                      500,
                      [
                          'Content-Type'   => 'text/plain',
                          'Content-Length' => 25,
                      ],
                      [ '500 Internal Server Error' ]
                  ],
                  '... got the right &{} overload transformation'
              );
          }
        },
    },
);

subtest "strict constructors all around" => sub {
  my $error = exception {
    HTTP::Throwable::Factory->throw(MovedPermanently => {
      location => '/foo',
      bogus    => 123,
    });
  };

  like(
    $error,
    qr{Found unknown attribute\(s\) passed to the constructor},
    "http throwables have strict constructors",
  );
};

done_testing;
