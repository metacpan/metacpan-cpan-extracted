use Test::More tests => 2;
use strict;
$^W = 1;

use Email::Send;
use Email::Simple;

{
  my $message = Email::Simple->new(<<'__MESSAGE__');
To: me@myhost.com
From: you@yourhost.com
Subject: Test
  
Testing this thing out.
__MESSAGE__

  Email::Send->new({mailer => 'Test', mailer_args => [ 1, 2, 3 ]})
             ->send($message);

  my ($deliveries) = Email::Send::Test->deliveries;
  my $test_message = $deliveries->[1];
  is_deeply(
    $deliveries->[2],
    [ 1, 2, 3 ],
    "args passed in properly",
  );

  is $test_message->as_string, $message->as_string, 'sent properly';

}
