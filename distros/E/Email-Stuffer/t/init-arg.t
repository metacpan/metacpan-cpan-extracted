#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Email::Stuffer;

my $from = 'me@email.com';
my $to   = [ 'you@example.com', 'them@example.mil' ];
my $stuffer = Email::Stuffer->new({
  to    => $to,
  from  => $from,
});

my $email = $stuffer->email;

is_deeply(
  [ split /\s*,\s*/, $stuffer->email->header('To') ],
  [ @$to ],
  'init-arg "to" sets To header',
);

is(
  $stuffer->email->header('From'),
  $from,
  'init-arg "from" sets From header',
);

done_testing;
