use Test::More;
use strict;
$^W = 1;

use Email::Send::Test;
use Email::Send 'Test';

plan skip_all => "Email::Abstract required for these tests"
  unless eval "use Email::Abstract; 1";

my $tests = 3;

my $message;

if (eval { require Mail::Internet; }) {
  plan tests => $tests;
  
  $message = Mail::Internet->new(
    Header => Mail::Header->new([
      "From: your mom\n",
      "To:  your dad\n",
    ]),
    Body   => [ "This is a message\n" ],
  );

  isa_ok($message, 'Mail::Internet');
} elsif (eval { require MIME::Entity }) {
  plan tests => $tests;

  $message = MIME::Entity->build(
    From    => 'me@myhost.com',
    To      => 'you@yourhost.com',
    Subject => "Hello, nurse!",
    Data    => "This is a message\n",
  );

  isa_ok($message, 'MIME::Entity');
} else {
  plan skip_all => "these tests require Mail::Internet or MIME::Entity";
}

send Test => $message;

my @emails = Email::Send::Test->emails;

is(@emails, 1, "we delivered the non-Simple message");

like(
  $emails[0]->body,
  qr/This is a message/,
  "the delivered message looks like what we send",
);

