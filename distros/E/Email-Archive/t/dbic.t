#!/usr/bin/perl
use strict;
use warnings;
use Email::MIME;

use Test::More;

use Email::Archive;
use Email::Archive::Storage::DBIC;

my $email = Email::MIME->create(
    header => [
      From    => 'foo@example.com',
      To      => 'drain@example.com',
      Subject => 'Message in a bottle',
      'Message-ID' => 'helloworld',
    ],
    body => 'hello there!'
);

my $e = Email::Archive->new(
    storage => Email::Archive::Storage::DBIC->new,
);
$e->connect('dbi:SQLite:dbname=t/test_dbic.db');
$e->store($email);

my $found = $e->retrieve('helloworld');
cmp_ok($found->header('subject'), 'eq', "Message in a bottle",
  "can find stored message by ID");


done_testing;

unlink 't/test_dbic.db';

