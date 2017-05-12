use strict;
use warnings;

use Test::More;

use JSON;
use Try::Tiny;

use HTTP::Throwable::JSONFactory qw(http_throw);

{
  my $exception;

  try {
    http_throw(Gone => {
      payload => {
        what => 'for',
      },
    });
  }  catch {
    $exception = $_;
  };

  is_deeply(
    $exception->as_psgi,
    [
      410,
      [
        'Content-Type'   => 'application/json',
        'Content-Length' => '14',
      ],
      [ '{"what":"for"}' ],
    ],
    "Excpetion looks right"
  ) or diag explain $exception->as_psgi;
}

{
  my $exception;

  try {
    http_throw('Gone');
  }  catch {
    $exception = $_;
  };

  is_deeply(
    $exception->as_psgi,
    [
      410,
      [
        'Content-Type'   => 'application/json',
        'Content-Length' => '2',
      ],
      [ '{}' ],
    ],
    "Excpetion looks right when no payload is specified"
  ) or diag explain $exception->as_psgi;
}

done_testing;
